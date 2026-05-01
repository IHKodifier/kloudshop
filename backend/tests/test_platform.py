import pytest
from httpx import AsyncClient
from unittest.mock import patch, MagicMock
from shared.auth import UserClaims

@pytest.mark.asyncio
async def test_platform_dashboard_access_denied_for_merchant(auth_override, client: AsyncClient):
    auth_override(UserClaims(
        uid="user123",
        email="owner@acme.com",
        tenant_id="acme",
        account_type="merchant",
        roles=["owner"],
        is_owner=True
    ))
    
    response = await client.get("/api/v1/platform/dashboard")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_platform_dashboard_access_granted_for_admin(auth_override, client: AsyncClient):
    auth_override(UserClaims(
        uid="admin123",
        email="admin@kloudshop.com",
        tenant_id=None,
        account_type="platform_admin",
        roles=["platform_admin"],
        is_owner=False
    ))
    
    response = await client.get("/api/v1/platform/dashboard")
    assert response.status_code == 200
    data = response.json()
    assert "total_merchants" in data
    assert "active_subscriptions" in data
