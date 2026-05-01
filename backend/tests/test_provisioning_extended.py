import pytest
from httpx import AsyncClient
from unittest.mock import patch, MagicMock
from modules.platform.models import Tenant
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from shared.auth import UserClaims
from main import app
from shared.db import get_db
from subprocess import CalledProcessError

@pytest.mark.asyncio
async def test_provision_tenant_idempotency(client: AsyncClient, auth_override, db_session):
    """Verify that calling provision-tenant twice for the same tenant is idempotent."""
    auth_override(UserClaims(
        uid="admin123",
        email="admin@kloudshop.com",
        tenant_id=None,
        account_type="platform_admin",
        roles=["platform_admin"],
        is_owner=False
    ))

    tenant_id = "acme_idempotent"
    headers = {"Authorization": "Bearer valid_token"}

    with patch("subprocess.run") as mock_run:
        mock_run.return_value = MagicMock(stdout="Success", returncode=0)

        # First call
        resp1 = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
        assert resp1.status_code == 201

        # Second call
        resp2 = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
        assert resp2.status_code == 201
        
        # Verify only one tenant record exists
        result = await db_session.execute(select(Tenant).where(Tenant.id == tenant_id))
        tenants = result.scalars().all()
        assert len(tenants) == 1


@pytest.mark.asyncio
async def test_provision_tenant_script_failure(client: AsyncClient, auth_override, db_session):
    """Verify that a script failure returns 500."""
    auth_override(UserClaims(
        uid="admin123",
        email="admin@kloudshop.com",
        tenant_id=None,
        account_type="platform_admin",
        roles=["platform_admin"],
        is_owner=False
    ))

    tenant_id = "fail_tenant"
    headers = {"Authorization": "Bearer valid_token"}

    with patch("subprocess.run") as mock_run:
        mock_run.side_effect = CalledProcessError(1, "script.sh", stderr="GCP Quote Exceeded")

        response = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
        assert response.status_code == 500
        assert "GCP Quote Exceeded" in response.json()["detail"]


@pytest.mark.asyncio
async def test_provision_tenant_record_creation(client: AsyncClient, auth_override, db_session):
    """Verify that a Tenant record is correctly created in the platform schema."""
    auth_override(UserClaims(
        uid="admin123",
        email="admin@kloudshop.com",
        tenant_id=None,
        account_type="platform_admin",
        roles=["platform_admin"],
        is_owner=False
    ))

    tenant_id = "new_corp"
    headers = {"Authorization": "Bearer valid_token"}

    with patch("subprocess.run") as mock_run:
        mock_run.return_value = MagicMock(stdout="Success", returncode=0)

        response = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
        assert response.status_code == 201

        # Check Tenant Record
        result = await db_session.execute(select(Tenant).where(Tenant.id == tenant_id))
        tenant = result.scalar_one_or_none()
        assert tenant is not None
        assert tenant.gcp_bucket_name == f"gs://kloudshop-dev-{tenant_id}"

        # Check if tables exist (StaffUser as a proxy for tenant schema tables)
        # Note: In SQLite tests, they are all in the same DB.
        from sqlalchemy import text
        result = await db_session.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))
        tables = [row[0] for row in result.fetchall()]
        assert "staff_users" in tables
        assert "invitations" in tables


@pytest.mark.asyncio
async def test_provision_tenant_migration_call(client: AsyncClient, auth_override, db_session):
    """Verify that Alembic upgrade is called when not in SQLite."""
    auth_override(UserClaims(
        uid="admin123",
        email="admin@kloudshop.com",
        tenant_id=None,
        account_type="platform_admin",
        roles=["platform_admin"],
        is_owner=False
    ))

    tenant_id = "postgres_test"
    headers = {"Authorization": "Bearer valid_token"}

    # Mock engine to simulate Postgres
    with patch("shared.db.engine") as mock_engine:
        mock_engine.url.drivername = "postgresql+asyncpg"
        
        # Use a fully mocked DB session
        mock_db = MagicMock(spec=AsyncSession)
        app.dependency_overrides[get_db] = lambda: mock_db
        
        with patch("subprocess.run") as mock_run, \
             patch("alembic.command.upgrade") as mock_upgrade:
            
            mock_run.return_value = MagicMock(stdout="Success", returncode=0)
            mock_db.execute.return_value = MagicMock()
            mock_db.get.return_value = None # Simulate new tenant
            
            response = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
            if response.status_code != 201:
                print(f"Error detail: {response.json()}")
            assert response.status_code == 201
            
            # Verify alembic upgrade was called
            mock_upgrade.assert_called_once()
            args, _ = mock_upgrade.call_args
            assert args[1] == "head"

