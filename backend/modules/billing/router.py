from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from datetime import datetime
import stripe
import os

from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from shared.db import get_db
from .models import Subscription, SubscriptionTier, SubscriptionStatus
from .schemas import SubscriptionResponse, UpgradeRequest, InvoiceResponse, PortalSessionResponse

router = APIRouter()

# Stripe API Key initialization
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

@router.get("/subscription", response_model=SubscriptionResponse)
async def get_subscription(
    user: UserClaims = has_permissions(["billing:manage"]),
    db: AsyncSession = Depends(get_db)
):
    """Fetch current subscription status for the tenant."""
    result = await db.execute(
        select(Subscription).where(Subscription.tenant_id == user.tenant_id)
    )
    subscription = result.scalar_one_or_none()
    
    if not subscription:
        # Create a default trial subscription if none exists
        subscription = Subscription(
            tenant_id=user.tenant_id,
            tier=SubscriptionTier.FREE,
            status=SubscriptionStatus.TRIALING
        )
        db.add(subscription)
        await db.commit()
        await db.refresh(subscription)
    
    return subscription

@router.post("/upgrade")
async def create_checkout_session(
    request: UpgradeRequest,
    user: UserClaims = has_permissions(["billing:manage"]),
    db: AsyncSession = Depends(get_db)
):
    """Initiates a Stripe Checkout Session for tier upgrades."""
    # 1. Fetch Subscription/Customer
    result = await db.execute(
        select(Subscription).where(Subscription.tenant_id == user.tenant_id)
    )
    subscription = result.scalar_one_or_none()
    
    if not subscription:
         raise HTTPException(status_code=404, detail="Subscription record not found")

    # 2. Logic to map plan_id to Stripe Price ID
    price_map = {
        "basic": os.getenv("STRIPE_PRICE_BASIC"),
        "pro": os.getenv("STRIPE_PRICE_PRO"),
        "enterprise": os.getenv("STRIPE_PRICE_ENTERPRISE"),
    }
    
    price_id = price_map.get(request.plan_id)
    if not price_id:
        raise HTTPException(status_code=400, detail="Invalid plan ID")

    try:
        # 3. Create Stripe Checkout Session
        checkout_session = stripe.checkout.Session.create(
            customer=subscription.stripe_customer_id,
            payment_method_types=['card'],
            line_items=[{
                'price': price_id,
                'quantity': 1,
            }],
            mode='subscription',
            success_url=request.success_url + "?session_id={CHECKOUT_SESSION_ID}",
            cancel_url=request.cancel_url,
            subscription_data={
                "metadata": {
                    "tenant_id": user.tenant_id,
                    "tier": request.plan_id
                }
            },
            metadata={
                "tenant_id": user.tenant_id,
                "tier": request.plan_id
            }
        )
        return {"checkout_url": checkout_session.url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stripe Session Creation Failed: {str(e)}")

@router.get("/invoices", response_model=List[InvoiceResponse])
async def list_invoices(
    user: UserClaims = has_permissions(["billing:manage"]),
    db: AsyncSession = Depends(get_db)
):
    """Lists all invoices from Stripe for the current tenant."""
    result = await db.execute(
        select(Subscription).where(Subscription.tenant_id == user.tenant_id)
    )
    subscription = result.scalar_one_or_none()
    
    if not subscription or not subscription.stripe_customer_id:
        return []

    try:
        invoices = stripe.Invoice.list(customer=subscription.stripe_customer_id)
        return [
            {
                "id": inv.id,
                "amount_paid": inv.amount_paid,
                "currency": inv.currency,
                "status": inv.status,
                "hosted_invoice_url": inv.hosted_invoice_url,
                "invoice_pdf": inv.invoice_pdf,
                "created": datetime.fromtimestamp(inv.created)
            } for inv in invoices.data
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stripe Invoice Fetch Failed: {str(e)}")

@router.post("/stripe/portal", response_model=PortalSessionResponse)
async def create_portal_session(
    return_url: str = "http://localhost:3000/dashboard/billing", # Default to dashboard
    user: UserClaims = has_permissions(["billing:manage"]),
    db: AsyncSession = Depends(get_db)
):
    """Creates a Stripe Billing Portal session."""
    result = await db.execute(
        select(Subscription).where(Subscription.tenant_id == user.tenant_id)
    )
    subscription = result.scalar_one_or_none()
    
    if not subscription or not subscription.stripe_customer_id:
        raise HTTPException(status_code=400, detail="No Stripe customer found for this tenant")

    try:
        session = stripe.billing_portal.Session.create(
            customer=subscription.stripe_customer_id,
            return_url=return_url,
        )
        return {"url": session.url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stripe Portal Session Failed: {str(e)}")

# Internal Endpoints (Internal/Webhook only)
@router.post("/internal/trial-check", status_code=status.HTTP_200_OK)
async def trigger_trial_check(
    db: AsyncSession = Depends(get_db)
):
    """Manually trigger the trial expiration check."""
    from .tasks import check_trial_expirations
    await check_trial_expirations(db)
    return {"status": "triggered"}
