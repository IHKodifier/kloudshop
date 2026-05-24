from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from datetime import datetime, timezone
from .models import Subscription, SubscriptionStatus
from modules.platform.models import Tenant

async def check_trial_expirations(db: AsyncSession):
    """
    Finds tenants with expired trials and suspends their access.
    In a real app, this would also send email notifications via Resend.
    """
    now = datetime.now(timezone.utc)
    
    # 1. Find expired trial subscriptions that are still 'trialing'
    result = await db.execute(
        select(Subscription).where(
            Subscription.status == SubscriptionStatus.TRIALING,
            Subscription.trial_end < now
        )
    )
    expired_subscriptions = result.scalars().all()
    
    for sub in expired_subscriptions:
        # Update subscription status
        sub.status = SubscriptionStatus.CANCELED # or UNPAID
        
        # Update tenant activity status
        await db.execute(
            update(Tenant)
            .where(Tenant.id == sub.tenant_id)
            .values(is_active=False)
        )
        
        print(f"Suspended tenant {sub.tenant_id} due to trial expiration.")
    
    await db.commit()
