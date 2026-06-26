import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from modules.policies.models import StorePolicy
from modules.navigation.models import StoreNavigationMenu, StoreNavigationItem

@pytest.mark.asyncio
async def test_policy_draft_crud_and_seeding(client: AsyncClient, mock_firebase_user, db_session: AsyncSession):
    headers = {"Authorization": "Bearer valid_token"}

    # 1. Seed template
    seed_payload = {"policy_type": "refund"}
    resp_seed = await client.post("/api/v1/policies/seed-template", json=seed_payload, headers=headers)
    assert resp_seed.status_code == 200
    seed_data = resp_seed.json()
    assert "Refund Policy" in seed_data["seeded_content"]

    # 2. Create policy draft
    create_payload = {
        "policy_type": "refund",
        "draft_content": seed_data["seeded_content"],
        "published_content": None,
        "is_active": False
    }
    resp_create = await client.post("/api/v1/policies", json=create_payload, headers=headers)
    assert resp_create.status_code == 201
    policy_data = resp_create.json()
    policy_id = policy_data["policy_id"]
    assert policy_data["policy_type"] == "refund"
    assert policy_data["is_active"] is False
    assert policy_data["version"] == 1

    # 3. Update draft
    update_payload = {"draft_content": "Updated Refund Policy draft content."}
    resp_update = await client.patch(f"/api/v1/policies/{policy_id}", json=update_payload, headers=headers)
    assert resp_update.status_code == 200
    assert resp_update.json()["draft_content"] == "Updated Refund Policy draft content."

@pytest.mark.asyncio
async def test_policy_publish_validation_and_lifecycle(client: AsyncClient, mock_firebase_user, db_session: AsyncSession):
    headers = {"Authorization": "Bearer valid_token"}

    # 1. Create a draft policy
    policy = StorePolicy(
        tenant_id="t_abc",
        policy_type="privacy",
        draft_content="Draft privacy policy content.",
        version=1,
        is_active=False
    )
    db_session.add(policy)
    await db_session.commit()
    await db_session.refresh(policy)
    policy_id = policy.policy_id

    # 2. Try to publish without active storefront links - should fail with 422
    resp_pub_fail = await client.post(f"/api/v1/policies/{policy_id}/publish", headers=headers)
    assert resp_pub_fail.status_code == 422
    assert "No active storefront links" in resp_pub_fail.json()["detail"]

    # 3. Publish with force=True - should succeed
    resp_pub_force = await client.post(f"/api/v1/policies/{policy_id}/publish?force=true", headers=headers)
    assert resp_pub_force.status_code == 200
    pub_data = resp_pub_force.json()
    assert pub_data["is_active"] is True
    assert pub_data["published_content"] == "Draft privacy policy content."
    assert pub_data["version"] == 2 # Incremented

    # 4. Create another version
    policy2 = StorePolicy(
        tenant_id="t_abc",
        policy_type="privacy",
        draft_content="Newer privacy policy draft.",
        version=1,
        is_active=False
    )
    db_session.add(policy2)
    await db_session.commit()
    await db_session.refresh(policy2)
    policy2_id = policy2.policy_id

    # 5. Publish policy2 with force=True
    resp_pub2 = await client.post(f"/api/v1/policies/{policy2_id}/publish?force=true", headers=headers)
    assert resp_pub2.status_code == 200
    
    # 6. Verify policy2 is active and policy1 is deactivated
    await db_session.refresh(policy)
    await db_session.refresh(policy2)
    
    assert policy.is_active is False
    assert policy.deactivated_at is not None
    assert policy2.is_active is True
    assert policy2.deactivated_at is None
