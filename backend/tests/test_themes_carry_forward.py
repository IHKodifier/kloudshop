import pytest
from httpx import AsyncClient, ASGITransport
from main import app
from shared.auth import validate_token, UserClaims

@pytest.mark.asyncio
async def test_theme_carry_forward(db_session):
    """
    Test that switching themes carries forward matching content slots.
    """
    # Setup auth override
    user = UserClaims(
        uid="test_user",
        email="test@example.com",
        tenant_id="test_tenant",
        account_type="staff",
        roles=["owner"]
    )
    app.dependency_overrides[validate_token] = lambda: user

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. Initialize themes
        await ac.get("/api/v1/themes")
        
        # 2. Select modern-dark
        await ac.post("/api/v1/themes/select", json={"theme_id": "modern-dark"})
        
        # 3. Update slot content in modern-dark
        await ac.patch("/api/v1/themes/config", json={
            "slots": {"hero_heading": "MY CUSTOM TITLE"}
        })
        
        # 4. Switch to minimal-light
        await ac.post("/api/v1/themes/select", json={"theme_id": "minimal-light"})
        
        # 5. Verify minimal-light configuration has the carried-forward slot
        res = await ac.get("/api/v1/themes/active")
        data = res.json()
        assert data["theme_id"] == "minimal-light"
        # minimal-light's default was "Minimalist", but it should now be "MY CUSTOM TITLE"
        assert data["draft_slots"]["hero_heading"] == "MY CUSTOM TITLE"
        # Verify tokens did NOT carry forward (primary should be black #000000 from minimalist)
        assert data["draft_tokens"]["primary"] == "#000000"

    # Cleanup
    app.dependency_overrides.clear()
