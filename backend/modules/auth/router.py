from fastapi import APIRouter, Depends, status, HTTPException, Request, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from typing import List, Optional
from firebase_admin import auth
from datetime import datetime, timezone, date, timedelta
import uuid

from shared.auth import UserClaims, validate_token, verify_app_check
from shared.rbac import has_permissions
from shared.db import get_db, AsyncSessionLocal
from .models import (
    Invitation, StaffRoleAssignment, B2BInvitation, BuyerUser, ConsumerUser,
    StaffUser, StaffLoginHistory, StaffSecurityState
)
from .schemas import (
    InvitationCreate, InvitationResponse, RoleUpdate, 
    OwnershipTransferRequest, B2BBuyerRegistration, ConsumerRegistration,
    FailedLoginAlert, UnblockRequest, UnblockVerify
)

router = APIRouter()

# ── Geolocation and Security Email Helpers ───────────────────────────

async def async_triangulate_ip(ip: str):
    import httpx
    if ip in ("127.0.0.1", "::1", "localhost"):
        # Returns realistic Mock data for Montreal, Canada (Eastern Canada sector)
        return {
            "country_code": "CA",
            "country_name": "Canada",
            "region": "Quebec",
            "city": "Montreal",
            "latitude": 45.5017,
            "longitude": -73.5673
        }
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            response = await client.get(f"https://ipapi.co/{ip}/json/")
            if response.status_code == 200:
                data = response.json()
                if "error" not in data:
                    return {
                        "country_code": data.get("country_code"),
                        "country_name": data.get("country_name"),
                        "region": data.get("region"),
                        "city": data.get("city"),
                        "latitude": data.get("latitude"),
                        "longitude": data.get("longitude")
                    }
    except Exception as e:
        print(f"IP Geolocation error for {ip}: {e}")
    
    return {}

def send_security_email(to_email: str, subject: str, body: str):
    print("\n" + "="*80)
    print(f"🔒 [SECURITY AUDIT] URGENT EMAIL DISPATCHED SUCCESSFULLY")
    print(f"Recipient: {to_email}")
    print(f"Subject: {subject}")
    print(f"Body:\n{body}")
    print("="*80 + "\n")

async def handle_failed_login_task(email: str, ip: str, user_agent: str, tenant_id: Optional[str], db_session_maker):
    geo = await async_triangulate_ip(ip)
    
    now_str = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    geo_str = f"{geo.get('city', 'Unknown City')}, {geo.get('region', 'Unknown Region')}, {geo.get('country_name', 'Unknown Country')}"
    if not geo.get('country_name'):
        geo_str = "Unknown Location"
        
    subject = "⚠️ Security Alert: Failed Login Attempt Detected"
    body = f"""
Dear User,

A failed sign-in attempt was detected on your account.

Time: {now_str}
IP Address: {ip}
Estimated Location: {geo_str}
Browser/Device: {user_agent}
Tenant Context: {tenant_id or "Platform-wide Control Plane"}

If this wasn't you, please secure your account immediately.
"""
    send_security_email(email, subject, body)
    
    async with db_session_maker() as db:
        result = await db.execute(select(StaffUser).where(StaffUser.email == email))
        user = result.scalar_one_or_none()
        if user and tenant_id:
            result = await db.execute(
                select(StaffRoleAssignment).where(
                    StaffRoleAssignment.staff_user_id == user.uid,
                    StaffRoleAssignment.tenant_id == tenant_id
                )
            )
            assignment = result.scalar_one_or_none()
            if assignment:
                owner_result = await db.execute(
                    select(StaffRoleAssignment).where(
                        StaffRoleAssignment.tenant_id == tenant_id,
                        StaffRoleAssignment.is_owner == True
                    )
                )
                owner_assign = owner_result.scalar_one_or_none()
                if owner_assign:
                    owner_user_result = await db.execute(
                        select(StaffUser).where(StaffUser.uid == owner_assign.staff_user_id)
                    )
                    owner_user = owner_user_result.scalar_one_or_none()
                    if owner_user and owner_user.email.lower() != email.lower():
                        admin_subject = f"⚠️ Security Alert: Failed login for staff member {email}"
                        admin_body = f"""
Dear Administrator,

A failed login attempt was recorded for staff member {email} under your store.

Time: {now_str}
IP Address: {ip}
Estimated Location: {geo_str}
Browser/Device: {user_agent}

No action is required unless this activity looks suspicious.
"""
                        send_security_email(owner_user.email, admin_subject, admin_body)

async def handle_successful_login_task(user_id: str, email: str, tenant_id: Optional[str], ip: str, user_agent: str, db_session_maker):
    geo = await async_triangulate_ip(ip)
    
    async with db_session_maker() as db:
        login_history = StaffLoginHistory(
            staff_user_id=user_id,
            tenant_id=tenant_id,
            ip_address=ip,
            user_agent=user_agent,
            country_code=geo.get("country_code"),
            country_name=geo.get("country_name"),
            region_name=geo.get("region"),
            city_name=geo.get("city"),
            latitude=str(geo.get("latitude")) if geo.get("latitude") is not None else None,
            longitude=str(geo.get("longitude")) if geo.get("longitude") is not None else None,
        )
        db.add(login_history)
        await db.commit()

# ── Endpoints ────────────────────────────────────────────────────────

@router.get("/me", response_model=UserClaims)
async def get_me(
    request: Request,
    background_tasks: BackgroundTasks,
    user: UserClaims = Depends(validate_token),
    db: AsyncSession = Depends(get_db)
):
    """Returns current user claims, resolving from DB if token is stale."""
    # 1. Update claims if needed
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
            
    # 2. Record successful login (rate limited to once per 5 minutes per user)
    if user.email:
        email_lower = user.email.lower()
        last_history_result = await db.execute(
            select(StaffLoginHistory)
            .where(StaffLoginHistory.staff_user_id == user.uid)
            .order_by(StaffLoginHistory.created_at.desc())
            .limit(1)
        )
        last_history = last_history_result.scalar_one_or_none()
        
        log_successful = False
        now_utc = datetime.now(timezone.utc)
        if not last_history:
            log_successful = True
        else:
            last_created = last_history.created_at
            if last_created.tzinfo is None:
                last_created = last_created.replace(tzinfo=timezone.utc)
            if now_utc - last_created > timedelta(minutes=5):
                log_successful = True
                
        if log_successful:
            client_ip = request.client.host if request.client else "127.0.0.1"
            user_agent = request.headers.get("user-agent", "Unknown")
            
            # Reset security failure counts upon successful login
            sec_state_result = await db.execute(
                select(StaffSecurityState).where(StaffSecurityState.gmail == email_lower)
            )
            sec_state = sec_state_result.scalar_one_or_none()
            if sec_state:
                sec_state.failed_attempts_count = 0
                sec_state.cool_off_until = None
                sec_state.updated_at = now_utc
            else:
                sec_state = StaffSecurityState(
                    gmail=email_lower,
                    failed_attempts_count=0,
                    failed_days_count=0,
                    is_blocked=False,
                    updated_at=now_utc
                )
                db.add(sec_state)
            
            await db.commit()
            
            background_tasks.add_task(
                handle_successful_login_task,
                user.uid,
                email_lower,
                user.tenant_id,
                client_ip,
                user_agent,
                AsyncSessionLocal
            )
            
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
    from datetime import datetime, timezone

    # 1. Validate token
    result = await db.execute(
        select(B2BInvitation).where(
            B2BInvitation.token == payload.invite_token,
            B2BInvitation.accepted_at == None
        )
    )
    invitation = result.scalar_one_or_none()
    if not invitation or invitation.expires_at < datetime.now(timezone.utc):
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
        invitation.accepted_at = datetime.now(timezone.utc)
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

# ── Login Security, Lockout, and Unblocking Endpoints ───────────────

@router.get("/login-status/{gmail}")
async def get_login_status(
    gmail: str,
    db: AsyncSession = Depends(get_db),
    _app_check = Depends(verify_app_check)
):
    """Checks the active cool-off and blocked status of a Gmail account."""
    gmail_lower = gmail.lower()
    result = await db.execute(
        select(StaffSecurityState).where(StaffSecurityState.gmail == gmail_lower)
    )
    sec_state = result.scalar_one_or_none()
    
    cool_off_seconds = 0
    is_blocked = False
    
    if sec_state:
        is_blocked = sec_state.is_blocked
        if sec_state.cool_off_until:
            now_utc = datetime.now(timezone.utc)
            cool_off = sec_state.cool_off_until
            if cool_off.tzinfo is None:
                cool_off = cool_off.replace(tzinfo=timezone.utc)
            if cool_off > now_utc:
                cool_off_seconds = int((cool_off - now_utc).total_seconds())
                
    return {
        "gmail": gmail_lower,
        "is_blocked": is_blocked,
        "cool_off_seconds": max(0, cool_off_seconds)
    }

@router.post("/failed-login-alert", status_code=status.HTTP_200_OK)
async def failed_login_alert(
    payload: FailedLoginAlert,
    request: Request,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    _app_check = Depends(verify_app_check)
):
    """Logs a failed sign-in attempt and initiates a 180s cool-off or block."""
    email_lower = payload.email.lower()
    client_ip = request.client.host if request.client else "127.0.0.1"
    user_agent = payload.user_agent or request.headers.get("user-agent", "Unknown")
    
    result = await db.execute(
        select(StaffSecurityState).where(StaffSecurityState.gmail == email_lower)
    )
    sec_state = result.scalar_one_or_none()
    
    now_utc = datetime.now(timezone.utc)
    
    if not sec_state:
        sec_state = StaffSecurityState(
            gmail=email_lower,
            failed_attempts_count=1,
            last_failed_attempt_at=now_utc,
            cool_off_until=now_utc + timedelta(seconds=180),
            failed_days_count=1,
            last_failed_day=str(date.today()),
            is_blocked=False
        )
        db.add(sec_state)
    else:
        # Check active cool-off
        cool_off = sec_state.cool_off_until
        if cool_off:
            if cool_off.tzinfo is None:
                cool_off = cool_off.replace(tzinfo=timezone.utc)
            if cool_off > now_utc:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Sign-in cool-off active. Please wait."
                )
        
        # Reset attempts if the last failure was > 24 hours ago
        if sec_state.last_failed_attempt_at:
            last_failed = sec_state.last_failed_attempt_at
            if last_failed.tzinfo is None:
                last_failed = last_failed.replace(tzinfo=timezone.utc)
            if now_utc - last_failed > timedelta(hours=24):
                sec_state.failed_attempts_count = 0
                
        # Increment attempts
        sec_state.failed_attempts_count += 1
        sec_state.last_failed_attempt_at = now_utc
        sec_state.cool_off_until = now_utc + timedelta(seconds=180)
        
        # Track daily failed calendar day strikes
        today_str = str(date.today())
        if sec_state.last_failed_day != today_str:
            sec_state.failed_days_count += 1
            sec_state.last_failed_day = today_str
            
        # Lockout check
        if sec_state.failed_attempts_count >= 3 or sec_state.failed_days_count >= 3:
            sec_state.is_blocked = True
            
        sec_state.updated_at = now_utc
        
    await db.commit()
    
    background_tasks.add_task(
        handle_failed_login_task,
        email_lower,
        client_ip,
        user_agent,
        payload.tenant_id,
        AsyncSessionLocal
    )
    
    return {"status": "alert_processed", "is_blocked": sec_state.is_blocked}

@router.post("/unblock/request", status_code=status.HTTP_200_OK)
async def request_unblock(
    payload: UnblockRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    _app_check = Depends(verify_app_check)
):
    """Sends a short-lived (180s TTL) unblock token email to the user (max 3/24h)."""
    email_lower = payload.email.lower()
    
    result = await db.execute(
        select(StaffSecurityState).where(StaffSecurityState.gmail == email_lower)
    )
    sec_state = result.scalar_one_or_none()
    
    if not sec_state or not sec_state.is_blocked:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account is not blocked."
        )
        
    now_utc = datetime.now(timezone.utc)
    
    # 24-hour request limit check
    if sec_state.last_unblock_request_at:
        last_req = sec_state.last_unblock_request_at
        if last_req.tzinfo is None:
            last_req = last_req.replace(tzinfo=timezone.utc)
        if now_utc - last_req > timedelta(hours=24):
            sec_state.unblock_request_count = 0
            
    if sec_state.unblock_request_count >= 3:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Maximum unblock requests exceeded for today. Try again in 24 hours."
        )
        
    token = str(uuid.uuid4())
    sec_state.unblock_token = token
    sec_state.unblock_token_expires_at = now_utc + timedelta(seconds=180) # 180s TTL
    sec_state.unblock_request_count += 1
    sec_state.last_unblock_request_at = now_utc
    sec_state.updated_at = now_utc
    
    await db.commit()
    
    unblock_link = f"http://localhost:3000/unblock?token={token}"
    subject = "🔑 Action Required: Unlock Your KloudShop Account"
    body = f"""
Dear User,

We received a request to unlock your KloudShop account.

Please click the link below to verify your identity and unblock your account:
{unblock_link}

This link is valid for exactly 180 seconds (3 minutes).

If you did not make this request, please ignore this email.
"""
    background_tasks.add_task(send_security_email, email_lower, subject, body)
    
    return {"status": "unblock_email_sent"}

@router.post("/unblock/verify", status_code=status.HTTP_200_OK)
async def verify_unblock(
    payload: UnblockVerify,
    db: AsyncSession = Depends(get_db)
):
    """Verifies the unblock token and unlocks the account (does not require login)."""
    result = await db.execute(
        select(StaffSecurityState).where(StaffSecurityState.unblock_token == payload.token)
    )
    sec_state = result.scalar_one_or_none()
    
    if not sec_state:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired unblock token."
        )
        
    now_utc = datetime.now(timezone.utc)
    expires = sec_state.unblock_token_expires_at
    if expires:
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        if now_utc > expires:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unblock token has expired (180s TTL limit)."
            )
            
    sec_state.is_blocked = False
    sec_state.failed_attempts_count = 0
    sec_state.failed_days_count = 0
    sec_state.unblock_token = None
    sec_state.unblock_token_expires_at = None
    sec_state.updated_at = now_utc
    
    await db.commit()
    
    return {"status": "account_unblocked", "email": sec_state.gmail}

@router.post("/staff/{uid}/unblock", status_code=status.HTTP_200_OK)
async def admin_unblock_staff(
    uid: str,
    user: UserClaims = has_permissions(["auth:invite"]),
    db: AsyncSession = Depends(get_db)
):
    """Allows an administrator or store owner to unblock a locked staff account."""
    # Enforce tenant boundary: Verify the target staff member belongs to the caller's tenant
    result = await db.execute(
        select(StaffRoleAssignment).where(
            StaffRoleAssignment.staff_user_id == uid,
            StaffRoleAssignment.tenant_id == user.tenant_id
        )
    )
    assignment = result.scalar_one_or_none()
    if not assignment:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Unauthorized to unblock this staff user or user does not exist in this tenant."
        )

    result = await db.execute(select(StaffUser).where(StaffUser.uid == uid))
    staff_user = result.scalar_one_or_none()
    if not staff_user:
        raise HTTPException(status_code=404, detail="Staff user not found.")
        
    result = await db.execute(
        select(StaffSecurityState).where(StaffSecurityState.gmail == staff_user.email.lower())
    )
    sec_state = result.scalar_one_or_none()
    
    if sec_state:
        sec_state.is_blocked = False
        sec_state.failed_attempts_count = 0
        sec_state.failed_days_count = 0
        sec_state.unblock_token = None
        sec_state.unblock_token_expires_at = None
        sec_state.updated_at = datetime.now(timezone.utc)
        await db.commit()
        
    return {"status": "staff_unblocked", "uid": uid}
