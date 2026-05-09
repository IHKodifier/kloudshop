import pytest
from httpx import AsyncClient
from shared.auth import UserClaims

@pytest.mark.asyncio
async def test_semantic_search_fallback(client: AsyncClient, auth_override):
    # 1. Setup
    auth_override(UserClaims(uid="u1", email="e1@g.com", tenant_id="t_search", roles=["owner"]))
    
    # Create Store
    await client.post("/api/v1/storefront/profile", json={
        "brand_name": "Search Store", "slug": "search-store", "is_published": True
    }, headers={"Authorization": "Bearer tok"})
    
    # Create Products with distinct topics
    await client.post("/api/v1/products/", json={
        "title": "Solar Powered Lamp",
        "slug": "solar-lamp",
        "description": "Eco-friendly lighting for your garden",
        "status": "active",
        "variants": [{"price": 45.0, "sku": "SOL-001"}]
    }, headers={"Authorization": "Bearer tok"})
    
    await client.post("/api/v1/products/", json={
        "title": "Winter Wool Socks",
        "slug": "wool-socks",
        "description": "Keep your feet warm in the snow",
        "status": "active",
        "variants": [{"price": 15.0, "sku": "SOC-001"}]
    }, headers={"Authorization": "Bearer tok"})
    
    # 2. Test Keyword Search (Exact match)
    response = await client.get("/api/v1/storefront/search-store/search?q=Solar")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["title"] == "Solar Powered Lamp"
    
    # 3. Test Consultative Search (Semantic match)
    # Query "garden light" should match "Solar Powered Lamp" via semantic similarity in mock mode
    response = await client.get("/api/v1/storefront/search-store/search?q=garden+light&consultative=true")
    assert response.status_code == 200
    assert len(response.json()) > 0
    # In our mock mode, the similarity is based on word hash overlap, 
    # but "Solar Powered Lamp" mentions "garden" so it should rank high.
    assert any("Solar" in p["title"] for p in response.json())
    assert "search_score" in response.json()[0]

@pytest.mark.asyncio
async def test_search_no_results(client: AsyncClient):
    response = await client.get("/api/v1/storefront/search-store/search?q=xyzzy")
    assert response.status_code == 200
    assert len(response.json()) == 0
