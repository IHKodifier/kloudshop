import pytest
from httpx import AsyncClient
from modules.orders.models import Order
from modules.inventory.models import Inventory, StockLocation
from modules.catalog.models import Product, Variant
from modules.b2b.models import B2BAccount
from shared.auth import UserClaims
from datetime import datetime, timedelta

@pytest.mark.asyncio
async def test_analytics_overview(client: AsyncClient, db_session, auth_override):
    tenant_id = "t_analytics"
    auth_override(UserClaims(uid="u1", email="a@t.com", tenant_id=tenant_id, roles=["owner"]))
    
    # Setup Orders
    order1 = Order(
        tenant_id=tenant_id, 
        order_number="KS-1001",
        email="c1@test.com",
        subtotal=100.00,
        grand_total=100.00, 
        payment_status="paid",
        fulfilment_status="unfulfilled",
        placed_at=datetime.utcnow()
    )
    order2 = Order(
        tenant_id=tenant_id, 
        order_number="KS-1002",
        email="c2@test.com",
        subtotal=50.00,
        grand_total=50.00, 
        payment_status="paid",
        fulfilment_status="unfulfilled",
        placed_at=datetime.utcnow()
    )
    db_session.add_all([order1, order2])
    await db_session.commit()
    
    headers = {"X-Tenant-ID": tenant_id}
    response = await client.get("/api/v1/analytics/overview", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["gmv"] == 150.00
    assert data["order_count"] == 2
    assert data["aov"] == 75.00

@pytest.mark.asyncio
async def test_analytics_needs_attention(client: AsyncClient, db_session, auth_override):
    tenant_id = "t_attention"
    auth_override(UserClaims(uid="u1", email="a@t.com", tenant_id=tenant_id, roles=["owner"]))
    
    # 1. Overdue Order
    overdue_date = datetime.utcnow() - timedelta(hours=48)
    order = Order(
        tenant_id=tenant_id, 
        order_number="KS-OVERDUE",
        email="c@test.com",
        subtotal=10.00,
        grand_total=10.00, 
        payment_status="paid",
        fulfilment_status="unfulfilled",
        placed_at=overdue_date
    )
    db_session.add(order)
    
    # 2. Low Stock
    location = StockLocation(name="Main", location_type="warehouse")
    db_session.add(location)
    await db_session.flush()
    
    product = Product(tenant_id=tenant_id, title="P1", slug="p1", status="active", created_by="u1")
    db_session.add(product)
    await db_session.flush()
    
    variant = Variant(product_id=product.product_id, tenant_id=tenant_id, sku="SKU1", price=10.00)
    db_session.add(variant)
    await db_session.flush()
    
    inventory = Inventory(
        variant_id=variant.variant_id,
        stock_location_id=location.stock_location_id,
        quantity_on_hand=5,
        reorder_point=10
    )
    db_session.add(inventory)
    
    # 3. Pending B2B
    b2b = B2BAccount(
        tenant_id=tenant_id, 
        company_name="Test Co", 
        contact_first_name="John",
        contact_last_name="Doe",
        contact_email="john@test.com",
        account_status="pending_approval"
    )
    db_session.add(b2b)
    
    await db_session.commit()
    
    headers = {"X-Tenant-ID": tenant_id}
    response = await client.get("/api/v1/analytics/needs-attention", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["pending_orders_overdue"] == 1
    assert data["low_stock_variants"] == 1
    assert data["pending_b2b_approvals"] == 1
    assert data["total_alerts"] == 3

@pytest.mark.asyncio
async def test_analytics_forecasting_looker(client: AsyncClient, auth_override):
    tenant_id = "t_misc"
    auth_override(UserClaims(uid="u1", email="a@t.com", tenant_id=tenant_id, roles=["owner"]))
    headers = {"X-Tenant-ID": tenant_id}
    
    # Forecasting
    response = await client.get("/api/v1/analytics/forecasting", headers=headers)
    assert response.status_code == 200
    assert "provider" in response.json()
    
    # Looker
    response = await client.get("/api/v1/analytics/looker/token", headers=headers)
    assert response.status_code == 200
    assert "embed_url" in response.json()
