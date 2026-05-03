import os
os.environ["TESTING"] = "1"
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from main import app
from unittest.mock import patch, MagicMock
from firebase_admin import auth
from shared.auth import validate_token, UserClaims

@pytest_asyncio.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from shared.db import Base
from modules.auth.models import Invitation, StaffUser
from modules.platform.models import Tenant
from modules.billing.models import Subscription
from modules.catalog.models import Product, Variant, Collection, CollectionProduct, ImportJob, RedirectRule
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
from modules.pricing.models import PricingRule
from modules.b2b.models import B2BAccount, PriceList, PriceListItem, ApprovalWorkflow, ApprovalRequest, B2BInvoice
from shared.db import get_db, engine, AsyncSessionLocal as SharedAsyncSessionLocal

@pytest_asyncio.fixture(autouse=True)
async def override_get_db(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    yield
    app.dependency_overrides.pop(get_db, None)

@pytest_asyncio.fixture
async def db_session():
    # Use the shared engine which is already configured for testing (:memory:)
    # Create tables
    async with engine.begin() as conn:
        def strip_schema(conn, metadata):
            for table in metadata.tables.values():
                table.schema = None
        await conn.run_sync(strip_schema, Base.metadata)
        await conn.run_sync(Base.metadata.create_all)
        
    async with SharedAsyncSessionLocal() as session:
        yield session
        await session.close()
    
    # We don't dispose the shared engine here as it's used across tests
    # But we should probably clean up tables after each test if needed
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture
def mock_firebase_user():
    with patch("shared.auth.auth.verify_id_token") as mock:
        mock.return_value = {
            "uid": "test_owner_uid",
            "email": "owner@gmail.com",
            "tenant_id": "t_abc",
            "account_type": "staff",
            "roles": ["owner"],
            "is_owner": True
        }
        yield mock

@pytest.fixture
def mock_firebase_auth():
    with patch("shared.auth.auth.set_custom_user_claims") as mock_set, \
         patch("shared.auth.auth.get_user") as mock_get, \
         patch("shared.auth.auth.create_user") as mock_create, \
         patch("shared.auth.auth.get_user_by_email") as mock_get_email:
        
        mock_get.return_value = MagicMock(uid="target_uid", email="target@g.com", custom_claims={})
        
        def mock_create_user_fn(**kwargs):
            return MagicMock(uid="new_uid", email=kwargs.get("email", "new@g.com"))
        
        mock_create.side_effect = mock_create_user_fn
        mock_get_email.side_effect = auth.UserNotFoundError("User not found")
        
        yield {
            "set": mock_set, 
            "get": mock_get, 
            "create": mock_create, 
            "get_email": mock_get_email
        }

@pytest.fixture
def auth_override():
    """
    Fixture to override validate_token dependency.
    Usage: auth_override(UserClaims(...))
    """
    def _override(user_claims: UserClaims):
        app.dependency_overrides[validate_token] = lambda: user_claims
        return user_claims
    
    yield _override
    app.dependency_overrides.clear()
