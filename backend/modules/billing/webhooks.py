from fastapi import APIRouter, Request, Header, HTTPException
import stripe
import os
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from shared.db import AsyncSessionLocal
from .models import Subscription, SubscriptionStatus, SubscriptionTier

router = APIRouter()

# In production, this must be set in env
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

@router.post("/stripe")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None)
):
    """Handle Stripe Webhook events."""
    payload = await request.body()
    
    if not STRIPE_WEBHOOK_SECRET:
        # Development fallback or warning
        print("WARNING: STRIPE_WEBHOOK_SECRET not set. Skipping signature validation.")
        # Only do this in dev; in prod, it's a security risk.
        event = stripe.Event.construct_from(await request.json(), stripe.api_key)
    else:
        try:
            event = stripe.Webhook.construct_event(
                payload, stripe_signature, STRIPE_WEBHOOK_SECRET
            )
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid payload")
        except stripe.error.SignatureVerificationError:
            raise HTTPException(status_code=400, detail="Invalid signature")

    # Handle the event using a dedicated session
    async with AsyncSessionLocal() as db:
        event_type = event.get('type')
        if not event_type:
            raise HTTPException(status_code=400, detail="Missing event type")

        if event_type == 'checkout.session.completed':
            session = event.get('data', {}).get('object')
            if session:
                await handle_checkout_completed(session, db)
        elif event_type == 'customer.subscription.updated':
            stripe_sub = event.get('data', {}).get('object')
            if stripe_sub:
                await handle_subscription_updated(stripe_sub, db)
        elif event_type == 'customer.subscription.deleted':
            stripe_sub = event.get('data', {}).get('object')
            if stripe_sub:
                await handle_subscription_deleted(stripe_sub, db)
        
        await db.commit()

    return {"status": "success"}

async def handle_checkout_completed(session, db: AsyncSession):
    metadata = session.get('metadata', {})
    tenant_id = metadata.get('tenant_id')
    tier = metadata.get('tier')
    
    if tenant_id:
        result = await db.execute(
            select(Subscription).where(Subscription.tenant_id == tenant_id)
        )
        sub = result.scalar_one_or_none()
        if sub:
            sub.stripe_customer_id = session.get('customer')
            sub.stripe_subscription_id = session.get('subscription')
            sub.tier = tier
            sub.status = SubscriptionStatus.ACTIVE
            print(f"INFO: Checkout completed for tenant {tenant_id}. Tier: {tier}")

async def handle_subscription_updated(stripe_sub, db: AsyncSession):
    sub_id = stripe_sub.get('id')
    result = await db.execute(
        select(Subscription).where(Subscription.stripe_subscription_id == sub_id)
    )
    sub = result.scalar_one_or_none()
    if sub:
        sub.status = stripe_sub.get('status')
        # Update trial/period dates if needed
        if stripe_sub.get('trial_end'):
            from datetime import datetime
            sub.trial_end = datetime.fromtimestamp(stripe_sub.get('trial_end'))
        
        if stripe_sub.get('current_period_end'):
            from datetime import datetime
            sub.current_period_end = datetime.fromtimestamp(stripe_sub.get('current_period_end'))
            
        print(f"INFO: Subscription updated for sub_id {sub_id}. Status: {sub.status}")

async def handle_subscription_deleted(stripe_sub, db: AsyncSession):
    sub_id = stripe_sub.get('id')
    result = await db.execute(
        select(Subscription).where(Subscription.stripe_subscription_id == sub_id)
    )
    sub = result.scalar_one_or_none()
    if sub:
        sub.status = SubscriptionStatus.CANCELED
        sub.tier = SubscriptionTier.FREE
        print(f"INFO: Subscription deleted/canceled for sub_id {sub_id}")
