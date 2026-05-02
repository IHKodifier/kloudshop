import pytest
from httpx import AsyncClient
from decimal import Decimal

@pytest.mark.asyncio
async def test_get_products_unauthorized(client: AsyncClient):
    """Verify that accessing /products without a token returns 403."""
    response = await client.get("/api/v1/products/")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_create_product_success(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that an owner can create a product with variants."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "title": "Hiking Jacket",
        "description": "Premium waterproof jacket",
        "status": "active",
        "slug": "hiking-jacket",
        "variants": [
            {
                "sku": "HJ-BL-L",
                "price": 129.99,
                "option_1": "Blue",
                "option_2": "Large"
            },
            {
                "sku": "HJ-RD-M",
                "price": 119.99,
                "option_1": "Red",
                "option_2": "Medium"
            }
        ]
    }
    
    response = await client.post("/api/v1/products/", json=payload, headers=headers)
    
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Hiking Jacket"
    assert len(data["variants"]) == 2
    assert data["tenant_id"] == "t_abc"
    assert data["created_by"] == "test_owner_uid"
    assert any(v["sku"] == "HJ-BL-L" for v in data["variants"])

@pytest.mark.asyncio
async def test_list_products_tenant_isolation(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify that a tenant only sees their own products."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create product for Tenant A
    await client.post("/api/v1/products/", json={
        "title": "Tenant A Product",
        "slug": "t-a-p",
        "variants": [{"sku": "SKU-A", "price": 10.0}]
    }, headers=headers)
    
    # 2. List products as Tenant A
    resp_a = await client.get("/api/v1/products/", headers=headers)
    assert len(resp_a.json()) == 1
    assert resp_a.json()[0]["title"] == "Tenant A Product"
    
    # 3. Switch to Tenant B
    from shared.auth import UserClaims
    auth_override(UserClaims(
        uid="user_b",
        email="userb@g.com",
        tenant_id="t_xyz",
        roles=["owner"],
        is_owner=True
    ))
    
    # 4. List products as Tenant B - should be empty
    resp_b = await client.get("/api/v1/products/", headers=headers)
    assert len(resp_b.json()) == 0

@pytest.mark.asyncio
async def test_variant_price_constraint(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that creating a variant with negative price fails with 400."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "title": "Bad Product",
        "slug": "bad-p",
        "variants": [{"sku": "BAD-SKU", "price": -10.0}]
    }
    
    response = await client.post("/api/v1/products/", json=payload, headers=headers)
    assert response.status_code == 422

@pytest.mark.asyncio
async def test_variant_pwyw_no_compare_at(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that PWYW variants cannot have a compare_at_price."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "title": "Donation Product",
        "slug": "donation-p",
        "variants": [{
            "sku": "DON-1",
            "pricing_model": "donation",
            "price": 0.0,
            "compare_at_price": 10.0 # INVALID
        }]
    }
    
    response = await client.post("/api/v1/products/", json=payload, headers=headers)
    assert response.status_code == 400

@pytest.mark.asyncio
async def test_product_prescription_logic(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that prescription_document_required requires requires_prescription=True."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "title": "Medicine",
        "slug": "medicine",
        "requires_prescription": False,
        "prescription_document_required": True, # INVALID
        "variants": [{"sku": "MED-1", "price": 50.0}]
    }
    
    response = await client.post("/api/v1/products/", json=payload, headers=headers)
    assert response.status_code == 400

@pytest.mark.asyncio
async def test_variant_perishable_logic(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that best_before_days requires is_perishable=True."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "title": "Fresh Milk",
        "slug": "milk",
        "variants": [{
            "sku": "MILK-1",
            "price": 3.0,
            "is_perishable": False,
            "best_before_days": 7 # INVALID
        }]
    }
    
    response = await client.post("/api/v1/products/", json=payload, headers=headers)
    assert response.status_code == 400
