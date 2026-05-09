from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from typing import List
from firebase_admin import auth

from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from shared.db import get_db
from .models import Invitation, StaffRoleAssignment, B2BInvitation, BuyerUser, ConsumerUser
from .schemas import (
    InvitationCreate, InvitationResponse, RoleUpdate, 
    OwnershipTransferRequest, B2BBuyerRegistration, ConsumerRegistration
)

router = APIRouter()

@router.get("/me", response_model=UserClaims)
async def get_me(
    user: UserClaims = Depends(validate_token),
    db: AsyncSession = Depends(get_db)
):
    """Returns current user claims, resolving from DB if token is stale."""
    if not user.tenant_id:
        result = await db.execute(
            select(StaffRoleAssignment).where(StaffRoleAssignment.staff_user_id == user.uid)
        )
        assignment = result.scalar_one_or_none()
        if assignment:
            user.tenant_id = assignment.tenant_id
            user.roles = assignment.roles
            user.is_owner = assignment.is_owner
            # Note: The client should ideally refresh its token after this 
            # to ensure subsequent requests have the claim in the JWT.
    return user

@router.post("/invitations", response_model=InvitationResponse, status_code=status.HTTP_201_CREATED)
async def create_invitation(
    invite: InvitationCreate,
    user: UserClaims = has_permissions(["auth:invite"]),
    db: AsyncSession = Depends(get_db)
):
    """Invite a new staff member."""
    new_invite = Invitation(
        email=invite.email,
        tenant_id=user.tenant_id,
        roles=invite.roles,
        invited_by=user.email
    )
    db.add(new_invite)
    await db.commit()
    await db.refresh(new_invite)
    return new_invite

@router.get("/invitations", response_model=List[InvitationResponse])
async def list_invitations(
    user: UserClaims = has_permissions(["auth:invite"]),
    db: AsyncSession = Depends(get_db)
):
    """List pending invitations for the current tenant."""
    result = await db.execute(
        select(Invitation).where(
            Invitation.tenant_id == user.tenant_id,
            Invitation.is_cancelled == False,
            Invitation.accepted_at == None
        )
    )
    return result.scalars().all()

@router.delete("/invitations/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_invitation(
    id: str,
    user: UserClaims = has_permissions(["auth:invite"]),
    db: AsyncSession = Depends(get_db)
):
    """Cancel a pending invitation."""
    result = await db.execute(
        select(Invitation).where(
            Invitation.id == id,
            Invitation.tenant_id == user.tenant_id
        )
    )
    invite = result.scalar_one_or_none()
    if not invite:
        raise HTTPException(status_code=404, detail="Invitation not found")
    
    invite.is_cancelled = True
    await db.commit()
    return None

@router.patch("/staff/{uid}/roles", status_code=status.HTTP_200_OK)
async def update_staff_roles(
    uid: str,
    payload: RoleUpdate,
    user: UserClaims = has_permissions(["auth:invite"]),
    db: AsyncSession = Depends(get_db)
):
    """Update a staff member's roles and sync with Firebase claims."""
    # 1. Update DB
    result = await db.execute(
        select(StaffRoleAssignment).where(
            StaffRoleAssignment.staff_user_id == uid,
            StaffRoleAssignment.tenant_id == user.tenant_id
        )
    )
    assignment = result.scalar_one_or_none()
    
    if not assignment:
        # Create new assignment if it doesn't exist (e.g. for manually added users)
        assignment = StaffRoleAssignment(
            staff_user_id=uid,
            tenant_id=user.tenant_id,
            roles=payload.roles
        )
        db.add(assignment)
    else:
        assignment.roles = payload.roles
    
    await db.commit()

    # 2. Sync with Firebase
    try:
        firebase_user = auth.get_user(uid)
        claims = firebase_user.custom_claims or {}
        claims.update({
            "roles": payload.roles,
            "tenant_id": user.tenant_id # Ensure tenant_id is preserved/set
        })
        auth.set_custom_user_claims(uid, claims)
    except Exception as e:
        # In a real app, we might want to rollback DB or log this failure
        raise HTTPException(status_code=500, detail=f"Firebase sync failed: {str(e)}")

    return {"status": "success", "uid": uid, "roles": payload.roles}

@router.delete("/staff/{uid}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_staff_access(
    uid: str,
    user: UserClaims = has_permissions(["auth:revoke"]),
    db: AsyncSession = Depends(get_db)
):
    """Revoke a staff member's access to the current tenant."""
    # 1. Remove from DB
    await db.execute(
        delete(StaffRoleAssignment).where(
            StaffRoleAssignment.staff_user_id == uid,
            StaffRoleAssignment.tenant_id == user.tenant_id
        )
    )
    await db.commit()

    # 2. Sync with Firebase (strip tenant-specific claims)
    try:
        firebase_user = auth.get_user(uid)
        claims = firebase_user.custom_claims or {}
        # If user only has this tenant, we could strip everything.
        # For multi-tenant users, we'd need more complex logic.
        # For MVP, we assume single tenant per staff member for now.
        auth.set_custom_user_claims(uid, None)
    except Exception:
        pass # User might already be deleted in Firebase

    return None

@router.post("/ownership/transfer", status_code=status.HTTP_200_OK)
async def transfer_ownership(
    payload: OwnershipTransferRequest,
    user: UserClaims = Depends(validate_token),
    db: AsyncSession = Depends(get_db)
):
    """Transfer store ownership to another staff member."""
    if not user.is_owner:
        raise HTTPException(status_code=403, detail="Only the owner can transfer ownership")

    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant context required for ownership transfer")

    # 1. Verify target exists and belongs to same tenant
    result = await db.execute(
        select(StaffRoleAssignment).where(
            StaffRoleAssignment.staff_user_id == payload.new_owner_uid,
            StaffRoleAssignment.tenant_id == user.tenant_id
        )
    )
    new_owner_assignment = result.scalar_one_or_none()
    if not new_owner_assignment:
        raise HTTPException(status_code=404, detail="Target staff member not found in this tenant")

    # 2. Update current owner's assignment
    result = await db.execute(
        select(StaffRoleAssignment).where(
            StaffRoleAssignment.staff_user_id == user.uid,
            StaffRoleAssignment.tenant_id == user.tenant_id
        )
    )
    current_owner_assignment = result.scalar_one_or_none()
    if current_owner_assignment:
        current_owner_assignment.is_owner = False
        # Give them 'admin' role as fallback
        if "admin" not in current_owner_assignment.roles:
            current_owner_assignment.roles = list(set(current_owner_assignment.roles + ["admin"]))

    # 3. Update new owner's assignment
    new_owner_assignment.is_owner = True

    await db.commit()

    # 4. Sync Firebase Claims
    try:
        # Update New Owner
        new_claims = auth.get_user(payload.new_owner_uid).custom_claims or {}
        new_claims.update({"is_owner": True})
        auth.set_custom_user_claims(payload.new_owner_uid, new_claims)

        # Update Previous Owner
        prev_claims = auth.get_user(user.uid).custom_claims or {}
        prev_claims.update({"is_owner": False, "roles": current_owner_assignment.roles})
        auth.set_custom_user_claims(user.uid, prev_claims)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Firebase sync failed: {str(e)}")

    return {"status": "success", "message": f"Ownership transferred to {payload.new_owner_uid}"}

@router.post("/b2b-buyers/register", status_code=status.HTTP_201_CREATED)
async def register_b2b_buyer(
    payload: B2BBuyerRegistration,
    db: AsyncSession = Depends(get_db)
):
    """Register a B2B buyer using an invitation token."""
    from datetime import datetime

    # 1. Validate token
    result = await db.execute(
        select(B2BInvitation).where(
            B2BInvitation.token == payload.invite_token,
            B2BInvitation.accepted_at == None
        )
    )
    invitation = result.scalar_one_or_none()
    if not invitation or invitation.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Invalid or expired invitation token")

    # 2. Create Firebase User
    try:
        # Check if user already exists
        try:
            fb_user = auth.get_user_by_email(invitation.email)
        except auth.UserNotFoundError:
            fb_user = auth.create_user(
                email=invitation.email,
                password=payload.password,
                display_name=payload.display_name
            )

        # 3. Set Custom Claims
        claims = {
            "tenant_id": invitation.tenant_id,
            "account_type": "buyer",
            "buyer_account_id": invitation.buyer_account_id,
            "roles": ["buyer"]
        }
        auth.set_custom_user_claims(fb_user.uid, claims)

        # 4. Update DB
        invitation.accepted_at = datetime.utcnow()
        new_buyer = BuyerUser(
            uid=fb_user.uid,
            email=invitation.email,
            tenant_id=invitation.tenant_id,
            buyer_account_id=invitation.buyer_account_id
        )
        db.add(new_buyer)
        await db.commit()

        return {"uid": fb_user.uid, "email": fb_user.email, "status": "registered"}

    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")

@router.post("/consumers/register", status_code=status.HTTP_201_CREATED)
async def register_consumer(
    payload: ConsumerRegistration,
    db: AsyncSession = Depends(get_db)
):
    """Register a DTC consumer (post-checkout)."""
    try:
        # 1. Create Firebase User
        try:
            fb_user = auth.get_user_by_email(payload.email)
        except auth.UserNotFoundError:
            fb_user = auth.create_user(
                email=payload.email,
                password=payload.password,
                display_name=payload.display_name or payload.full_name
            )

        # 2. Set Custom Claims
        claims = {
            "tenant_id": payload.tenant_id,
            "account_type": "consumer",
            "roles": ["consumer"]
        }
        auth.set_custom_user_claims(fb_user.uid, claims)

        # 3. Create/Update Consumer In DB
        result = await db.execute(select(ConsumerUser).where(ConsumerUser.uid == fb_user.uid))
        consumer = result.scalar_one_or_none()
        
        if not consumer:
            consumer = ConsumerUser(
                uid=fb_user.uid,
                email=payload.email,
                tenant_id=payload.tenant_id,
                full_name=payload.full_name,
                default_shipping_address=payload.shipping_address
            )
            db.add(consumer)
        else:
            # Update existing if needed
            if payload.full_name:
                consumer.full_name = payload.full_name
            if payload.shipping_address:
                consumer.default_shipping_address = payload.shipping_address
        
        await db.flush()

        # 4. Link Order if provided
        if payload.order_id:
            from ..orders.models import Order
            order_result = await db.execute(
                select(Order).where(Order.order_id == payload.order_id, Order.tenant_id == payload.tenant_id)
            )
            order = order_result.scalar_one_or_none()
            if order:
                order.consumer_id = fb_user.uid
        
        await db.commit()

        return {"uid": fb_user.uid, "email": fb_user.email, "status": "registered"}

    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")
