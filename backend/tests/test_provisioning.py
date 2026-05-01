import pytest
from httpx import AsyncClient
from unittest.mock import patch, MagicMock
from shared.auth import UserClaims
from main import app
from shared.db import get_db

@pytest.mark.asyncio
async def test_provision_tenant_unauthorized(client: AsyncClient):
    """Verify that only users with internal:provision can call this."""
    response = await client.post("/api/v1/internal/provision-tenant?tenant_id=acme")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_provision_tenant_success(client: AsyncClient, auth_override, db_session):
    """Verify that provisioning succeeds with correct permissions and mocked script."""
    auth_override(UserClaims(
        uid="admin123",
        email="admin@kloudshop.com",
        tenant_id=None,
        account_type="platform_admin",
        roles=["platform_admin"],
        is_owner=False
    ))
    
    # Mock the subprocess.run to avoid calling real gcloud in unit tests
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = MagicMock(stdout="Success logs", returncode=0)
        
        headers = {"Authorization": "Bearer valid_token"}
        response = await client.post("/api/v1/internal/provision-tenant?tenant_id=acme", headers=headers)
        if response.status_code != 201:
            print(f"DEBUG: {response.status_code} - {response.text}")
        assert response.status_code == 201
        data = response.json()
        assert data["status"] == "provisioned"
        assert data["tenant_id"] == "acme"
        assert data["schema"] == "shared (sqlite)"
        
