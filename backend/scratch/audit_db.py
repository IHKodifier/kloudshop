import asyncio
import sys
import os
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

# Add the backend directory to sys.path
sys.path.append(os.getcwd())

DATABASE_URL = "sqlite+aiosqlite:///backend/test_persistent.db"

async def audit_database():
    print("Starting database audit...")
    engine = create_async_engine(DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # 1. Check all products
        print("\n--- Products ---")
        result = await session.execute(text("SELECT product_id, tenant_id, title, status FROM products"))
        products = result.fetchall()
        for p in products:
            print(f"Product: {p.title} | ID: {p.product_id} | Tenant: {p.tenant_id} | Status: {p.status}")

        # 2. Check all orders
        print("\n--- Orders ---")
        result = await session.execute(text("SELECT order_number, tenant_id, grand_total FROM orders"))
        orders = result.fetchall()
        for o in orders:
            print(f"Order: {o.order_number} | Tenant: {o.tenant_id} | Total: {o.grand_total}")

        # 3. Check all brand profiles
        print("\n--- Brand Profiles ---")
        result = await session.execute(text("SELECT tenant_id, brand_name, slug FROM brand_profiles"))
        brands = result.fetchall()
        for b in brands:
            print(f"Brand: {b.brand_name} | Slug: {b.slug} | Tenant: {b.tenant_id}")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(audit_database())
