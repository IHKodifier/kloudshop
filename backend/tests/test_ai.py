import pytest
import pytest_asyncio
from httpx import AsyncClient
from modules.ai.models import BrandVoiceProfile, AICopywriterLog
from sqlalchemy import select

@pytest.mark.asyncio
async def test_brand_voice_crud(client: AsyncClient, mock_firebase_user):
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Get default (empty)
    resp_get = await client.get("/api/v1/ai/brand-voice", headers=headers)
    assert resp_get.status_code == 200
    assert resp_get.json()["tone"] == "Professional"
    
    # 2. Update
    payload = {
        "tone": "Playful",
        "target_audience": "Tech-savvy teens",
        "brand_adjectives": ["cool", "vibrant"],
        "writing_style_rules": "Use emojis.",
        "negative_brands": ["Old School Inc"]
    }
    resp_put = await client.put("/api/v1/ai/brand-voice", json=payload, headers=headers)
    assert resp_put.status_code == 200
    assert resp_put.json()["tone"] == "Playful"
    assert resp_put.json()["brand_adjectives"] == ["cool", "vibrant"]

@pytest.mark.asyncio
async def test_generate_product_title(client: AsyncClient, mock_firebase_user, db_session):
    headers = {"Authorization": "Bearer valid_token"}
    
    payload = {
        "brand_profile_id": "default",
        "context_data": {"title": "Solar Powered Powerbank", "category": "Electronics"}
    }
    
    response = await client.post("/api/v1/ai/copy/product-title", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "log_id" in data
    assert len(data["variants"]) == 3
    assert data["variants"][0]["label"] == "Benefit-led"
    assert "Solar Powered Powerbank" in data["variants"][0]["content"]

@pytest.mark.asyncio
async def test_accept_variant(client: AsyncClient, mock_firebase_user, db_session):
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Generate
    gen_payload = {
        "brand_profile_id": "default",
        "context_data": {"title": "Test Product"}
    }
    resp_gen = await client.post("/api/v1/ai/copy/product-title", json=gen_payload, headers=headers)
    log_id = resp_gen.json()["log_id"]
    
    # 2. Accept
    acc_payload = {"variant_accepted": 1, "was_edited": True}
    resp_acc = await client.post(f"/api/v1/ai/copy/accept/{log_id}", json=acc_payload, headers=headers)
    assert resp_acc.status_code == 200
    
    # 3. Verify in DB
    result = await db_session.execute(
        select(AICopywriterLog).where(AICopywriterLog.log_id == log_id)
    )
    log = result.scalar_one()
    assert log.variant_accepted == 1
    assert log.was_edited is True
