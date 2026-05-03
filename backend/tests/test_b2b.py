import pytest
from httpx import AsyncClient
from decimal import Decimal
from shared.auth import UserClaims
from datetime import datetime, timedelta

@pytest.mark.asyncio
async def test_b2b_unauthorized(client: AsyncClient):
    """Verify that accessing B2B endpoints without a token returns 403."""
    response = await client.get("/api/v1/b2b/buyers")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_invite_buyer_success(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that an admin can invite a B2B buyer."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "company_name": "Enigma Tek",
        "contact_first_name": "John",
        "contact_last_name": "Doe",
        "contact_email": "john@enigma.tek",
        "contact_phone": "+123456789",
        "credit_limit": 5000.00,
        "net_terms_days": 30
    }
    
    response = await client.post("/api/v1/b2b/buyers", json=payload, headers=headers)
    
    assert response.status_code == 201
    data = response.json()
    assert data["company_name"] == "Enigma Tek"
    assert data["account_status"] == "invited"
    assert data["tenant_id"] == "t_abc"

@pytest.mark.asyncio
async def test_invite_duplicate_buyer_fails(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that inviting a duplicate email fails with 409."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "company_name": "Enigma Tek",
        "contact_first_name": "John",
        "contact_last_name": "Doe",
        "contact_email": "john@enigma.tek"
    }
    
    # First invite
    await client.post("/api/v1/b2b/buyers", json=payload, headers=headers)
    
    # Second invite with same email
    response = await client.post("/api/v1/b2b/buyers", json=payload, headers=headers)
    assert response.status_code == 409

@pytest.mark.asyncio
async def test_list_buyers_tenant_isolation(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify tenant isolation for B2B buyers."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Invite buyer for Tenant A
    await client.post("/api/v1/b2b/buyers", json={
        "company_name": "Tenant A Buyer",
        "contact_first_name": "A",
        "contact_last_name": "User",
        "contact_email": "a@tenant.com"
    }, headers=headers)
    
    # 2. List buyers as Tenant A
    resp_a = await client.get("/api/v1/b2b/buyers", headers=headers)
    assert len(resp_a.json()) == 1
    
    # 3. Switch to Tenant B
    auth_override(UserClaims(
        uid="user_b",
        email="userb@g.com",
        tenant_id="t_xyz",
        roles=["owner"],
        is_owner=True
    ))
    
    # 4. List buyers as Tenant B - should be empty
    resp_b = await client.get("/api/v1/b2b/buyers", headers=headers)
    assert len(resp_b.json()) == 0

@pytest.mark.asyncio
async def test_create_price_list_success(client: AsyncClient, mock_firebase_user, db_session):
    """Verify price list creation."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "name": "Wholesale Gold",
        "description": "Premium wholesale tier",
        "currency_code": "USD",
        "is_default": True
    }
    
    response = await client.post("/api/v1/b2b/price-lists", json=payload, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Wholesale Gold"
    assert data["tenant_id"] == "t_abc"

@pytest.mark.asyncio
async def test_approval_workflow_upsert(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that approval workflow can be retrieved and updated (upsert)."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Get default workflow (should be auto-created)
    resp_get = await client.get("/api/v1/b2b/approval-workflow", headers=headers)
    assert resp_get.status_code == 200
    assert resp_get.json()["is_enabled"] is False
    
    # 2. Update workflow
    payload = {
        "is_enabled": True,
        "auto_approve_under": 1000.00,
        "auto_approve_within_credit_limit": True,
        "approver_roles": ["owner", "admin"],
        "escalation_hours": 24
    }
    resp_put = await client.put("/api/v1/b2b/approval-workflow", json=payload, headers=headers)
    assert resp_put.status_code == 200
    assert resp_put.json()["is_enabled"] is True
    assert Decimal(str(resp_put.json()["auto_approve_under"])) == Decimal("1000.00")

@pytest.mark.asyncio
async def test_place_b2b_order_threshold(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify B2B portal order placement and threshold-based approval."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Setup: Create Product & Variant
    from modules.catalog.models import Product, Variant
    product = Product(product_id="p1", tenant_id="t_abc", title="Bulk Coffee", slug="coffee", created_by="admin")
    variant = Variant(variant_id="v1", product_id="p1", tenant_id="t_abc", sku="COF-BAG", price=Decimal("50.00"))
    db_session.add(product)
    db_session.add(variant)
    
    # 2. Setup: Create B2B Account
    from modules.b2b.models import B2BAccount, ApprovalWorkflow
    buyer_account = B2BAccount(
        b2b_account_id="b1",
        tenant_id="t_abc",
        company_name="Cafe Central",
        contact_first_name="Alice",
        contact_last_name="Smith",
        contact_email="alice@cafe.com",
        firebase_uid="buyer_uid",
        account_status="active",
        credit_limit=Decimal("1000.00")
    )
    db_session.add(buyer_account)
    
    # 3. Setup: Enable Approval Workflow (Threshold: $200)
    workflow = ApprovalWorkflow(tenant_id="t_abc", is_enabled=True, auto_approve_under=Decimal("200.00"))
    db_session.add(workflow)
    await db_session.commit()
    
    # 4. Auth as Buyer
    auth_override(UserClaims(
        uid="buyer_uid",
        email="alice@cafe.com",
        tenant_id="t_abc",
        account_type="buyer",
        roles=["buyer"]
    ))
    
    # 5. Place order below threshold ($50 * 2 = $100 < $200) -> auto_approved
    payload_small = {
        "items": [{"variant_id": "v1", "quantity": 2}],
        "shipping_name": "Alice Smith",
        "shipping_address1": "123 Cafe Lane",
        "shipping_city": "Brewtown",
        "shipping_state": "BT",
        "shipping_postcode": "12345",
        "shipping_country": "US"
    }
    resp_small = await client.post("/api/v1/b2b/portal/orders", json=payload_small, headers=headers)
    assert resp_small.status_code == 200
    assert resp_small.json()["status"] == "auto_approved"
    
    # 6. Place order above threshold ($50 * 5 = $250 > $200) -> pending
    payload_large = {
        "items": [{"variant_id": "v1", "quantity": 5}],
        "shipping_name": "Alice Smith",
        "shipping_address1": "123 Cafe Lane",
        "shipping_city": "Brewtown",
        "shipping_state": "BT",
        "shipping_postcode": "12345",
        "shipping_country": "US"
    }
    resp_large = await client.post("/api/v1/b2b/portal/orders", json=payload_large, headers=headers)
    assert resp_large.status_code == 200
    assert resp_large.json()["status"] == "pending"

@pytest.mark.asyncio
async def test_get_b2b_catalog_overrides(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify B2B portal catalog returns custom pricing."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Setup: Create Product & Variant
    from modules.catalog.models import Product, Variant
    product = Product(product_id="p2", tenant_id="t_abc", title="Bulk Tea", slug="tea", status="active", created_by="admin")
    variant = Variant(variant_id="v2", product_id="p2", tenant_id="t_abc", sku="TEA-BAG", price=Decimal("20.00"))
    db_session.add(product)
    db_session.add(variant)
    
    # 2. Setup: Create Price List with 10% discount
    from modules.b2b.models import B2BAccount, PriceList, PriceListItem
    pl = PriceList(price_list_id="pl1", tenant_id="t_abc", name="Tea Discount", currency_code="USD", created_by="admin")
    pli = PriceListItem(
        price_list_id="pl1", 
        variant_id="v2", 
        override_type="percentage", 
        override_discount_pct=10.0,
        created_by="admin"
    )
    db_session.add(pl)
    db_session.add(pli)
    
    # 3. Setup: Create B2B Account linked to Price List
    buyer = B2BAccount(
        b2b_account_id="b2",
        tenant_id="t_abc",
        company_name="Tea House",
        contact_first_name="Bob",
        contact_last_name="Tea",
        contact_email="bob@tea.com",
        firebase_uid="buyer_bob",
        account_status="active",
        price_list_id="pl1"
    )
    db_session.add(buyer)
    await db_session.commit()
    
    # 4. Auth as Buyer Bob
    auth_override(UserClaims(
        uid="buyer_bob",
        email="bob@tea.com",
        tenant_id="t_abc",
        account_type="buyer",
        roles=["buyer"]
    ))
    
    # 5. Fetch Catalog
    response = await client.get("/api/v1/b2b/portal/catalog", headers=headers)
    assert response.status_code == 200
    data = response.json()
    
    # Find the tea product
    tea_prod = next(p for p in data if p["product_id"] == "p2")
    tea_variant = tea_prod["variants"][0]
    
    # Price should be $20 * 0.9 = $18.00
    assert Decimal(str(tea_variant["price"])) == Decimal("18.00")

@pytest.mark.asyncio
async def test_b2b_invoice_generation(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify that an invoice is generated upon B2B order approval."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Setup: Buyer with Net-45 terms
    from modules.b2b.models import B2BAccount, ApprovalRequest, B2BInvoice
    from modules.orders.models import Order
    buyer = B2BAccount(
        b2b_account_id="b3",
        tenant_id="t_abc",
        company_name="Invoiced Co",
        contact_first_name="Ian",
        contact_last_name="Voice",
        contact_email="ian@voice.com",
        account_status="active",
        net_terms_days=45
    )
    db_session.add(buyer)
    
    # 2. Setup: Pending Approval Request
    order = Order(
        order_id="o3", 
        order_number="B2B-INV-TEST", 
        tenant_id="t_abc", 
        email="ian@voice.com",
        subtotal=Decimal("500.00"),
        grand_total=Decimal("500.00"),
        b2b_approval_status="pending"
    )
    db_session.add(order)
    
    req = ApprovalRequest(
        approval_request_id="req3",
        tenant_id="t_abc",
        order_id="o3",
        b2b_account_id="b3",
        order_grand_total=Decimal("500.00"),
        currency_code="USD",
        status="pending"
    )
    db_session.add(req)
    await db_session.commit()
    
    # 3. Approve the order as Admin
    auth_override(UserClaims(uid="admin_uid", email="admin@g.com", tenant_id="t_abc", roles=["admin", "b2b:approve"]))
    
    resp_approve = await client.patch("/api/v1/b2b/orders/req3/approve", headers=headers)
    assert resp_approve.status_code == 200
    
    # 4. Verify B2BInvoice creation
    from sqlalchemy import select
    inv_res = await db_session.execute(select(B2BInvoice).where(B2BInvoice.order_id == "o3"))
    invoice = inv_res.scalar_one_or_none()
    
    assert invoice is not None
    assert invoice.invoice_amount == Decimal("500.00")
    assert invoice.payment_status == "open"
    
    # Due date should be ~45 days from now
    expected_due = datetime.utcnow() + timedelta(days=45)
    assert abs((invoice.due_date - expected_due).total_seconds()) < 60 # Within a minute
