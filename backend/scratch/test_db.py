import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
import os
import sys

# Add backend to path to import settings
sys.path.append(os.path.join(os.getcwd(), 'backend'))

async def test_db():
    from shared.db import settings
    print(f"Testing DB connection to {settings.DATABASE_URL}...")
    engine = create_async_engine(settings.DATABASE_URL)
    try:
        async with engine.connect() as conn:
            result = await conn.execute(text("SELECT 1"))
            print(f"DB connection successful: {result.fetchone()}")
    except Exception as e:
        print(f"DB connection failed: {e}")
    finally:
        await engine.dispose()

if __name__ == "__main__":
    asyncio.run(test_db())
