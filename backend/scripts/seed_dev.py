import asyncio
import os
import sys

# Add backend directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from shared.db import Base
from modules.auth.models import StaffUser, StaffRoleAssignment, Invitation
from modules.platform.models import Tenant

# Cloud SQL Public IP (authorized)
DATABASE_URL = "postgresql+asyncpg://postgres:postgres@35.232.54.225:5432/kloudshop"

async def seed():
    print(f"Connecting to {DATABASE_URL}...")
    engine = create_async_engine(DATABASE_URL)
    
    try:
        async with engine.begin() as conn:
            # 1. Create schemas
            print("Creating schemas...")
            await conn.execute(text("CREATE SCHEMA IF NOT EXISTS kloudshop_platform"))
            
            # 2. Create tables
            print("Creating tables...")
            # Note: create_all is synchronous, run_sync handles it
            await conn.run_sync(Base.metadata.create_all)
            
            # 3. Seed Test Merchant
            print("Seeding test merchant...")
            check_tenant = await conn.execute(
                text("SELECT id FROM kloudshop_platform.tenants WHERE id = :id"),
                {"id": "testmerchant"}
            )
            if not check_tenant.fetchone():
                await conn.execute(
                    text("""
                        INSERT INTO kloudshop_platform.tenants 
                        (id, name, gcp_project_id, gcp_bucket_name, created_at, is_active, config) 
                        VALUES (:id, :name, :project, :bucket, NOW(), true, '{}')
                    """),
                    {
                        "id": "testmerchant",
                        "name": "Test Merchant",
                        "project": "kloudshop-dev",
                        "bucket": "gs://kloudshop-dev-testmerchant"
                    }
                )
                print("SUCCESS: Seeded 'testmerchant'")
            else:
                print("INFO: 'testmerchant' already exists")

        print("Done!")
    except Exception as e:
        print(f"ERROR during seeding: {e}")
    finally:
        await engine.dispose()

if __name__ == "__main__":
    asyncio.run(seed())
