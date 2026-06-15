import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_theme_cloning_and_ab_management(client: AsyncClient, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}

    # 1. Seed themes by listing them
    response = await client.get("/api/v1/themes")
    assert response.status_code == 200

    # 2. Select active theme configuration (seeds default active layout config)
    response = await client.post(
        "/api/v1/themes/select", 
        headers=headers, 
        json={"theme_id": "modern-dark"}
    )
    assert response.status_code == 200
    active_config = response.json()
    assert active_config["is_active"] is True
    assert active_config["name"] == "Active Modern Dark"
    active_config_id = active_config["config_id"]

    # 3. Clone the active layout
    clone_payload = {"name": "Header Option A"}
    response = await client.post(
        "/api/v1/themes/clone",
        headers=headers,
        json=clone_payload
    )
    assert response.status_code == 200
    cloned_config = response.json()
    assert cloned_config["name"] == "Header Option A"
    assert cloned_config["is_active"] is False
    assert cloned_config["theme_id"] == "modern-dark"
    cloned_config_id = cloned_config["config_id"]

    # 4. List all layout configurations for the tenant
    response = await client.get("/api/v1/themes/configurations", headers=headers)
    assert response.status_code == 200
    configs = response.json()
    assert len(configs) >= 2
    assert any(c["config_id"] == active_config_id for c in configs)
    assert any(c["config_id"] == cloned_config_id for c in configs)

    # 5. Get configuration by ID (Public, unauthenticated)
    response = await client.get(f"/api/v1/themes/config/{cloned_config_id}")
    assert response.status_code == 200
    config_by_id = response.json()
    assert config_by_id["config_id"] == cloned_config_id
    assert config_by_id["name"] == "Header Option A"

    # 6. Rename configuration (PATCH by ID)
    rename_payload = {"name": "Header Option B"}
    response = await client.patch(
        f"/api/v1/themes/config/{cloned_config_id}",
        headers=headers,
        json=rename_payload
    )
    assert response.status_code == 200
    renamed_config = response.json()
    assert renamed_config["name"] == "Header Option B"

    # 7. Make layout active (Publish by ID)
    response = await client.post(
        f"/api/v1/themes/publish/{cloned_config_id}",
        headers=headers
    )
    assert response.status_code == 200
    published_config = response.json()
    assert published_config["is_active"] is True

    # 8. Check that the previous active layout is now inactive
    response = await client.get("/api/v1/themes/configurations", headers=headers)
    assert response.status_code == 200
    updated_configs = response.json()
    prev_active = next(c for c in updated_configs if c["config_id"] == active_config_id)
    assert prev_active["is_active"] is False

    # 9. Delete the now inactive configuration
    response = await client.delete(
        f"/api/v1/themes/config/{active_config_id}",
        headers=headers
    )
    assert response.status_code == 200
    assert response.json()["message"] == "Theme configuration deleted successfully"

    # 10. Check that the configuration is deleted from configurations list
    response = await client.get("/api/v1/themes/configurations", headers=headers)
    assert response.status_code == 200
    final_configs = response.json()
    assert not any(c["config_id"] == active_config_id for c in final_configs)

    # 11. Check that deleting an active configuration is prevented
    response = await client.delete(
        f"/api/v1/themes/config/{cloned_config_id}",
        headers=headers
    )
    assert response.status_code == 400
    assert "Cannot delete active theme configuration" in response.json()["detail"]
