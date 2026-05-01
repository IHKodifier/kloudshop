import pytest
from httpx import AsyncClient
from unittest.mock import patch, MagicMock
from datetime import datetime, timedelta
from shared.auth import UserClaims
from modules.billing.models import Subscription, SubscriptionStatus, SubscriptionTier
from modules.platform.models import Tenant

@pytest.mark.asyncio
async def test_get_subscription_success(client: AsyncClient, auth_override, db_session):
    """Verify that a merchant can fetch their subscription."""
    auth_override(UserClaims(
        uid="user123",
        email="merchant@test.com",
        tenant_id="tenant_abc",
        account_type="merchant",
        roles=["owner"],
        is_owner=True
    ))
    
    response = await client.get("/api/v1/billing/subscription")
    assert response.status_code == 200
    data = response.json()
    assert data["tenant_id"] == "tenant_abc"
    assert data["status"] == "trialing"

@pytest.mark.asyncio
async def test_list_invoices_empty(client: AsyncClient, auth_override, db_session):
    """Verify that list_invoices returns empty list if no stripe customer."""
    auth_override(UserClaims(
        uid="user123",
        email="merchant@test.com",
        tenant_id="tenant_abc",
        account_type="merchant",
        roles=["owner"],
        is_owner=True
    ))
    
    response = await client.get("/api/v1/billing/invoices")
    assert response.status_code == 200
    assert response.json() == []

@pytest.mark.asyncio
async def test_create_portal_session_fail_no_customer(client: AsyncClient, auth_override, db_session):
    """Verify that creating portal session fails without a stripe customer."""
    auth_override(UserClaims(
        uid="user123",
        email="merchant@test.com",
        tenant_id="tenant_abc",
        account_type="merchant",
        roles=["owner"],
        is_owner=True
    ))
    
    response = await client.post("/api/v1/billing/stripe/portal")
    assert response.status_code == 400
    assert "No Stripe customer found" in response.json()["detail"]

@pytest.mark.asyncio
async def test_trial_check_task(db_session):
    """Verify that the trial check task suspends expired tenants."""
    from modules.billing.tasks import check_trial_expirations
    
    # 1. Setup expired tenant
    tenant = Tenant(id="expired_tenant", name="Expired Tenant", is_active=True)
    db_session.add(tenant)
    
    subscription = Subscription(
        tenant_id="expired_tenant",
        status=SubscriptionStatus.TRIALING,
        trial_end=datetime.utcnow() - timedelta(days=1) # Expired yesterday
    )
    db_session.add(subscription)
    await db_session.commit()
    
    # 2. Run task
    await check_trial_expirations(db_session)
    
    # 3. Verify
    await db_session.refresh(tenant)
    await db_session.refresh(subscription)
    
    assert tenant.is_active is False
    assert subscription.status == SubscriptionStatus.CANCELED
