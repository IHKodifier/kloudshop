import pytest
from httpx import AsyncClient
from uuid import uuid4

async def setup_test_store(client: AsyncClient, headers: dict):
    # Create Profile
    profile_data = {
        "brand_name": "Test Store",
        "slug": "test-store",
        "primary_color": "#FF0000",
        "is_published": True
    }
    await client.post(
        "/api/v1/storefront/profile",
        json=profile_data,
        headers=headers
    )

@pytest.mark.asyncio
async def test_storefront_profile_not_found(client: AsyncClient):
    response = await client.get("/api/v1/storefront/nonexistent/profile")
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_create_and_get_brand_profile(client: AsyncClient, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    # 1. Create Profile (Admin)
    profile_data = {
        "brand_name": "Test Store",
        "slug": "test-store",
        "primary_color": "#FF0000"
    }
    response = await client.post(
        "/api/v1/storefront/profile",
        json=profile_data,
        headers=headers
    )
    assert response.status_code == 200
    
    # 2. Update to Published
    await client.patch(
        "/api/v1/storefront/profile",
        json={"is_published": True},
        headers=headers
    )

    # 3. Get Profile (Public)
    response = await client.get("/api/v1/storefront/test-store/profile")
    assert response.status_code == 200
    assert response.json()["brand_name"] == "Test Store"

@pytest.mark.asyncio
async def test_static_page_crud(client: AsyncClient, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    await setup_test_store(client, headers)
    
    # 1. Create Page
    page_data = {
        "title": "About Us",
        "slug": "about",
        "body": {"content": "Welcome to our store"},
        "status": "published"
    }
    response = await client.post(
        "/api/v1/storefront/pages",
        json=page_data,
        headers=headers
    )
    assert response.status_code == 200
    
    # 2. Get Page (Public)
    response = await client.get("/api/v1/storefront/test-store/pages/about")
    assert response.status_code == 200
    assert response.json()["title"] == "About Us"

@pytest.mark.asyncio
async def test_shipping_rates(client: AsyncClient):
    rate_req = {
        "country": "US",
        "items": []
    }
    response = await client.post("/api/v1/storefront/shipping/rates", json=rate_req)
    assert response.status_code == 200
    assert len(response.json()) > 0
    assert response.json()[0]["service_level_id"] == "standard"
    
    # Test Free Shipping Threshold ($100)
    rate_req_expensive = {
        "country": "US",
        "items": [{"price": 120.0, "quantity": 1}]
    }
    response = await client.post("/api/v1/storefront/shipping/rates", json=rate_req_expensive)
    assert response.json()[0]["rate"] == 0.0
    assert "Free" in response.json()[0]["display_name"]

@pytest.mark.asyncio
async def test_storefront_search(client: AsyncClient, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    await setup_test_store(client, headers)
    
    response = await client.get("/api/v1/storefront/test-store/search?q=test")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
