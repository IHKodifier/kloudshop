import asyncio
import os
import sys
sys.path.append(os.getcwd())
from shared.db import engine

async def test_conn():
    try:
        from sqlalchemy import text
        async with engine.begin() as conn:
            await conn.execute(text("CREATE SCHEMA IF NOT EXISTS tenant_template"))
            print("Successfully created/verified schema tenant_template")
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_conn())
