import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime

from modules.inventory.models import StockLocation, Inventory, Supplier, PurchaseOrder, PurchaseOrderLine, StockTransfer
from modules.catalog.models import Product, Variant

@pytest.mark.asyncio
async def test_supplier_crud(client: AsyncClient, db_session: AsyncSession, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    # 1. Create Supplier
    resp = await client.post("/api/v1/inventory/suppliers", headers=headers, json={
        "name": "Global Supplies Inc",
        "contact_email": "sales@globalsupplies.com",
        "currency": "USD"
    })
    assert resp.status_code == 200
    supplier_id = resp.json()["supplier_id"]
    
    # 2. List Suppliers
    resp = await client.get("/api/v1/inventory/suppliers", headers=headers)
    assert any(s["supplier_id"] == supplier_id for s in resp.json())
    
    # 3. Update Supplier
    resp = await client.patch(f"/api/v1/inventory/suppliers/{supplier_id}", headers=headers, json={
        "contact_name": "John Doe"
    })
    assert resp.json()["contact_name"] == "John Doe"

@pytest.mark.asyncio
async def test_purchase_order_lifecycle(client: AsyncClient, db_session: AsyncSession, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    tenant_id = "t_abc"
    # Setup: Location, Supplier, Product
    loc = StockLocation(name="Main Warehouse", location_type="warehouse", tenant_id="t_abc")
    db_session.add(loc)
    sup = Supplier(name="Tech Distro", tenant_id="test-tenant", created_by="user-1")
    db_session.add(sup)
    prod = Product(title="Laptop", tenant_id="test-tenant", slug="laptop", created_by="user-1")
    db_session.add(prod)
    await db_session.flush()
    var = Variant(product_id=prod.product_id, sku="LAP-001", price=1000, tenant_id="test-tenant")
    db_session.add(var)
    await db_session.commit()
    
    # 1. Create PO Draft
    resp = await client.post("/api/v1/inventory/purchase-orders", headers=headers, json={
        "supplier_id": sup.supplier_id,
        "receiving_location_id": loc.stock_location_id,
        "lines": [{"variant_id": var.variant_id, "quantity_ordered": 10, "unit_cost": 800}]
    })
    assert resp.status_code == 200
    po_id = resp.json()["po_id"]
    po_line_id = resp.json()["lines"][0]["po_line_id"]
    
    # 2. Send PO
    resp = await client.patch(f"/api/v1/inventory/purchase-orders/{po_id}/send", headers=headers)
    assert resp.json()["status"] == "sent"
    
    # 3. Receive PO (Partial)
    resp = await client.post(f"/api/v1/inventory/purchase-orders/{po_id}/receive", headers=headers, json={
        "lines": [{"po_line_id": po_line_id, "quantity_received": 4}]
    })
    assert resp.json()["status"] == "partial"
    
    # Verify Inventory
    res = await db_session.execute(select(Inventory).where(Inventory.variant_id == var.variant_id))
    inv = res.scalar_one()
    assert inv.quantity_on_hand == 4
    
    # 4. Receive PO (Remainder)
    resp = await client.post(f"/api/v1/inventory/purchase-orders/{po_id}/receive", headers=headers, json={
        "lines": [{"po_line_id": po_line_id, "quantity_received": 6}]
    })
    assert resp.json()["status"] == "received"
    
    # Verify Inventory Final
    await db_session.refresh(inv)
    assert inv.quantity_on_hand == 10

@pytest.mark.asyncio
async def test_stock_transfer(client: AsyncClient, db_session: AsyncSession, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    tenant_id = "t_abc"
    # Setup: 2 Locations, 1 Variant with stock
    loc1 = StockLocation(name="Store A", location_type="store", tenant_id="t_abc")
    loc2 = StockLocation(name="Store B", location_type="store", tenant_id="t_abc")
    db_session.add_all([loc1, loc2])
    prod = Product(title="Mouse", tenant_id="test-tenant", slug="mouse", created_by="user-1")
    db_session.add(prod)
    await db_session.flush()
    var = Variant(product_id=prod.product_id, sku="MOU-001", price=20, tenant_id="test-tenant")
    db_session.add(var)
    await db_session.flush()
    inv1 = Inventory(variant_id=var.variant_id, stock_location_id=loc1.stock_location_id, quantity_on_hand=50, tenant_id="t_abc")
    db_session.add(inv1)
    await db_session.commit()
    
    # 1. Initiate Transfer
    resp = await client.post("/api/v1/inventory/transfers", headers=headers, json={
        "source_location_id": loc1.stock_location_id,
        "destination_location_id": loc2.stock_location_id,
        "variant_id": var.variant_id,
        "quantity_transferred": 20
    })
    assert resp.status_code == 200
    transfer_id = resp.json()["transfer_id"]
    
    # Verify source decrement
    await db_session.refresh(inv1)
    assert inv1.quantity_on_hand == 30
    
    # 2. Receive Transfer
    resp = await client.post(f"/api/v1/inventory/transfers/{transfer_id}/receive", headers=headers)
    assert resp.status_code == 200
    
    # Verify destination increment
    res = await db_session.execute(
        select(Inventory).where(Inventory.variant_id == var.variant_id, Inventory.stock_location_id == loc2.stock_location_id)
    )
    inv2 = res.scalar_one()
    assert inv2.quantity_on_hand == 20
