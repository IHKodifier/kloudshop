import pytest
from httpx import AsyncClient
from decimal import Decimal
from shared.auth import UserClaims
from datetime import datetime

@pytest.mark.asyncio
async def test_pos_unauthorized(client: AsyncClient):
    """Verify that accessing POS endpoints without a token returns 403."""
    response = await client.get("/api/v1/pos/location")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_assign_staff_location(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that an admin can assign a staff member to a location."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create a stock location
    from modules.inventory.models import StockLocation
    location = StockLocation(stock_location_id="loc1", name="London Store", location_type="store", fulfils_pos=True)
    db_session.add(location)
    await db_session.commit()
    
    # 2. Assign staff to location
    payload = {
        "staff_user_id": "staff_uid_1",
        "stock_location_id": "loc1"
    }
    response = await client.post("/api/v1/pos/assign-location", json=payload, headers=headers)
    assert response.status_code == 200
    assert response.json()["staff_user_id"] == "staff_uid_1"
    assert response.json()["stock_location_id"] == "loc1"

@pytest.mark.asyncio
async def test_pos_sale_success(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify successful POS sale processing."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Setup: Location, Variant, Inventory
    from modules.inventory.models import StockLocation, Inventory
    from modules.catalog.models import Product, Variant
    
    loc = StockLocation(stock_location_id="loc2", name="Sydney Store", location_type="store", fulfils_pos=True)
    db_session.add(loc)
    
    prod = Product(product_id="p_pos", tenant_id="t_abc", title="POS Product", slug="pos-prod", created_by="admin")
    db_session.add(prod)
    
    var = Variant(variant_id="v_pos", product_id="p_pos", tenant_id="t_abc", sku="POS-SKU", price=Decimal("100.00"))
    db_session.add(var)
    
    inv = Inventory(variant_id="v_pos", stock_location_id="loc2", quantity_on_hand=10)
    db_session.add(inv)
    
    # 2. Setup: Staff Assignment
    from modules.pos.models import StaffLocationAssignment
    assignment = StaffLocationAssignment(tenant_id="t_abc", staff_user_id="pos_staff_uid", stock_location_id="loc2")
    db_session.add(assignment)
    await db_session.commit()
    
    # 3. Auth as POS Operator
    auth_override(UserClaims(
        uid="pos_staff_uid",
        email="pos@store.com",
        tenant_id="t_abc",
        roles=["pos_operator"]
    ))
    
    # 4. Get My Location
    resp_loc = await client.get("/api/v1/pos/location", headers=headers)
    assert resp_loc.status_code == 200
    assert resp_loc.json()["name"] == "Sydney Store"
    
    # 5. Process Sale (2 units)
    payload = {
        "items": [{"variant_id": "v_pos", "quantity": 2}],
        "payment_method": "cash"
    }
    resp_sale = await client.post("/api/v1/pos/orders", json=payload, headers=headers)
    assert resp_sale.status_code == 200
    assert resp_sale.json()["order_number"].startswith("POS-")
    assert Decimal(str(resp_sale.json()["total"])) == Decimal("200.00")
    
    # 6. Verify Inventory Deduction
    await db_session.refresh(inv)
    assert inv.quantity_on_hand == 8

@pytest.mark.asyncio
async def test_pos_sale_insufficient_stock(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify that POS sale fails if stock is insufficient."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Setup: Location, Variant, Inventory (Stock = 1)
    from modules.inventory.models import StockLocation, Inventory
    from modules.catalog.models import Product, Variant
    from modules.pos.models import StaffLocationAssignment
    
    loc = StockLocation(stock_location_id="loc3", name="Melbourne Store", location_type="store", fulfils_pos=True)
    db_session.add(loc)
    prod = Product(product_id="p_fail", tenant_id="t_abc", title="Fail Product", slug="fail-prod", created_by="admin")
    db_session.add(prod)
    var = Variant(variant_id="v_fail", product_id="p_fail", tenant_id="t_abc", sku="FAIL-SKU", price=Decimal("10.00"))
    db_session.add(var)
    inv = Inventory(variant_id="v_fail", stock_location_id="loc3", quantity_on_hand=1)
    db_session.add(inv)
    assignment = StaffLocationAssignment(tenant_id="t_abc", staff_user_id="fail_staff", stock_location_id="loc3")
    db_session.add(assignment)
    await db_session.commit()
    
    # 2. Auth as POS Operator
    auth_override(UserClaims(uid="fail_staff", email="fail@store.com", tenant_id="t_abc", roles=["pos_operator"]))
    
    # 3. Process Sale (2 units - should fail)
    payload = {
        "items": [{"variant_id": "v_fail", "quantity": 2}],
        "payment_method": "cash"
    }
    response = await client.post("/api/v1/pos/orders", json=payload, headers=headers)
    assert response.status_code == 400
    assert "Insufficient stock" in response.json()["detail"]
    
    # 4. Verify Inventory NOT Deducted
    await db_session.refresh(inv)
    assert inv.quantity_on_hand == 1
