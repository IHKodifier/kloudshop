import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_onboarding_lifecycle(client: AsyncClient, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Get Status (Initial)
    response = await client.get("/api/v1/onboarding/status", headers=headers)
    assert response.status_code == 200
    assert response.json()["current_step"] == "signup"
    
    # 2. Signup & Tier
    response = await client.post("/api/v1/onboarding/signup", headers=headers, json={
        "brand_name": "My New Store",
        "owner_email": "owner@example.com",
        "tier": "professional"
    })
    assert response.status_code == 200
    assert response.json()["current_step"] == "region"
    
    # 3. Select Region
    response = await client.post("/api/v1/onboarding/region", headers=headers, json={
        "region": "us-central1"
    })
    assert response.status_code == 200
    assert response.json()["current_step"] == "import"
    
    # 4. Analyze CSV
    response = await client.post("/api/v1/onboarding/import/analyze", headers=headers, json={
        "entity_type": "product",
        "csv_sample": ["Product Name", "SKU", "Price", "Extra Field"]
    })
    assert response.status_code == 200
    mapping = response.json()["suggested_mapping"]
    assert mapping["Product Name"] == "title"
    assert mapping["SKU"] == "sku"
    
    # 5. Get Runbook
    response = await client.get("/api/v1/onboarding/runbook", headers=headers)
    assert response.status_code == 200
    assert len(response.json()["steps"]) > 0
