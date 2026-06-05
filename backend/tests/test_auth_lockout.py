import pytest
from httpx import AsyncClient
from datetime import datetime, timedelta, timezone, date
from sqlalchemy import select
from main import app
from shared.db import get_db
from shared.auth import verify_app_check
from modules.auth.models import StaffSecurityState, StaffUser, StaffRoleAssignment

# Bypass App Check for lockout tests by mocking dependency
async def bypass_app_check():
    return

@pytest.fixture(autouse=True)
def setup_dependencies(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    app.dependency_overrides[verify_app_check] = bypass_app_check
    yield
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_failed_login_alert_cool_off(client: AsyncClient, db_session):
    """Verify that a failed login starts a cool-off and further logins fail during it."""
    for r in app.routes:
        print(f"ROUTE: {r.path}")
    email = "testlockout@gmail.com"
    
    # First failure
    response = await client.post(
        "/api/v1/auth/failed-login-alert",
        json={"email": email}
    )
    assert response.status_code == 200
    assert response.json()["is_blocked"] is False
    
    # Second failure immediately should fail with 403 due to cool-off
    response2 = await client.post(
        "/api/v1/auth/failed-login-alert",
        json={"email": email}
    )
    assert response2.status_code == 403
    assert "cool-off active" in response2.json()["detail"].lower()

@pytest.mark.asyncio
async def test_failed_login_alert_lockout_3_strikes(client: AsyncClient, db_session):
    """Verify that 3 failed login attempts (with cool-off bypassed/cleared) triggers a lockout."""
    email = "lockout3@gmail.com"
    
    # Strike 1
    response = await client.post("/api/v1/auth/failed-login-alert", json={"email": email})
    assert response.status_code == 200
    
    # Clear cool-off manually in DB to allow next attempt
    result = await db_session.execute(select(StaffSecurityState).where(StaffSecurityState.gmail == email))
    sec_state = result.scalar_one()
    sec_state.cool_off_until = None
    await db_session.commit()
    
    # Strike 2
    response = await client.post("/api/v1/auth/failed-login-alert", json={"email": email})
    assert response.status_code == 200
    
    # Clear cool-off again
    result = await db_session.execute(select(StaffSecurityState).where(StaffSecurityState.gmail == email))
    sec_state = result.scalar_one()
    sec_state.cool_off_until = None
    await db_session.commit()
    
    # Strike 3 (should block the account)
    response = await client.post("/api/v1/auth/failed-login-alert", json={"email": email})
    assert response.status_code == 200
    assert response.json()["is_blocked"] is True
    
    # Check status endpoint
    status_response = await client.get(f"/api/v1/auth/login-status/{email}")
    assert status_response.status_code == 200
    assert status_response.json()["is_blocked"] is True

@pytest.mark.asyncio
async def test_failed_login_alert_lockout_3_distinct_days(client: AsyncClient, db_session):
    """Verify that failures across 3 distinct days blocks the account."""
    email = "lockoutdays@gmail.com"
    
    # Strike Day 1
    response = await client.post("/api/v1/auth/failed-login-alert", json={"email": email})
    assert response.status_code == 200
    
    # Adjust DB: set day to 2 days ago, clear cool-off
    result = await db_session.execute(select(StaffSecurityState).where(StaffSecurityState.gmail == email))
    sec_state = result.scalar_one()
    sec_state.last_failed_day = str(date.today() - timedelta(days=2))
    sec_state.cool_off_until = None
    await db_session.commit()
    
    # Strike Day 2
    response = await client.post("/api/v1/auth/failed-login-alert", json={"email": email})
    assert response.status_code == 200
    
    # Adjust DB: set day to 1 day ago, clear cool-off
    result = await db_session.execute(select(StaffSecurityState).where(StaffSecurityState.gmail == email))
    sec_state = result.scalar_one()
    sec_state.last_failed_day = str(date.today() - timedelta(days=1))
    sec_state.cool_off_until = None
    await db_session.commit()
    
    # Strike Day 3 (blocks account)
    response = await client.post("/api/v1/auth/failed-login-alert", json={"email": email})
    assert response.status_code == 200
    
    # Refresh and assert
    result = await db_session.execute(select(StaffSecurityState).where(StaffSecurityState.gmail == email))
    sec_state = result.scalar_one()
    assert sec_state.failed_days_count == 3
    assert sec_state.is_blocked is True

@pytest.mark.asyncio
async def test_unblock_email_rate_limit_and_verify(client: AsyncClient, db_session):
    """Verify that unblock email requests are capped at 3 per 24h, and verify works."""
    email = "unblocktest@gmail.com"
    
    # Pre-populate blocked security state
    sec_state = StaffSecurityState(
        gmail=email,
        failed_attempts_count=3,
        is_blocked=True
    )
    db_session.add(sec_state)
    await db_session.commit()
    
    # Request unblock 3 times
    for i in range(3):
        response = await client.post("/api/v1/auth/unblock/request", json={"email": email})
        assert response.status_code == 200
        assert response.json()["status"] == "unblock_email_sent"
        
    # Request 4th time should trigger 429
    response4 = await client.post("/api/v1/auth/unblock/request", json={"email": email})
    assert response4.status_code == 429
    assert "maximum unblock requests exceeded" in response4.json()["detail"].lower()
    
    # Verify unblocking with the token
    await db_session.refresh(sec_state)
    token = sec_state.unblock_token
    assert token is not None
    
    verify_response = await client.post("/api/v1/auth/unblock/verify", json={"token": token})
    assert verify_response.status_code == 200
    assert verify_response.json()["status"] == "account_unblocked"
    
    # Verify DB state is cleared
    await db_session.refresh(sec_state)
    assert sec_state.is_blocked is False
    assert sec_state.failed_attempts_count == 0

@pytest.mark.asyncio
async def test_unblock_token_ttl(client: AsyncClient, db_session):
    """Verify that an expired unblock token fails verification."""
    email = "ttltest@gmail.com"
    
    sec_state = StaffSecurityState(
        gmail=email,
        failed_attempts_count=3,
        is_blocked=True,
        unblock_token="expired-token-123",
        unblock_token_expires_at=datetime.now(timezone.utc) - timedelta(seconds=10) # expired
    )
    db_session.add(sec_state)
    await db_session.commit()
    
    response = await client.post("/api/v1/auth/unblock/verify", json={"token": "expired-token-123"})
    assert response.status_code == 400
    assert "expired" in response.json()["detail"].lower()

@pytest.mark.asyncio
async def test_admin_unblock_staff_tenant_boundary(client: AsyncClient, db_session, auth_override):
    """Verify that an administrator cannot unblock a staff user from another tenant."""
    from shared.auth import UserClaims
    
    # Create Staff User B
    staff_user = StaffUser(
        uid="staff-b-uid",
        email="staff_b@gmail.com",
        display_name="Staff B"
    )
    db_session.add(staff_user)
    
    # Block their security state
    sec_state = StaffSecurityState(
        gmail="staff_b@gmail.com",
        failed_attempts_count=3,
        is_blocked=True
    )
    db_session.add(sec_state)
    
    # Assign Staff User B to Tenant B
    role_b = StaffRoleAssignment(
        staff_user_id="staff-b-uid",
        tenant_id="tenant-b",
        roles=["staff"]
    )
    db_session.add(role_b)
    await db_session.commit()
    
    # Log in as Admin on Tenant A
    admin_claims = UserClaims(
        uid="admin-a-uid",
        email="admin_a@gmail.com",
        tenant_id="tenant-a",
        account_type="staff",
        roles=["admin"],
        is_owner=False
    )
    auth_override(admin_claims)
    
    # Try to unblock Staff B (should return 403 Forbidden)
    response = await client.post("/api/v1/auth/staff/staff-b-uid/unblock")
    assert response.status_code == 403
    assert "unauthorized to unblock this staff user" in response.json()["detail"].lower()
    
    # Verify Staff B is still blocked
    await db_session.refresh(sec_state)
    assert sec_state.is_blocked is True
    
    # Now log in as Admin on Tenant B
    admin_b_claims = UserClaims(
        uid="admin-b-uid",
        email="admin_b@gmail.com",
        tenant_id="tenant-b",
        account_type="staff",
        roles=["admin"],
        is_owner=False
    )
    auth_override(admin_b_claims)
    
    # Try to unblock Staff B (should succeed 200)
    response2 = await client.post("/api/v1/auth/staff/staff-b-uid/unblock")
    assert response2.status_code == 200
    assert response2.json()["status"] == "staff_unblocked"
    
    # Verify Staff B is unblocked
    await db_session.refresh(sec_state)
    assert sec_state.is_blocked is False

