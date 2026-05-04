import pytest
from httpx import AsyncClient
from modules.catalog.models import Product, Variant
from shared.auth import UserClaims

@pytest.mark.asyncio
async def test_connect_channel(client: AsyncClient, mock_firebase_user, auth_override):
    auth_override(UserClaims(uid="test_user", tenant_id="t_abc", roles=["owner"], is_owner=True))
    headers = {"Authorization": "Bearer valid_token"}
    response = await client.post(
        "/api/v1/channels/tiktok/connect",
        headers=headers
    )
    assert response.status_code == 200
    assert "Successfully connected" in response.json()["message"]

@pytest.mark.asyncio
async def test_list_channels(client: AsyncClient, mock_firebase_user, auth_override, db_session):
    auth_override(UserClaims(uid="test_user", tenant_id="t_abc", roles=["owner"], is_owner=True))
    headers = {"Authorization": "Bearer valid_token"}
    
    # First connect
    await client.post("/api/v1/channels/tiktok/connect", headers=headers)
    
    response = await client.get(
        "/api/v1/channels",
        headers=headers
    )
    assert response.status_code == 200
    channels = response.json()
    assert len(channels) >= 1
    assert any(c["channel_type"] == "tiktok" for c in channels)

@pytest.mark.asyncio
async def test_google_shopping_feed(client: AsyncClient, db_session):
    # Setup: Create a product and variant
    tenant_id = "test-tenant"
    product = Product(
        tenant_id=tenant_id,
        title="Test Hiking Boot",
        description="A very good boot",
        slug="test-hiking-boot",
        status="active",
        created_by="test-user"
    )
    db_session.add(product)
    await db_session.flush()
    
    variant = Variant(
        product_id=product.product_id,
        tenant_id=tenant_id,
        sku="BOOT-001",
        price=99.99,
        is_active=True
    )
    db_session.add(variant)
    await db_session.commit()
    
    response = await client.get(f"/api/v1/feeds/google-shopping?tenant_id={tenant_id}")
    assert response.status_code == 200
    assert "application/xml" in response.headers["content-type"]
    assert "Test Hiking Boot" in response.text
    assert "BOOT-001" in response.text
    assert "99.99 USD" in response.text

@pytest.mark.asyncio
async def test_tiktok_sync(client: AsyncClient, mock_firebase_user, auth_override, db_session):
    auth_override(UserClaims(uid="test_user", tenant_id="t_abc", roles=["owner"], is_owner=True))
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Connect TikTok
    await client.get("/api/v1/channels/tiktok/callback?code=mock_code&state=t_abc")
    
    # 2. Setup: Create a product and variant
    product = Product(
        tenant_id="t_abc",
        title="TikTok Shoe",
        slug="tiktok-shoe",
        status="active",
        created_by="test-user"
    )
    db_session.add(product)
    await db_session.flush()
    
    variant = Variant(
        product_id=product.product_id,
        tenant_id="t_abc",
        sku="TSH-001",
        price=49.99,
        is_active=True
    )
    db_session.add(variant)
    await db_session.commit()
    
    # 3. Trigger Sync
    response = await client.post(
        "/api/v1/channels/tiktok/sync",
        headers=headers
    )
    assert response.status_code == 200
    assert response.json()["items_synced"] >= 1
    assert response.json()["status"] == "success"

@pytest.mark.asyncio
async def test_instagram_sync(client: AsyncClient, mock_firebase_user, auth_override, db_session):
    auth_override(UserClaims(uid="test_user", tenant_id="t_abc", roles=["owner"], is_owner=True))
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Connect Instagram
    await client.get("/api/v1/channels/instagram/callback?code=mock_code&state=t_abc")
    
    # 2. Setup: Create a product and variant
    product = Product(
        tenant_id="t_abc",
        title="Insta Dress",
        slug="insta-dress",
        status="active",
        created_by="test-user"
    )
    db_session.add(product)
    await db_session.flush()
    
    variant = Variant(
        product_id=product.product_id,
        tenant_id="t_abc",
        sku="IDR-001",
        price=59.99,
        is_active=True
    )
    db_session.add(variant)
    await db_session.commit()
    
    # 3. Trigger Sync
    response = await client.post(
        "/api/v1/channels/instagram/sync",
        headers=headers
    )
    assert response.status_code == 200
    assert response.json()["items_synced"] >= 1
    assert response.json()["status"] == "success"

@pytest.mark.asyncio
async def test_facebook_sync(client: AsyncClient, mock_firebase_user, auth_override, db_session):
    auth_override(UserClaims(uid="test_user", tenant_id="t_abc", roles=["owner"], is_owner=True))
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Connect Facebook
    await client.get("/api/v1/channels/facebook/callback?code=mock_code&state=t_abc")
    
    # 2. Setup: Create a product and variant
    product = Product(
        tenant_id="t_abc",
        title="FB Shirt",
        slug="fb-shirt",
        status="active",
        created_by="test-user"
    )
    db_session.add(product)
    await db_session.flush()
    
    variant = Variant(
        product_id=product.product_id,
        tenant_id="t_abc",
        sku="FBS-001",
        price=29.99,
        is_active=True
    )
    db_session.add(variant)
    await db_session.commit()
    
    # 3. Trigger Sync
    response = await client.post(
        "/api/v1/channels/facebook/sync",
        headers=headers
    )
    assert response.status_code == 200
    assert response.json()["items_synced"] >= 1
    assert response.json()["status"] == "success"
