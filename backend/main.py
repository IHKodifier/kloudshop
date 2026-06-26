from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from shared.db import engine
from contextlib import asynccontextmanager
import os

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("KloudShop Core API starting up...")
    try:
        if "sqlite" in engine.url.drivername:
            print("Running local SQLite - automatically creating tables...")
            from shared.db import Base
            
            # Force import all models to register them on Base.metadata
            from modules.auth.models import Invitation, StaffUser, StaffRoleAssignment, B2BInvitation, BuyerUser, ConsumerUser, StaffLoginHistory, StaffSecurityState
            from modules.platform.models import Tenant
            from modules.billing.models import Subscription
            from modules.catalog.models import Product, Variant, Collection, CollectionProduct, ImportJob, RedirectRule, ColorPreset
            from modules.orders.models import Order, OrderItem, OrderEvent, OrderNote
            from modules.inventory.models import (
                StockLocation, Inventory, Supplier, PurchaseOrder, PurchaseOrderLine,
                SupplierPerformanceEvent, StockTransfer, PackagingPreset,
                SupplierScoreWeights, ShippingSettings
            )
            from modules.storefront.models import (
                BrandProfile, StorefrontContent, StaticPage,
                MerchantCarrierConnection, CarrierCheckoutOption
            )
            from modules.onboarding.models import OnboardingSession, ImportMapping
            from modules.themes.models import Theme, ThemeConfiguration
            from modules.features.models import Feature, TenantFeatureActivation, TenantFeatureConfig, FeatureRequest, FeatureRequestVote
            from modules.ai.models import BrandVoiceProfile, AICopywriterLog
            from modules.export.models import ExportJob
            from modules.channels.models import ChannelConnection, ChannelSyncLog
            from modules.pricing.models import PricingRule
            from modules.b2b.models import B2BAccount, PriceList, PriceListItem, ApprovalWorkflow, ApprovalRequest, B2BInvoice
            from modules.shipping.models import StoreShippingProfile, StoreShippingZone, StoreShippingRate
            from modules.tax.models import StoreTaxRate
            from modules.navigation.models import StoreNavigationMenu, StoreNavigationItem
            from modules.policies.models import StorePolicy

            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
                
        import firebase_admin
        from firebase_admin import credentials
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
from modules.b2b.router import router as b2b_router
from modules.pos.router import router as pos_router
from modules.channels.router import router as channels_router
from modules.feeds.router import router as feeds_router
from modules.blog.router import router as blog_router
from modules.i18n.router import router as i18n_router
from modules.storefront.sitemap_router import router as sitemap_router
from modules.analytics.router import router as analytics_router 
from modules.platform.hygiene_router import router as hygiene_router
from modules.internal.media_router import router as media_router
from modules.shipping.router import router as shipping_router
from modules.tax.router import router as tax_router
from modules.navigation.router import router as navigation_router
from modules.policies.router import router as policies_router
from modules.storefront.ssr_router import router as ssr_storefront_router

# API Routes
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
app.include_router(b2b_router, prefix="/api/v1", tags=["B2B"])
app.include_router(pos_router, prefix="/api/v1/pos", tags=["POS"])
app.include_router(channels_router, prefix="/api/v1/channels", tags=["Social Commerce"])
app.include_router(feeds_router, prefix="/api/v1/feeds", tags=["Feeds"])
app.include_router(blog_router, prefix="/api/v1/blog", tags=["Blog"])
app.include_router(i18n_router, prefix="/api/v1/i18n", tags=["i18n"])
app.include_router(sitemap_router, prefix="/api/v1/storefront", tags=["SEO"])
app.include_router(analytics_router, prefix="/api/v1/analytics", tags=["Analytics"])
app.include_router(hygiene_router, prefix="/api/v1/internal", tags=["Hygiene"])
app.include_router(media_router, prefix="/api/v1/internal/media", tags=["Media"])
app.include_router(shipping_router, prefix="/api/v1/shipping", tags=["Shipping"])
app.include_router(tax_router, prefix="/api/v1/tax", tags=["Tax"])
app.include_router(navigation_router, prefix="/api/v1/navigation", tags=["Navigation"])
app.include_router(policies_router, prefix="/api/v1/policies", tags=["Policies"])

# SSR Storefront Routes (Must be after API to avoid shadowing /api)
app.include_router(ssr_storefront_router, tags=["Storefront SSR"])

# Local Media Storage (Simulates GCS in Dev)
backend_dir = os.path.dirname(os.path.abspath(__file__))
media_path = os.path.join(backend_dir, "storage", "media")
if not os.path.exists(media_path):
    os.makedirs(media_path, exist_ok=True)
app.mount("/media", StaticFiles(directory=media_path), name="media")

# Static Files (Flutter Web Build)
static_path = os.path.join(os.path.dirname(backend_dir), "frontend", "build", "web")
if os.path.exists(static_path):
    app.mount("/", StaticFiles(directory=static_path, html=True), name="static")
else:
    print(f"WARNING: Static files not found at {static_path}. Storefront hydration will fail.")
