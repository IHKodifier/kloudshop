import pytest
from httpx import AsyncClient
from shared.auth import UserClaims

@pytest.mark.asyncio
async def test_ssr_storefront_home(client: AsyncClient, auth_override):
    # 1. Setup: Create a published brand profile
    auth_override(UserClaims(uid="u1", email="e1@g.com", tenant_id="t_ssr", roles=["owner"]))
    
    profile_data = {
        "brand_name": "SSR Test Store",
        "slug": "ssr-store",
        "primary_color": "#00FF00",
        "is_published": True
    }
    await client.post("/api/v1/storefront/profile", json=profile_data, headers={"Authorization": "Bearer tok"})
    
    # 2. Test SSR Home
    response = await client.get("/ssr-store")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    assert "<title>SSR Test Store</title>" in response.text
    assert "og:title" in response.text
    assert "og:url" in response.text
    assert "Loading storefront..." in response.text

@pytest.mark.asyncio
async def test_ssr_product_page(client: AsyncClient, auth_override):
    # 1. Setup
    auth_override(UserClaims(uid="u1", email="e1@g.com", tenant_id="t_ssr", roles=["owner"]))
    
    # Create Store
    await client.post("/api/v1/storefront/profile", json={
        "brand_name": "SSR Store", "slug": "ssr-store", "is_published": True
    }, headers={"Authorization": "Bearer tok"})
    
    # Create Product
    product_data = {
        "title": "Premium Jacket",
        "slug": "premium-jacket",
        "description": "A very warm jacket",
        "status": "active",
        "variants": [{"price": 99.99, "sku": "JKT-001"}]
    }
    await client.post("/api/v1/products/", json=product_data, headers={"Authorization": "Bearer tok"})
    
    # 2. Test SSR Product Page
    response = await client.get("/ssr-store/products/premium-jacket")
    assert response.status_code == 200
    assert "Premium Jacket" in response.text
    assert "$99.99" in response.text
    assert "og:title" in response.text
    assert "application/ld+json" in response.text
    assert "A very warm jacket" in response.text

@pytest.mark.asyncio
async def test_ssr_404(client: AsyncClient):
    response = await client.get("/nonexistent-store")
    assert response.status_code == 404
