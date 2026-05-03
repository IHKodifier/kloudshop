from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import subprocess
import os
import anyio
from alembic.config import Config
from alembic import command

from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from shared.db import get_db
from modules.platform.models import Tenant
from sqlalchemy import select, text
from datetime import datetime
import uuid

router = APIRouter()

async def verify_gcp_connectivity():
    """
    Performs a 'peace of mind' test by creating and immediately deleting a GCS bucket.
    Ensures gcloud credentials and service account permissions are working.
    """
    test_id = str(uuid.uuid4())[:8]
    bucket_name = f"kloudshop-connectivity-test-{test_id}"
    
    def run_gcloud_tests():
        # Create bucket
        subprocess.run(["gsutil", "mb", f"gs://{bucket_name}"], check=True, capture_output=True, shell=(os.name == 'nt'))
        # Delete bucket immediately
        subprocess.run(["gsutil", "rb", f"gs://{bucket_name}"], check=True, capture_output=True, shell=(os.name == 'nt'))

    try:
        await anyio.to_thread.run_sync(run_gcloud_tests)
        return f"GCP Connectivity Verified (Test bucket {bucket_name} created and deleted)."
    except subprocess.CalledProcessError as e:
        raise Exception(f"GCP Connectivity Test failed: {e.stderr}")

@router.post("/provision-tenant", status_code=status.HTTP_201_CREATED)
async def provision_tenant(
    tenant_id: str,
    user: UserClaims = Depends(validate_token),
    db: AsyncSession = Depends(get_db)

):
    """
    Provisions isolated GCP resources and SQL schema for a new tenant.
    This is an internal idempotent operation.
    """
    from shared.db import engine
    is_sqlite = "sqlite" in engine.url.drivername
    
    
    # 0. Safety Check: Does this user already own a store?
    from modules.auth.models import StaffRoleAssignment
    existing_assignment = await db.execute(
        select(StaffRoleAssignment).where(
            StaffRoleAssignment.staff_user_id == user.uid,
            StaffRoleAssignment.is_owner == True
        )
    )
    if existing_assignment.scalar_one_or_none():
        raise HTTPException(
            status_code=400, 
            detail="You already own a provisioned store. Please refresh your session."
        )

    logs = []
    
    # 1. Connectivity Test (Peace of Mind)
    try:
        test_log = await verify_gcp_connectivity()
        logs.append(test_log)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    # 2. Run GCP Provisioning Script
    script_ext = "ps1" if os.name == "nt" else "sh"
    shell_cmd = "powershell" if os.name == "nt" else "bash"
    script_path = os.path.join(os.getcwd(), "..", "infrastructure", f"provision_tenant.{script_ext}")
    
    env = "dev" 
    
    try:
        cmd = [shell_cmd]
        if os.name == "nt":
            cmd.extend(["-ExecutionPolicy", "Bypass", "-File", script_path, "-TenantId", tenant_id, "-Environment", env])
        else:
            cmd.extend([script_path, tenant_id, env])
            
        def run_script():
            return subprocess.run(cmd, capture_output=True, text=True, check=True)
            
        result = await anyio.to_thread.run_sync(run_script)
        result_stdout = result.stdout
        logs.append(f"GCP Script Output: {result_stdout}")
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"GCP Provisioning failed: {e.stderr}")

    # 3. Create PostgreSQL Schema
    schema_name = f"tenant_{tenant_id}"
    if not is_sqlite:
        try:
            await db.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))
            await db.commit()
            logs.append(f"Database schema {schema_name} verified.")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Database schema creation failed: {str(e)}")

    # 4. Run Alembic Migrations
    if not is_sqlite:
        alembic_cfg = Config("alembic.ini")
        try:
            def run_migrations():
                os.environ["ALEMBIC_SCHEMA"] = schema_name
                command.upgrade(alembic_cfg, "head")
            await anyio.to_thread.run_sync(run_migrations)
            logs.append(f"Alembic migrations applied to {schema_name}.")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Database migration failed: {str(e)}")

    # 5. Create Tenant Record
    try:
        tenant = await db.get(Tenant, tenant_id)
        if not tenant:
            tenant = Tenant(
                id=tenant_id,
                name=tenant_id.capitalize(),
                gcp_project_id="kloudshop-dev",
                gcp_bucket_name=f"gs://kloudshop-dev-{tenant_id}"
            )
            db.add(tenant)
            await db.commit()
            logs.append(f"Tenant record {tenant_id} created in platform schema.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create tenant record: {str(e)}")

    # 6. Set Custom Claims in Firebase & Create Staff Assignment
    try:
        from firebase_admin import auth as firebase_auth
        from modules.auth.models import StaffRoleAssignment
        
        # Update Firebase Custom Claims
        fb_user = firebase_auth.get_user(user.uid)
        claims = fb_user.custom_claims or {}
        claims.update({
            "tenant_id": tenant_id,
            "roles": ["owner"],
            "is_owner": True,
            "account_type": "merchant"
        })
        firebase_auth.set_custom_user_claims(user.uid, claims)
        logs.append(f"Custom claims (tenant_id={tenant_id}) applied to user {user.uid}.")

        # Record ownership in database
        result = await db.execute(
            select(StaffRoleAssignment).where(
                StaffRoleAssignment.staff_user_id == user.uid,
                StaffRoleAssignment.tenant_id == tenant_id
            )
        )
        assignment = result.scalar_one_or_none()
        if not assignment:
            assignment = StaffRoleAssignment(
                staff_user_id=user.uid,
                tenant_id=tenant_id,
                roles=["owner"],
                is_owner=True,
                accepted_at=datetime.utcnow()
            )
            db.add(assignment)
            await db.commit()
            logs.append(f"Staff role assignment created for owner {user.uid}.")
            
    except Exception as e:
        # We don't fail the whole request if claims fail (idempotency), but we log it
        logs.append(f"WARNING: Identity sync failed: {str(e)}")

    return {
        "status": "provisioned",
        "tenant_id": tenant_id,
        "schema": schema_name if not is_sqlite else "shared (sqlite)",
        "logs": "\n".join(logs)
    }
