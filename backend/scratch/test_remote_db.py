import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def test_db():
    url = "postgresql+asyncpg://postgres:postgres@35.232.54.225:5432/kloudshop"
    print(f"Testing DB connection to {url}...")
    engine = create_async_engine(url)
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
