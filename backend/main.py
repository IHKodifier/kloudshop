from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from shared.db import engine
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("KloudShop Core API starting up...")
    try:
        if "sqlite" in engine.url.drivername:
            print("Running local SQLite - automatically creating tables...")
            from shared.db import Base
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
                
        import firebase_admin
        from firebase_admin import credentials
        import os
        if not firebase_admin._apps:
            sa_path = "service_account.json"
            if not os.path.exists(sa_path):
                # Try to find it if we're in a different context
                sa_path = os.path.join(os.getcwd(), "backend", "service_account.json")
            
            if os.path.exists(sa_path):
                cred = credentials.Certificate(sa_path)
                firebase_admin.initialize_app(cred)
                print(f"SUCCESS: Firebase Admin initialized with {sa_path}")
            else:
                firebase_admin.initialize_app()
                print("SUCCESS: Firebase Admin initialized with default credentials.")
    except Exception as e:
        print(f"ERROR: Failed to initialize Firebase Admin: {e}")
        
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
    allow_origins=[], # Must be empty when using regex with credentials
    allow_origin_regex=r"https?://(?:localhost|127\.0\.0\.1)(?::\d+)?",

    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "KloudShop Core API"}

# ---------------------------------------------------------
# Routers included here as modules are developed
# ---------------------------------------------------------
from modules.auth.router import router as auth_router
from modules.internal.provisioning import router as provisioning_router
from modules.billing.router import router as billing_router
from modules.billing.webhooks import router as billing_webhooks
from modules.platform.router import router as platform_router
from modules.catalog.router import router as catalog_router
from modules.orders.router import router as orders_router
from modules.inventory.router import router as inventory_router
from modules.storefront.router import router as storefront_router
from modules.onboarding.router import router as onboarding_router
from modules.themes.router import router as themes_router
from modules.features.router import router as features_router
from modules.ai.router import router as ai_router
from modules.export.router import router as export_router
from modules.pricing.router import router as pricing_router

app.include_router(auth_router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(provisioning_router, prefix="/api/v1/internal", tags=["Internal"])
app.include_router(billing_router, prefix="/api/v1/billing", tags=["Billing"])
app.include_router(billing_webhooks, prefix="/api/v1/webhooks", tags=["Webhooks"])
app.include_router(platform_router, prefix="/api/v1/platform", tags=["Platform"])
app.include_router(catalog_router, prefix="/api/v1/products", tags=["Catalog"])
app.include_router(orders_router, prefix="/api/v1/orders", tags=["Orders"])
app.include_router(inventory_router, prefix="/api/v1/inventory", tags=["Inventory"])
app.include_router(storefront_router, prefix="/api/v1/storefront", tags=["Storefront"])
app.include_router(onboarding_router, prefix="/api/v1/onboarding", tags=["Onboarding"])
app.include_router(themes_router, prefix="/api/v1/themes", tags=["Themes"])
app.include_router(features_router, prefix="/api/v1/features", tags=["Features"])
app.include_router(ai_router, prefix="/api/v1/ai", tags=["AI"])
app.include_router(export_router, prefix="/api/v1/export", tags=["Export"])
app.include_router(pricing_router, prefix="/api/v1/pricing", tags=["Pricing"])
