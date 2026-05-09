
import asyncio
import sys
import os

# Add the current directory to sys.path to find modules
sys.path.append(os.getcwd())

from shared.db import AsyncSessionLocal
from modules.auth.models import StaffUser, StaffRoleAssignment
from modules.storefront.models import BrandProfile
from modules.onboarding.models import OnboardingSession
from sqlalchemy import select, delete

async def run():
    async with AsyncSessionLocal() as db:
        # 1. Identify the tenant for enigmatekinc
        tenant_id = "enigmatekinc"
        
        print(f"Starting cleanup for tenant: {tenant_id}")
        
        # Use raw SQL to avoid mapper initialization errors
        from sqlalchemy import text
        
        tables = [
            "brand_profiles",
            "products",
            "product_variants",
            "collections",
            "orders",
            "order_items",
            "staff_role_assignments",
            "onboarding_sessions"
        ]
        
        for table in tables:
            try:
                print(f"Clearing table: {table}")
                await db.execute(text(f"DELETE FROM {table} WHERE tenant_id = :tid"), {"tid": tenant_id})
                # Also clear brand_profiles by slug if tid is different
                if table == "brand_profiles":
                     await db.execute(text(f"DELETE FROM {table} WHERE slug = :tid"), {"tid": tenant_id})
            except Exception as e:
                print(f"Skipping {table}: {e}")
        
        await db.commit()
        print(f"Successfully cleared all data for {tenant_id}. You can now start onboarding fresh.")

if __name__ == "__main__":
    asyncio.run(run())
