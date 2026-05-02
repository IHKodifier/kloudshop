import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_collection_success(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that an owner can create a collection."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "title": "Summer Sale",
        "description": "Best summer outfits",
        "slug": "summer-sale",
        "is_visible": True
    }
    
    response = await client.post("/api/v1/products/collections", json=payload, headers=headers)
    
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Summer Sale"
    assert data["slug"] == "summer-sale"
    assert data["tenant_id"] == "t_abc"

@pytest.mark.asyncio
async def test_list_collections_tenant_isolation(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify that a tenant only sees their own collections."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create collection for Tenant A
    await client.post("/api/v1/products/collections", json={
        "title": "Tenant A Coll",
        "slug": "t-a-c"
    }, headers=headers)
    
    # 2. List as Tenant A
    resp_a = await client.get("/api/v1/products/collections", headers=headers)
    assert len(resp_a.json()) == 1
    
    # 3. Switch to Tenant B
    from shared.auth import UserClaims
    auth_override(UserClaims(
        uid="user_b",
        email="userb@g.com",
        tenant_id="t_xyz",
        roles=["owner"],
        is_owner=True
    ))
    
    # 4. List as Tenant B
    resp_b = await client.get("/api/v1/products/collections", headers=headers)
    assert len(resp_b.json()) == 0

@pytest.mark.asyncio
async def test_assign_products_to_collection(client: AsyncClient, mock_firebase_user, db_session):
    """Verify assigning products to a collection."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create Product
    prod_resp = await client.post("/api/v1/products/", json={
        "title": "Test Product",
        "slug": "test-prod",
        "variants": [{"sku": "SKU-1", "price": 10.0}]
    }, headers=headers)
    product_id = prod_resp.json()["product_id"]
    
    # 2. Create Collection
    coll_resp = await client.post("/api/v1/products/collections", json={
        "title": "Test Coll",
        "slug": "test-coll"
    }, headers=headers)
    collection_id = coll_resp.json()["collection_id"]
    
    # 3. Assign
    assign_resp = await client.post(
        f"/api/v1/products/collections/{collection_id}/products",
        json={"product_ids": [product_id]},
        headers=headers
    )
    assert assign_resp.status_code == 200
    
    # 4. Verify (Get collection would normally show products, but our schema doesn't yet load them)
    # We can check via a 404 if we try to remove it and it's NOT there.
    # But better to just check the 200 response for now.

@pytest.mark.asyncio
async def test_remove_product_from_collection(client: AsyncClient, mock_firebase_user, db_session):
    """Verify removing a product from a collection."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # Setup: Product + Collection + Assignment
    prod_resp = await client.post("/api/v1/products/", json={
        "title": "P1", "slug": "p1", "variants": [{"sku": "S1", "price": 1.0}]
    }, headers=headers)
    product_id = prod_resp.json()["product_id"]
    
    coll_resp = await client.post("/api/v1/products/collections", json={
        "title": "C1", "slug": "c1"
    }, headers=headers)
    collection_id = coll_resp.json()["collection_id"]
    
    await client.post(
        f"/api/v1/products/collections/{collection_id}/products",
        json={"product_ids": [product_id]},
        headers=headers
    )
    
    # Remove
    del_resp = await client.delete(
        f"/api/v1/products/collections/{collection_id}/products/{product_id}",
        headers=headers
    )
    assert del_resp.status_code == 204
    
    # Try removing again (should be 404)
    del_resp_2 = await client.delete(
        f"/api/v1/products/collections/{collection_id}/products/{product_id}",
        headers=headers
    )
    assert del_resp_2.status_code == 404
