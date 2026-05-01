import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_get_me_unauthorized(client: AsyncClient):
    """Verify that accessing /auth/me without a token returns 403 (FastAPI default for missing Bearer)."""
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_me_success(client: AsyncClient, mock_firebase_user):
    """Verify that accessing /auth/me with a valid token returns user info."""
    headers = {"Authorization": "Bearer valid_token"}
    response = await client.get("/api/v1/auth/me", headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert data["uid"] == "test_owner_uid"
    assert data["tenant_id"] == "t_abc"
    assert "owner" in data["roles"]

@pytest.mark.asyncio
async def test_create_invitation_success(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that an owner can invite a staff member."""
    from main import app
    from shared.db import get_db
    
    # Override get_db to use our test session
    app.dependency_overrides[get_db] = lambda: db_session
    
    headers = {"Authorization": "Bearer valid_token"}
    payload = {
        "email": "staff@gmail.com",
        "roles": ["admin"]
    }
    response = await client.post("/api/v1/auth/invitations", json=payload, headers=headers)
    
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "staff@gmail.com"
    assert "admin" in data["roles"]
    assert data["invited_by"] == "owner@gmail.com"
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_list_invitations(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that an owner can list pending invitations."""
    from main import app
    from shared.db import get_db
    app.dependency_overrides[get_db] = lambda: db_session
    
    headers = {"Authorization": "Bearer valid_token"}
    
    # First create an invitation
    await client.post("/api/v1/auth/invitations", json={"email": "s1@g.com", "roles": ["mgr"]}, headers=headers)
    
    response = await client.get("/api/v1/auth/invitations", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_cancel_invitation(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that an owner can cancel an invitation."""
    from main import app
    from shared.db import get_db
    app.dependency_overrides[get_db] = lambda: db_session
    
    headers = {"Authorization": "Bearer valid_token"}
    resp = await client.post("/api/v1/auth/invitations", json={"email": "c@g.com", "roles": ["r"]}, headers=headers)
    invite_id = resp.json()["id"]
    
    response = await client.delete(f"/api/v1/auth/invitations/{invite_id}", headers=headers)
    assert response.status_code == 204
    
    # Verify it's gone from list
    list_resp = await client.get("/api/v1/auth/invitations", headers=headers)
    assert all(i["id"] != invite_id for i in list_resp.json())
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_update_staff_roles(client: AsyncClient, mock_firebase_user, db_session, mock_firebase_auth):
    """Verify that an owner can update staff member roles."""
    from main import app
    from shared.db import get_db
    app.dependency_overrides[get_db] = lambda: db_session
    
    headers = {"Authorization": "Bearer valid_token"}
    payload = {"roles": ["store_manager"]}
    
    response = await client.patch("/api/v1/auth/staff/target_uid/roles", json=payload, headers=headers)
    assert response.status_code == 200
    
    # Verify Firebase claims were updated
    mock_firebase_auth["set"].assert_called_once()
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_revoke_staff_access(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that an owner can revoke staff access."""
    from main import app
    from shared.db import get_db
    app.dependency_overrides[get_db] = lambda: db_session
    
    headers = {"Authorization": "Bearer valid_token"}
    
    response = await client.delete("/api/v1/auth/staff/target_uid", headers=headers)
    assert response.status_code == 204
    
    app.dependency_overrides.clear()
