import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def t():
    try:
        e=create_async_engine('postgresql+asyncpg://postgres:postgres@35.232.54.225:5432/kloudshop')
        async with e.connect() as c:
            res = await c.execute(text('SELECT 1'))
            print(f"Result: {res.fetchone()}")
        await e.dispose()
    except Exception as ex:
        print(f"Error: {ex}")

if __name__ == "__main__":
    asyncio.run(t())
