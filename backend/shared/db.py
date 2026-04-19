from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Default to a local postgres instance or Cloud SQL proxy
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/kloudshop"
    
    class Config:
        env_file = ".env"

settings = Settings()

# Async SQLAlchemy Engine (configured for use with PgBouncer later)
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    pool_size=10,
    max_overflow=20,
)

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
