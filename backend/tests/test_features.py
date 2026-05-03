import pytest
import pytest_asyncio
from httpx import AsyncClient
from modules.features.models import Feature, TenantFeatureActivation, TenantFeatureConfig, FeatureRequest
from sqlalchemy import select

@pytest_asyncio.fixture(autouse=True)
async def seed_features(db_session):
    features = [
        Feature(
            feature_id="ai_copywriter", 
            name="AI Copywriter", 
            description="Generate marketing copy", 
            has_config=True,
            config_schema={"tone": "string", "audience": "string"}
        ),
        Feature(
            feature_id="dynamic_pricing", 
            name="Dynamic Pricing", 
            description="Automatic price adjustments", 
            has_config=True
        ),
        Feature(
            feature_id="export_engine", 
            name="Export Engine", 
            description="CSV/JSON data portability", 
            has_config=False
        )
    ]
    db_session.add_all(features)
    await db_session.commit()

@pytest.mark.asyncio
async def test_list_features(client: AsyncClient, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    response = await client.get("/api/v1/features/", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 3
    # Verify AI Copywriter is there and inactive by default
    ai_feat = next(f for f in data if f["feature_id"] == "ai_copywriter")
    assert ai_feat["is_active"] is False

@pytest.mark.asyncio
async def test_activate_feature(client: AsyncClient, mock_firebase_user, db_session):
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Activate
    response = await client.post("/api/v1/features/ai_copywriter/activate", headers=headers)
    assert response.status_code == 200
    assert response.json()["status"] == "processing"
    
    # 2. Verify in DB
    result = await db_session.execute(
        select(TenantFeatureActivation).where(TenantFeatureActivation.feature_id == "ai_copywriter")
    )
    activation = result.scalar_one()
    assert activation.is_active is True
    assert activation.tenant_id == "t_abc"

    # 3. Verify in List
    resp_list = await client.get("/api/v1/features/", headers=headers)
    ai_feat = next(f for f in resp_list.json() if f["feature_id"] == "ai_copywriter")
    assert ai_feat["is_active"] is True

@pytest.mark.asyncio
async def test_feature_config(client: AsyncClient, mock_firebase_user, db_session):
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Update config
    payload = {"config": {"tone": "Luxurious", "audience": "High-end buyers"}}
    response = await client.put("/api/v1/features/ai_copywriter/config", json=payload, headers=headers)
    assert response.status_code == 200
    
    # 2. Get config
    resp_get = await client.get("/api/v1/features/ai_copywriter/config", headers=headers)
    assert resp_get.status_code == 200
    data = resp_get.json()
    assert data["tone"] == "Luxurious"
    assert data["audience"] == "High-end buyers"

@pytest.mark.asyncio
async def test_feature_requests_voting(client: AsyncClient, mock_firebase_user, db_session):
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create request
    req_payload = {"title": "Apple Pay Integration", "description": "Need Apple Pay for mobile users"}
    resp_create = await client.post("/api/v1/features/requests", json=req_payload, headers=headers)
    assert resp_create.status_code == 200
    request_id = resp_create.json()["request_id"]
    
    # 2. Vote
    resp_vote = await client.post(f"/api/v1/features/requests/{request_id}/vote", headers=headers)
    assert resp_vote.status_code == 200
    assert resp_vote.json()["votes_count"] == 1
    assert resp_vote.json()["has_voted"] is True
    
    # 3. Double vote should fail
    resp_vote_2 = await client.post(f"/api/v1/features/requests/{request_id}/vote", headers=headers)
    assert resp_vote_2.status_code == 400
    
    # 4. List requests
    resp_list = await client.get("/api/v1/features/requests", headers=headers)
    assert len(resp_list.json()) == 1
    assert resp_list.json()[0]["votes_count"] == 1
    assert resp_list.json()[0]["has_voted"] is True
