import pytest
from httpx import AsyncClient
from modules.catalog.models import Product, RedirectRule
from shared.auth import UserClaims
from sqlalchemy.future import select

@pytest.mark.asyncio
async def test_product_slug_change_creates_redirect(client: AsyncClient, db_session, auth_override):
    # 1. Create a product
    auth_override(UserClaims(
        uid="test_owner_uid",
        email="owner@gmail.com",
        tenant_id="t_abc",
        account_type="staff",
        roles=["owner", "catalog:write", "catalog:read"],
        is_owner=True
    ))
    
    product_data = {
        "title": "SEO Product",
        "slug": "old-slug",
        "status": "active",
        "variants": [{"sku": "SEO-1", "price": 100}]
    }
    response = await client.post("/api/v1/products/", json=product_data)
    assert response.status_code == 201
    product_id = response.json()["product_id"]
    
    # 2. Update slug
    update_data = {"slug": "new-slug"}
    response = await client.put(f"/api/v1/products/{product_id}", json=update_data)
    assert response.status_code == 200
    assert response.json()["slug"] == "new-slug"
    
    # 3. Verify redirect rule
    response = await client.get("/api/v1/products/redirects")
    assert response.status_code == 200
    redirects = response.json()
    assert len(redirects) == 1
    assert redirects[0]["source_path"] == "/products/old-slug"
    assert redirects[0]["destination_path"] == "/products/new-slug"
    assert redirects[0]["is_auto_generated"] is True

@pytest.mark.asyncio
async def test_redirect_chain_flattening(client: AsyncClient, db_session, auth_override):
    auth_override(UserClaims(
        uid="test_owner_uid",
        email="owner@gmail.com",
        tenant_id="t_abc",
        account_type="staff",
        roles=["owner", "catalog:write", "catalog:read"],
        is_owner=True
    ))
    
    # 1. Create product with slug A
    product_data = {
        "title": "Chain Product",
        "slug": "slug-a",
        "status": "active",
        "variants": [{"sku": "CHAIN-1", "price": 100}]
    }
    resp = await client.post("/api/v1/products/", json=product_data)
    pid = resp.json()["product_id"]
    
    # 2. Update A -> B
    await client.put(f"/api/v1/products/{pid}", json={"slug": "slug-b"})
    
    # 3. Update B -> C
    await client.put(f"/api/v1/products/{pid}", json={"slug": "slug-c"})
    
    # 4. Verify redirects
    response = await client.get("/api/v1/products/redirects")
    redirects = response.json()
    
    # Should have two rules:
    # A -> C (flattened)
    # B -> C
    
    assert len(redirects) == 2
    paths = {r["source_path"]: r["destination_path"] for r in redirects}
    assert paths["/products/slug-a"] == "/products/slug-c"
    assert paths["/products/slug-b"] == "/products/slug-c"
