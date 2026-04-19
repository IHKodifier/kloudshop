from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from shared.db import engine
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: We rely on Alembic for schema creation in production
    # but we can add startup events here if needed.
    print("KloudShop Core API starting up...")
    yield
    # Shutdown: Dispose of the database engine
    print("KloudShop Core API shutting down...")
    await engine.dispose()

app = FastAPI(
    title="KloudShop Core API",
    description="Modular monolith powering the KloudShop commerce platform.",
    version="0.1.0",
    lifespan=lifespan
)

# Configure CORS for Flutter Web storefronts and admin panels
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # TODO: Tighten this dynamically in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "KloudShop Core API"}

# ---------------------------------------------------------
# Routers will be included here as modules are developed
# e.g., app.include_router(auth.router, prefix="/auth")
# ---------------------------------------------------------
