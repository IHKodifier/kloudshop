from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    # Default to a local postgres instance or Cloud SQL proxy
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/kloudshop"
    TESTING: bool = False
    
    class Config:
        env_file = os.path.join(os.path.dirname(__file__), "..", ".env")

settings = Settings()

# Use SQLite for testing to support in-memory async DB
db_url = settings.DATABASE_URL
if settings.TESTING:
    db_url = "sqlite+aiosqlite:///:memory:"

# Async SQLAlchemy Engine (configured for use with PgBouncer later)
engine_kwargs = {
    "echo": False,
}

if "sqlite" not in db_url:
    engine_kwargs.update({
        "pool_size": 10,
        "max_overflow": 20,
    })

engine = create_async_engine(db_url, **engine_kwargs)

# Async Session Maker
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Declarative Base for all SQLAlchemy models
Base = declarative_base()

# Dependency for FastAPI route handlers
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
