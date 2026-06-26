from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from datetime import datetime, timezone
from typing import List, Optional

from shared.db import get_db
from shared.auth import UserClaims, validate_token
from modules.storefront.models import BrandProfile
from modules.navigation.models import StoreNavigationItem
from .models import StorePolicy
from .schemas import (
    PolicyCreate, PolicyResponse, PolicyUpdate,
    PolicyTemplateSeedRequest, PolicyTemplateSeedResponse
)

router = APIRouter(tags=["Policies"])

# --- Policies CRUD ---

@router.post("", response_model=PolicyResponse, status_code=status.HTTP_201_CREATED)
async def create_policy(
    req: PolicyCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    # Only allow one active draft/policy type initially, or let them create multiple versions
    # For simplicity, we just create a new policy version
    policy = StorePolicy(
        tenant_id=user.tenant_id,
        policy_type=req.policy_type.lower(),
        draft_content=req.draft_content,
        published_content=req.published_content,
        version=1,
        is_active=False
    )
    db.add(policy)
    await db.commit()
    await db.refresh(policy)
    return policy

@router.get("", response_model=List[PolicyResponse])
async def list_policies(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    # Returns all policies (active or draft versions)
    result = await db.execute(
        select(StorePolicy)
        .where(StorePolicy.tenant_id == user.tenant_id)
        .order_by(StorePolicy.policy_type, StorePolicy.version.desc())
    )
    return result.scalars().all()

@router.get("/{policy_id}", response_model=PolicyResponse)
async def get_policy(
    policy_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(StorePolicy).where(StorePolicy.policy_id == policy_id, StorePolicy.tenant_id == user.tenant_id)
    )
    policy = result.scalar_one_or_none()
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")
    return policy

@router.patch("/{policy_id}", response_model=PolicyResponse)
async def update_policy_draft(
    policy_id: str,
    req: PolicyUpdate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(StorePolicy).where(StorePolicy.policy_id == policy_id, StorePolicy.tenant_id == user.tenant_id)
    )
    policy = result.scalar_one_or_none()
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")

    policy.draft_content = req.draft_content
    policy.updated_at = datetime.now(timezone.utc)
    
    await db.commit()
    await db.refresh(policy)
    return policy

# --- Publish Transaction with Validation ---

@router.post("/{policy_id}/publish", response_model=PolicyResponse)
async def publish_policy(
    policy_id: str,
    force: bool = Query(False, description="Bypass storefront link check validation"),
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    # 1. Fetch target policy
    result = await db.execute(
        select(StorePolicy).where(StorePolicy.policy_id == policy_id, StorePolicy.tenant_id == user.tenant_id)
    )
    policy = result.scalar_one_or_none()
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")

    if not policy.draft_content:
        raise HTTPException(status_code=400, detail="Cannot publish a policy with empty draft content")

    # 2. Validation Check: Check if there are navigation items referencing this policy
    if not force:
        nav_res = await db.execute(
            select(StoreNavigationItem)
            .where(
                StoreNavigationItem.tenant_id == user.tenant_id,
                StoreNavigationItem.link_type == "policy",
                StoreNavigationItem.resource_id == policy_id
            )
        )
        has_links = nav_res.first() is not None
        if not has_links:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="No active storefront links (navigation menus) reference this policy. To publish anyway, set force=True."
            )

    # 3. Publish transaction:
    # Deactivate previously active policy of the same type
    now_time = datetime.now(timezone.utc)
    await db.execute(
        update(StorePolicy)
        .where(
            StorePolicy.tenant_id == user.tenant_id,
            StorePolicy.policy_type == policy.policy_type,
            StorePolicy.is_active == True
        )
        .values(is_active=False, deactivated_at=now_time)
    )

    # Make this version active
    policy.published_content = policy.draft_content
    policy.is_active = True
    policy.version += 1
    policy.updated_at = now_time
    policy.deactivated_at = None

    await db.commit()
    await db.refresh(policy)
    return policy

# --- Template Seeder ---

@router.post("/seed-template", response_model=PolicyTemplateSeedResponse)
async def seed_policy_template(
    req: PolicyTemplateSeedRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="Tenant ID missing")

    # Fetch BrandProfile for metadata
    brand_res = await db.execute(select(BrandProfile).where(BrandProfile.tenant_id == user.tenant_id))
    brand = brand_res.scalar_one_or_none()

    company_name = brand.brand_name if brand else "KloudShop Merchant"
    contact_email = brand.contact_email if brand and brand.contact_email else "support@kloudshop.com"

    ptype = req.policy_type.lower()
    
    if ptype == "refund":
        content = (
            f"<h1>Refund Policy</h1>\n"
            f"<p>Thank you for shopping at <strong>{company_name}</strong>.</p>\n"
            f"<p>We offer a full refund and/or exchange within 30 days of your purchase. If 30 days have passed since your purchase, you will not be offered a refund and/or exchange of any kind.</p>\n"
            f"<p><strong>Eligibility for Refunds and Exchanges:</strong></p>\n"
            f"<ul>\n"
            f"  <li>Your item must be unused and in the same condition that you received it.</li>\n"
            f"  <li>The item must be in the original packaging.</li>\n"
            f"</ul>\n"
            f"<p>Please contact us at <strong>{contact_email}</strong> to initiate a return.</p>"
        )
    elif ptype == "privacy":
        content = (
            f"<h1>Privacy Policy</h1>\n"
            f"<p>This Privacy Policy describes how <strong>{company_name}</strong> collects, uses, and discloses your personal information when you visit or make a purchase from the storefront.</p>\n"
            f"<h3>Personal Information We Collect</h3>\n"
            f"<p>When you visit the site, we collect certain information about your device, your interaction with the site, and information necessary to process your purchases.</p>\n"
            f"<p>If you have questions, please contact us via email at <strong>{contact_email}</strong>.</p>"
        )
    elif ptype == "terms":
        content = (
            f"<h1>Terms of Service</h1>\n"
            f"<p>These Terms of Service govern your use of the website and storefront operated by <strong>{company_name}</strong>.</p>\n"
            f"<p>By accessing or using any part of the site, you agree to be bound by these Terms of Service. If you do not agree to all the terms and conditions of this agreement, then you may not access the website or use any services.</p>\n"
            f"<p>For support, please contact us at <strong>{contact_email}</strong>.</p>"
        )
    elif ptype == "shipping":
        content = (
            f"<h1>Shipping Policy</h1>\n"
            f"<p>All orders at <strong>{company_name}</strong> are processed within 2-3 business days.</p>\n"
            f"<p>Orders are not shipped or delivered on weekends or holidays. If we are experiencing a high volume of orders, shipments may be delayed by a few days.</p>\n"
            f"<p>Shipping charges for your order will be calculated and displayed at checkout.</p>"
        )
    else:
        raise HTTPException(status_code=400, detail="Invalid policy type for seeding")

    return PolicyTemplateSeedResponse(
        policy_type=ptype,
        seeded_content=content
    )
