import pytest
from httpx import AsyncClient
from datetime import datetime, timedelta, timezone
from modules.auth.models import StaffRoleAssignment, B2BInvitation
from sqlalchemy import select

@pytest.mark.asyncio
async def test_ownership_transfer_success(client: AsyncClient, mock_firebase_user, db_session, mock_firebase_auth):
    """Verify that an owner can transfer ownership to another staff member."""
    from main import app
    from shared.db import get_db
    app.dependency_overrides[get_db] = lambda: db_session

    # 1. Setup: Add target staff member to DB
    target_uid = "target_uid"
    target_assignment = StaffRoleAssignment(
        staff_user_id=target_uid,
        tenant_id="t_abc",
        roles=["admin"],
        is_owner=False
    )
    db_session.add(target_assignment)
    
    # Also ensure current owner is in DB
    owner_assignment = StaffRoleAssignment(
        staff_user_id="test_owner_uid",
        tenant_id="t_abc",
        roles=["owner"],
        is_owner=True
    )
    db_session.add(owner_assignment)
    await db_session.commit()

    # 2. Call endpoint
    headers = {"Authorization": "Bearer valid_token"}
    payload = {"new_owner_uid": target_uid}
    response = await client.post("/api/v1/auth/ownership/transfer", json=payload, headers=headers)
    
    assert response.status_code == 200
    assert response.json()["status"] == "success"

    # 3. Verify DB changes
    await db_session.refresh(target_assignment)
    await db_session.refresh(owner_assignment)
    assert target_assignment.is_owner is True
    assert owner_assignment.is_owner is False
    assert "admin" in owner_assignment.roles

    # 4. Verify Firebase sync
    assert mock_firebase_auth["set"].call_count == 2
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_ownership_transfer_forbidden(client: AsyncClient, db_session):
    """Verify that a non-owner cannot transfer ownership."""
    # We'll use a mock user that is NOT an owner
    # The validate_token dependency will return this user
    from shared.auth import UserClaims
    from shared.auth import validate_token
    from main import app

    async def mock_validate_token():
        return UserClaims(uid="staff_uid", email="s@g.com", tenant_id="t_abc", is_owner=False, roles=["admin"])

    app.dependency_overrides[validate_token] = mock_validate_token
    
    headers = {"Authorization": "Bearer some_token"}
    response = await client.post("/api/v1/auth/ownership/transfer", json={"new_owner_uid": "somebody"})
    
    assert response.status_code == 403
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_b2b_buyer_registration_success(client: AsyncClient, db_session, mock_firebase_auth):
    """Verify that a B2B buyer can register with a valid token."""
    from main import app
    from shared.db import get_db
    app.dependency_overrides[get_db] = lambda: db_session

    # 1. Setup: Create invitation
    token = "valid_b2b_token"
    invitation = B2BInvitation(
        email="buyer@corp.com",
        tenant_id="t_abc",
        buyer_account_id="corp_xyz",
        token=token,
        expires_at=datetime.now(timezone.utc) + timedelta(days=7)
    )
    db_session.add(invitation)
    await db_session.commit()

    # 2. Call endpoint
    payload = {
        "invite_token": token,
        "password": "securepassword123",
        "display_name": "John Buyer"
    }
    response = await client.post("/api/v1/auth/b2b-buyers/register", json=payload)
    
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "registered"
    assert data["email"] == "buyer@corp.com"

    # 3. Verify Firebase sync
    mock_firebase_auth["set"].assert_called_once()
    claims = mock_firebase_auth["set"].call_args[0][1]
    assert claims["account_type"] == "buyer"
    assert claims["tenant_id"] == "t_abc"

    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_consumer_registration_success(client: AsyncClient, db_session, mock_firebase_auth):
    """Verify that a consumer can register."""
    from main import app
    from shared.db import get_db
    app.dependency_overrides[get_db] = lambda: db_session

    payload = {
        "email": "consumer@gmail.com",
        "password": "password123",
        "tenant_id": "t_abc",
        "display_name": "Jane Doe"
    }
    response = await client.post("/api/v1/auth/consumers/register", json=payload)
    
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "registered"

    # Verify Firebase sync
    mock_firebase_auth["set"].assert_called_once()
    claims = mock_firebase_auth["set"].call_args[0][1]
    assert claims["account_type"] == "consumer"
    assert "consumer" in claims["roles"]

    app.dependency_overrides.clear()
