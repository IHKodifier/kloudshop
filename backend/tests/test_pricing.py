import pytest
import pytest_asyncio
from httpx import AsyncClient
from modules.pricing.models import PricingRule
from sqlalchemy import select

@pytest.mark.asyncio
async def test_pricing_rule_crud(client: AsyncClient, mock_firebase_user, db_session):
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create rule
    payload = {
        "name": "Summer Sale 10%",
        "rule_type": "percentage",
        "target_resource": "products",
        "target_ids": ["prod_1", "prod_2"],
        "modifier_value": -10.0,
        "priority": 10
    }
    response = await client.post("/api/v1/pricing/", json=payload, headers=headers)
    assert response.status_code == 201
    rule_id = response.json()["rule_id"]
    
    # 2. List rules
    resp_list = await client.get("/api/v1/pricing/", headers=headers)
    assert resp_list.status_code == 200
    assert len(resp_list.json()) >= 1
    assert resp_list.json()[0]["name"] == "Summer Sale 10%"
    
    # 3. Delete rule
    resp_del = await client.delete(f"/api/v1/pricing/{rule_id}", headers=headers)
    assert resp_del.status_code == 204
    
    # 4. Verify deletion
    result = await db_session.execute(
        select(PricingRule).where(PricingRule.rule_id == rule_id)
    )
    assert result.scalar_one_or_none() is None
