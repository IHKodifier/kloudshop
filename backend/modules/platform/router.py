from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List

from shared.auth import UserClaims
from shared.rbac import has_permissions
from shared.db import get_db
from .models import Tenant
from modules.billing.models import Subscription, SubscriptionStatus

router = APIRouter()

@router.get("/dashboard")
async def get_platform_dashboard(
    user: UserClaims = has_permissions(["admin:platform"]),
    db: AsyncSession = Depends(get_db)
):
    """Aggregated metrics for platform administrators."""
    # 1. Total Tenants
    result = await db.execute(select(func.count(Tenant.id)))
    total_tenants = result.scalar()

    # 2. Active Subscriptions
    result = await db.execute(
        select(func.count(Subscription.id)).where(Subscription.status == SubscriptionStatus.ACTIVE)
    )
    active_subscriptions = result.scalar()

    # 3. Trialing Tenants
    result = await db.execute(
        select(func.count(Subscription.id)).where(Subscription.status == SubscriptionStatus.TRIALING)
    )
    trialing_tenants = result.scalar()

    return {
        "total_merchants": total_tenants,
        "active_subscriptions": active_subscriptions,
        "trialing_merchants": trialing_tenants,
        "mrr_estimate": active_subscriptions * 49.0, # Basic tier placeholder
        "health": "healthy"
    }

@router.get("/merchants", response_model=List[dict])
async def list_merchants(
    user: UserClaims = has_permissions(["admin:platform"]),
    db: AsyncSession = Depends(get_db)
):
    """List all merchants and their subscription status."""
    result = await db.execute(
        select(Tenant, Subscription).join(
            Subscription, Tenant.id == Subscription.tenant_id, isouter=True
        )
    )
    merchants = []
    for row in result:
        tenant = row[0]
        sub = row[1]
        merchants.append({
            "id": tenant.id,
            "name": tenant.name,
            "is_active": tenant.is_active,
            "created_at": tenant.created_at,
            "tier": sub.tier if sub else "none",
            "status": sub.status if sub else "none"
        })
    return merchants

@router.patch("/merchants/{tenant_id}/approve")
async def approve_merchant(
    tenant_id: str,
    user: UserClaims = has_permissions(["admin:platform"]),
    db: AsyncSession = Depends(get_db)
):
    """Manually approve a merchant (e.g. after manual verification)."""
    result = await db.execute(select(Tenant).where(Tenant.id == tenant_id))
    tenant = result.scalar_one_or_none()
    
    if not tenant:
        raise HTTPException(status_code=404, detail="Merchant not found")
        
    tenant.is_active = True
    await db.commit()
    return {"status": "approved", "tenant_id": tenant_id}
