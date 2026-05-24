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
        uid="admin_idem",
        email="admin_idem@kloudshop.com",
        tenant_id=None,
        account_type="platform_admin",
        roles=["platform_admin"],
        is_owner=False
    ))

    tenant_id = "acmeidempotent"  # No underscores - avoids sanitizer converting _ to -
    headers = {"Authorization": "Bearer valid_token"}

    with patch("subprocess.run") as mock_run:
        mock_run.return_value = MagicMock(stdout="Success", returncode=0)

        # First call
        resp1 = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
        assert resp1.status_code == 201
        actual_tenant_id = resp1.json()["tenant_id"]

        # Second call (same tenant — must be idempotent, not blocked)
        resp2 = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
        assert resp2.status_code == 201
        
        # Expire cached state and re-query using the sanitized ID from the response
        await db_session.close()
        result = await db_session.execute(select(Tenant).where(Tenant.id == actual_tenant_id))
        tenants = result.scalars().all()
        assert len(tenants) == 1


@pytest.mark.asyncio
async def test_provision_tenant_script_failure(client: AsyncClient, auth_override, db_session):
    """Verify that a script failure returns 500."""
    import os
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

    # Set env to non-dev so script execution path is triggered
    with patch.dict(os.environ, {"KLOUDSHOP_ENV": "production"}), \
         patch("subprocess.run") as mock_run:
        mock_run.side_effect = CalledProcessError(1, "script.sh", stderr="GCP Quote Exceeded")

        response = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
        assert response.status_code == 500
        assert "GCP Quote Exceeded" in response.json()["detail"]


@pytest.mark.asyncio
async def test_provision_tenant_record_creation(client: AsyncClient, auth_override, db_session):
    """Verify that a Tenant record is correctly created in the platform schema."""
    auth_override(UserClaims(
        uid="admin_rec",
        email="admin_rec@kloudshop.com",
        tenant_id=None,
        account_type="platform_admin",
        roles=["platform_admin"],
        is_owner=False
    ))

    tenant_id = "newcorp"  # No underscores - avoids sanitizer converting _ to -
    headers = {"Authorization": "Bearer valid_token"}

    with patch("subprocess.run") as mock_run:
        mock_run.return_value = MagicMock(stdout="Success", returncode=0)

        response = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
        assert response.status_code == 201
        # The API response confirms provisioning succeeded
        data = response.json()
        assert data["status"] == "provisioned"
        actual_tenant_id = data["tenant_id"]  # May differ from input after sanitization

        # Expire the session's identity cache so we re-read from the DB
        await db_session.close()
        result = await db_session.execute(select(Tenant).where(Tenant.id == actual_tenant_id))
        tenant = result.scalar_one_or_none()
        assert tenant is not None
        assert tenant.gcp_bucket_name == f"gs://kloudshop-dev-{actual_tenant_id}"

        # Check if tables exist (StockUser as a proxy for tenant schema tables)
        # Note: In SQLite tests, they are all in the same DB.
        from sqlalchemy import text
        result = await db_session.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))
        tables = [row[0] for row in result.fetchall()]
        assert "staff_users" in tables
        assert "invitations" in tables


@pytest.mark.asyncio
async def test_provision_tenant_migration_call(client: AsyncClient, auth_override, db_session):
    """Verify that Alembic upgrade is called when not in SQLite."""
    import os
    auth_override(UserClaims(
        uid="admin_mig",
        email="admin_mig@kloudshop.com",
        tenant_id=None,
        account_type="platform_admin",
        roles=["platform_admin"],
        is_owner=False
    ))

    tenant_id = "postgres_test"
    headers = {"Authorization": "Bearer valid_token"}

    # Patch engine URL to simulate Postgres + set non-dev env
    # Also patch db.execute so CREATE SCHEMA doesn't run on the real SQLite DB
    with patch.dict(os.environ, {"KLOUDSHOP_ENV": "production"}), \
         patch("modules.internal.provisioning.engine") as mock_engine, \
         patch("subprocess.run") as mock_run, \
         patch("alembic.command.upgrade") as mock_upgrade, \
         patch("sqlalchemy.ext.asyncio.AsyncSession.execute") as mock_execute:

        mock_engine.url.drivername = "postgresql+asyncpg"
        mock_run.return_value = MagicMock(stdout="Success", returncode=0)
        # mock_execute returns an empty result for all DB calls in this path
        mock_execute.return_value = MagicMock(scalar_one_or_none=MagicMock(return_value=None),
                                               scalars=MagicMock(return_value=MagicMock(first=MagicMock(return_value=None))))

        response = await client.post(f"/api/v1/internal/provision-tenant?tenant_id={tenant_id}", headers=headers)
        if response.status_code not in (201, 500):
            print(f"Error detail: {response.json()}")

        # The key assertion: alembic upgrade must have been called
        mock_upgrade.assert_called_once()
        args, _ = mock_upgrade.call_args
        assert args[1] == "head"

