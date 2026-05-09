import asyncio
import sys
import os
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

# Add the backend directory to sys.path
sys.path.append(os.getcwd())

DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/kloudshop"

async def wipe_database():
    print("Starting full database wipe...")
    engine = create_async_engine(DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # 1. Get all tenant schemas
        result = await session.execute(text("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'tenant_%'"))
        schemas = [row[0] for row in result.fetchall()]
        
        for schema in schemas:
            print(f"Dropping schema: {schema}")
            await session.execute(text(f"DROP SCHEMA IF EXISTS {schema} CASCADE"))

        # 2. Truncate platform tables
        print("Truncating platform tables...")
        tables = [
            "public.brand_profiles",
            "public.staff_role_assignments",
            "public.onboarding_sessions",
            "public.tenants",
            "public.merchant_users",
            "public.catalog_import_mappings"
        ]
        
        for table in tables:
            try:
                await session.execute(text(f"TRUNCATE TABLE {table} CASCADE"))
                print(f"Truncated {table}")
            except Exception as e:
                print(f"Could not truncate {table} (might not exist yet): {e}")

        await session.commit()
    
    await engine.dispose()
    print("Database wipe complete! The system is now empty.")

if __name__ == "__main__":
    asyncio.run(wipe_database())
