import pytest
from httpx import AsyncClient
from modules.orders.models import Order
from modules.b2b.models import B2BAccount
from shared.auth import UserClaims

@pytest.mark.asyncio
async def test_gdpr_erasure(client: AsyncClient, db_session, auth_override):
    tenant_id = "t_hygiene"
    email = "user@to_erase.com"
    auth_override(UserClaims(uid="u1", email="owner@test.com", tenant_id=tenant_id, roles=["owner"], is_owner=True))
    
    # Setup data
    order = Order(
        tenant_id=tenant_id, 
        order_number="KS-1", 
        email=email,
        subtotal=10.0,
        grand_total=10.0,
        shipping_name="John Doe"
    )
    b2b = B2BAccount(
        tenant_id=tenant_id, 
        company_name="Old Co", 
        contact_email=email,
        contact_first_name="John",
        contact_last_name="Doe"
    )
    db_session.add_all([order, b2b])
    await db_session.commit()
    
    # Trigger Erasure
    headers = {"X-Tenant-ID": tenant_id}
    response = await client.post("/api/v1/internal/gdpr/erasure", json={"email": email}, headers=headers)
    assert response.status_code == 200
    
    # Verify Anonymization
    await db_session.refresh(order)
    await db_session.refresh(b2b)
    
    assert order.email == "redacted@kloudshop.io"
    assert order.shipping_name == "Deleted User"
    assert b2b.contact_first_name == "Deleted"
    assert b2b.contact_email != email
    assert "redacted" in b2b.contact_email

@pytest.mark.asyncio
async def test_hygiene_health_and_version(client: AsyncClient, auth_override):
    tenant_id = "t_hygiene"
    auth_override(UserClaims(uid="u1", email="owner@test.com", tenant_id=tenant_id, roles=["owner"], is_owner=True))
    headers = {"X-Tenant-ID": tenant_id}
    
    # Version
    response = await client.get("/api/v1/internal/version", headers=headers)
    assert response.status_code == 200
    assert "version" in response.json()
    
    # Health
    response = await client.get("/api/v1/internal/health/schema-drift", headers=headers)
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
