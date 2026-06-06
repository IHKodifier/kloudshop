import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_color_preset_success(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that a merchant can successfully create a color preset."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "name": "Emerald Green",
        "hex_code": "#064e3b"
    }
    
    response = await client.post("/api/v1/products/color-presets", json=payload, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Emerald Green"
    assert data["hex_code"] == "#064e3b"
    assert data["tenant_id"] == "t_abc"
    assert "preset_id" in data

@pytest.mark.asyncio
async def test_create_color_preset_duplicate_name_fails(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that creating a duplicate color preset name under the same tenant fails."""
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "name": "Ocean Blue",
        "hex_code": "#0000ff"
    }
    
    # 1. Create first preset
    resp1 = await client.post("/api/v1/products/color-presets", json=payload, headers=headers)
    assert resp1.status_code == 201
    
    # 2. Try creating duplicate
    resp2 = await client.post("/api/v1/products/color-presets", json=payload, headers=headers)
    assert resp2.status_code == 400
    assert "already exists" in resp2.json()["detail"]

@pytest.mark.asyncio
async def test_create_color_preset_invalid_hex_fails(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that invalid hex code formats fail schema validation."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # Missing '#' prefix
    resp1 = await client.post("/api/v1/products/color-presets", json={
        "name": "Red",
        "hex_code": "ff0000"
    }, headers=headers)
    assert resp1.status_code == 422
    
    # Too short
    resp2 = await client.post("/api/v1/products/color-presets", json={
        "name": "Red",
        "hex_code": "#ff0"
    }, headers=headers)
    assert resp2.status_code == 422
    
    # Invalid characters
    resp3 = await client.post("/api/v1/products/color-presets", json={
        "name": "Red",
        "hex_code": "#ff00gg"
    }, headers=headers)
    assert resp3.status_code == 422

@pytest.mark.asyncio
async def test_list_color_presets_tenant_isolation(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify that preset listing is isolated per tenant."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create preset as Tenant A
    await client.post("/api/v1/products/color-presets", json={
        "name": "Tenant A Red",
        "hex_code": "#ff0000"
    }, headers=headers)
    
    # Verify Tenant A lists it
    resp_a = await client.get("/api/v1/products/color-presets", headers=headers)
    assert resp_a.status_code == 200
    assert len(resp_a.json()) == 1
    assert resp_a.json()[0]["name"] == "Tenant A Red"
    
    # 2. Switch to Tenant B
    from shared.auth import UserClaims
    auth_override(UserClaims(
        uid="user_b",
        email="userb@g.com",
        tenant_id="t_xyz",
        roles=["owner"],
        is_owner=True
    ))
    
    # Verify Tenant B sees default seeded list
    resp_b = await client.get("/api/v1/products/color-presets", headers=headers)
    assert resp_b.status_code == 200
    assert len(resp_b.json()) == 3

@pytest.mark.asyncio
async def test_delete_color_preset_success(client: AsyncClient, mock_firebase_user, db_session):
    """Verify deleting a color preset."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create preset
    resp1 = await client.post("/api/v1/products/color-presets", json={
        "name": "To Delete",
        "hex_code": "#123456"
    }, headers=headers)
    assert resp1.status_code == 201
    preset_id = resp1.json()["preset_id"]
    
    # 2. Delete preset
    resp2 = await client.delete(f"/api/v1/products/color-presets/{preset_id}", headers=headers)
    assert resp2.status_code == 204
    
    # 3. Verify it is gone and we have default seeded presets
    resp3 = await client.get("/api/v1/products/color-presets", headers=headers)
    assert len(resp3.json()) == 3

@pytest.mark.asyncio
async def test_delete_color_preset_not_found(client: AsyncClient, mock_firebase_user, db_session, auth_override):
    """Verify that deleting a non-existent or other tenant's preset fails with 404."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create preset as Tenant A
    resp1 = await client.post("/api/v1/products/color-presets", json={
        "name": "Tenant A Color",
        "hex_code": "#aabbcc"
    }, headers=headers)
    assert resp1.status_code == 201
    preset_id = resp1.json()["preset_id"]
    
    # 2. Switch to Tenant B
    from shared.auth import UserClaims
    auth_override(UserClaims(
        uid="user_b",
        email="userb@g.com",
        tenant_id="t_xyz",
        roles=["owner"],
        is_owner=True
    ))
    
    # Try deleting Tenant A's preset as Tenant B
    resp2 = await client.delete(f"/api/v1/products/color-presets/{preset_id}", headers=headers)
    assert resp2.status_code == 404
