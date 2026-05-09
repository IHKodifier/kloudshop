
import asyncio
import sys
import os

# Add the current directory to sys.path to find modules
sys.path.append(os.getcwd())

from shared.db import AsyncSessionLocal
from modules.auth.models import MerchantUser
from sqlalchemy import select

async def run():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(MerchantUser))
        users = result.scalars().all()
        for u in users:
            print(f"Email: {u.email}, Tenant: {u.tenant_id}")

if __name__ == "__main__":
    asyncio.run(run())
