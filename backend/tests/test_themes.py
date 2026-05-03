import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_themes_lifecycle(client: AsyncClient, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. List Themes (Seeds modern-dark)
    response = await client.get("/api/v1/themes")
    assert response.status_code == 200
    assert any(t["theme_id"] == "modern-dark" for t in response.json())
    
    # 2. Select Theme
    response = await client.post("/api/v1/themes/select", headers=headers, json={"theme_id": "modern-dark"})
    if response.status_code != 200:
        print(f"DEBUG: {response.status_code} - {response.text}")
    assert response.status_code == 200
    assert response.json()["is_active"] == True
    
    # 3. Get Active Config
    response = await client.get("/api/v1/themes/active", headers=headers)
    assert response.status_code == 200
    assert response.json()["theme_id"] == "modern-dark"
    
    # 4. Update Draft Config
    new_tokens = {"primary": "#FFFFFF"}
    response = await client.patch("/api/v1/themes/config", headers=headers, json={"tokens": new_tokens})
    if response.status_code != 200:
        print(f"DEBUG STEP 4: {response.status_code} - {response.text}")
    assert response.status_code == 200
    assert response.json()["is_active"] == True
    
    # 5. Publish
    response = await client.post("/api/v1/themes/publish", headers=headers)
    if response.status_code != 200:
        print(f"DEBUG STEP 5: {response.status_code} - {response.text}")
    assert response.status_code == 200
    assert response.json()["live_tokens"]["primary"] == "#FFFFFF"
