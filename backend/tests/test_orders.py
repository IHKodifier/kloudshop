import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from decimal import Decimal
from datetime import datetime

from modules.catalog.models import Product, Variant
from modules.orders.models import Order, OrderItem
from modules.inventory.models import StockLocation, Inventory

@pytest.mark.asyncio
async def test_order_checkout_flow(client: AsyncClient, db_session: AsyncSession, mock_firebase_user):
    """
    Test end-to-end checkout: payment-intent -> confirm -> inventory decrement.
    """
    # 1. Setup Data
    tenant_id = "t_abc" # Matching mock_firebase_user default
    user_id = "test_owner_uid"
    
    # Create Product & Variant
    product = Product(
        title="Test Hiking Jacket",
        slug="test-hiking-jacket",
        tenant_id=tenant_id,
        created_by=user_id,
        status='active'
    )
    db_session.add(product)
    await db_session.flush()
    
    variant = Variant(
        sku="THJ-001",
        price=Decimal("129.99"),
        product_id=product.product_id,
        tenant_id=tenant_id
    )
    db_session.add(variant)
    await db_session.flush()
    
    # Create Stock Location
    location = StockLocation(
        name="Main Warehouse",
        tenant_id=tenant_id,
        is_default=True,
        is_active=True
    )
    db_session.add(location)
    await db_session.flush()
    
    # Add Inventory
    inventory = Inventory(
        variant_id=variant.variant_id,
        stock_location_id=location.stock_location_id,
        quantity_on_hand=10,
        tenant_id=tenant_id
    )
    db_session.add(inventory)
    await db_session.commit()
    
    # 2. Step 1: Create Payment Intent
    intent_data = {
        "items": [{"variant_id": variant.variant_id, "quantity": 2}],
        "email": "customer@example.com"
    }
    response = await client.post("/api/v1/orders/checkout/payment-intent", json=intent_data)
    assert response.status_code == 200
    intent_res = response.json()
    assert "client_secret" in intent_res
    pi_id = intent_res["payment_intent_id"]
    
    # 3. Step 2: Confirm Order
    confirm_data = {
        "payment_intent_id": pi_id,
        "tenant_id": tenant_id,
        "items": [{"variant_id": variant.variant_id, "quantity": 2}],
        "shipping_name": "John Doe",
        "shipping_address1": "123 Main St",
        "shipping_city": "New York",
        "shipping_state": "NY",
        "shipping_postcode": "10001"
    }
    response = await client.post("/api/v1/orders/checkout/confirm", json=confirm_data)
    assert response.status_code == 200
    order_res = response.json()
    assert order_res["payment_status"] == "paid"
    assert len(order_res["items"]) == 1
    
    # 4. Verify Inventory Decrement
    # Re-fetch inventory
    result = await db_session.execute(
        select(Inventory).where(Inventory.inventory_id == inventory.inventory_id)
    )
    updated_inventory = result.scalars().first()
    assert updated_inventory.quantity_on_hand == 8

@pytest.mark.asyncio
async def test_insufficient_stock(client: AsyncClient, db_session: AsyncSession):
    # Setup data with 1 unit
    tenant_id = "t_test_fail"
    product = Product(title="Fail Prod", slug="fail-prod", tenant_id=tenant_id, created_by="u1")
    db_session.add(product)
    await db_session.flush()
    variant = Variant(sku="FAIL-01", price=Decimal("10"), product_id=product.product_id, tenant_id=tenant_id)
    db_session.add(variant)
    await db_session.flush()
    location = StockLocation(name="W1", is_default=True, tenant_id=tenant_id)
    db_session.add(location)
    await db_session.flush()
    inventory = Inventory(variant_id=variant.variant_id, stock_location_id=location.stock_location_id, quantity_on_hand=1, tenant_id=tenant_id)
    db_session.add(inventory)
    await db_session.commit()
    
    confirm_data = {
        "payment_intent_id": "pi_any",
        "tenant_id": tenant_id,
        "items": [{"variant_id": variant.variant_id, "quantity": 5}],
        "shipping_name": "J", "shipping_address1": "A", "shipping_city": "C", "shipping_state": "S", "shipping_postcode": "P"
    }
    response = await client.post("/api/v1/orders/checkout/confirm", json=confirm_data)
    assert response.status_code == 400
    assert "Insufficient stock" in response.json()["detail"]

@pytest.mark.asyncio
async def test_admin_order_list(client: AsyncClient, db_session: AsyncSession, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    tenant_id = "t_abc"
    order = Order(
        order_number="KS-LIST-01",
        tenant_id=tenant_id,
        email="test@test.com",
        subtotal=Decimal("100.00"),
        grand_total=Decimal("100.00")
    )
    db_session.add(order)
    await db_session.commit()
    
    response = await client.get("/api/v1/orders/", headers=headers)
    assert response.status_code == 200
    orders = response.json()
    assert any(o["order_number"] == "KS-LIST-01" for o in orders)

@pytest.mark.asyncio
async def test_fulfil_order(client: AsyncClient, db_session: AsyncSession, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    tenant_id = "t_abc"
    order = Order(
        order_number="KS-FULFIL-01",
        tenant_id=tenant_id,
        email="test@test.com",
        payment_status="paid",
        fulfilment_status="unfulfilled",
        subtotal=10, grand_total=10
    )
    db_session.add(order)
    await db_session.commit()
    
    payload = {"carrier": "FedEx", "tracking_number": "12345"}
    response = await client.patch(f"/api/v1/orders/{order.order_id}/fulfil", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["fulfilment_status"] == "fulfilled"
    assert any(e["event_type"] == "order_fulfilled" for e in data["events"])

@pytest.mark.asyncio
async def test_refund_order(client: AsyncClient, db_session: AsyncSession, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    tenant_id = "t_abc"
    order = Order(
        order_number="KS-REFUND-01",
        tenant_id=tenant_id,
        email="test@test.com",
        payment_status="paid",
        stripe_payment_intent_id="pi_123",
        subtotal=50, grand_total=50
    )
    db_session.add(order)
    await db_session.commit()
    
    # Partial Refund
    payload = {"amount": 20, "reason": "damaged"}
    response = await client.post(f"/api/v1/orders/{order.order_id}/refund", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["payment_status"] == "partially_refunded"
    assert any(e["event_type"] == "order_refunded" for e in data["events"])

@pytest.mark.asyncio
async def test_export_orders_csv(client: AsyncClient, db_session: AsyncSession, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    tenant_id = "t_abc"
    
    # Setup: 2 orders
    db_session.add(Order(order_number="KS-EXP-01", tenant_id=tenant_id, email="e1@t.com", subtotal=10, grand_total=10))
    db_session.add(Order(order_number="KS-EXP-02", tenant_id=tenant_id, email="e2@t.com", subtotal=20, grand_total=20))
    await db_session.commit()
    
    response = await client.get("/api/v1/orders/export", headers=headers)
    assert response.status_code == 200
    assert response.headers["content-type"] == "text/csv; charset=utf-8"
    assert "attachment; filename=orders_export_" in response.headers["content-disposition"]
    
    content = response.text
    assert "Order Number,Date,Email" in content
    assert "KS-EXP-01" in content
    assert "KS-EXP-02" in content
