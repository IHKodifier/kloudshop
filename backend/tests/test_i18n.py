import pytest
from httpx import AsyncClient
from modules.platform.models import Tenant
from shared.auth import UserClaims

@pytest.mark.asyncio
async def test_i18n_locales_management(client: AsyncClient, db_session, auth_override):
    # Setup tenant
    tenant = Tenant(id="t_i18n", name="I18n Store", supported_locales=["en"])
    db_session.add(tenant)
    await db_session.commit()
    
    # Auth override
    auth_override(UserClaims(uid="u1", email="admin@test.com", tenant_id="t_i18n", roles=["owner"], is_owner=True))
    
    headers = {"X-Tenant-ID": "t_i18n"}
    
    # 1. Get locales
    response = await client.get("/api/v1/i18n/locales", headers=headers)
    assert response.status_code == 200
    assert response.json() == ["en"]
    
    # 2. Update locales
    response = await client.put("/api/v1/i18n/locales", json=["en", "fr", "es"], headers=headers)
    assert response.status_code == 200
    assert "fr" in response.json()
    assert "es" in response.json()
    assert "en" in response.json()
    
    # 3. Verify in DB
    await db_session.refresh(tenant)
    assert "fr" in tenant.supported_locales
