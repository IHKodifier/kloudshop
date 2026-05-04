from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from shared.db import get_db
from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from . import models, schemas, service
from typing import List

router = APIRouter(tags=["Social Commerce"])

@router.get("", response_model=List[schemas.ChannelConnectionRead])
async def list_channels(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["channels:manage"])
):
    """List all connected social channels for the tenant."""
    tenant_id = user.tenant_id
    result = await db.execute(
        select(models.ChannelConnection).filter(models.ChannelConnection.tenant_id == tenant_id)
    )
    return result.scalars().all()

@router.post("/{channel_type}/connect")
async def connect_channel(
    channel_type: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["channels:manage"])
):
    """Initiate a connection to a social channel."""
    tenant_id = user.tenant_id
    
    if channel_type not in ['tiktok', 'instagram', 'facebook', 'google']:
        raise HTTPException(status_code=400, detail="Invalid channel type")
        
    # Check if already connected
    result = await db.execute(
        select(models.ChannelConnection).filter(
            models.ChannelConnection.tenant_id == tenant_id,
            models.ChannelConnection.channel_type == channel_type
        )
    )
    existing = result.scalar_one_or_none()
    
    if existing and existing.status == "connected":
        return {"message": f"{channel_type} already connected", "connection_id": existing.connection_id}
        
    # Mocking OAuth initiation
    if not existing:
        connection = models.ChannelConnection(
            tenant_id=tenant_id,
            channel_type=channel_type,
            status="connected", # Auto-connect for MVP/Mock
            credentials_secret_id=f"secret_{channel_type}_{tenant_id}"
        )
        db.add(connection)
        await db.commit()
        return {"message": f"Successfully connected to {channel_type}", "connection_id": connection.connection_id}
    else:
        existing.status = "connected"
        await db.commit()
        return {"message": f"Successfully reconnected to {channel_type}", "connection_id": existing.connection_id}

@router.get("/tiktok/connect")
async def tiktok_connect(
    user: UserClaims = has_permissions(["channels:manage"])
):
    """Generate TikTok OAuth authorization URL."""
    # In a real app, this would use client_id and redirect_uri from environment
    # For now, we return a mock URL
    return {
        "auth_url": f"https://auth.tiktok-shop.com/oauth/authorize?app_id=mock_app_id&state={user.tenant_id}&redirect_uri=https://api.kloudshop.biz/api/v1/channels/tiktok/callback"
    }

@router.get("/tiktok/callback")
async def tiktok_callback(
    code: str,
    state: str,
    db: AsyncSession = Depends(get_db)
):
    """Handle TikTok OAuth callback and exchange code for access token."""
    # In a real app, 'state' would contain the tenant_id or a secure nonce
    tenant_id = state
    
    # Mock token exchange
    access_token = f"mock_tiktok_token_{code}"
    
    # Store connection in DB
    result = await db.execute(
        select(models.ChannelConnection).filter(
            models.ChannelConnection.tenant_id == tenant_id,
            models.ChannelConnection.channel_type == "tiktok"
        )
    )
    connection = result.scalar_one_or_none()
    
    if not connection:
        connection = models.ChannelConnection(
            tenant_id=tenant_id,
            channel_type="tiktok",
            status="connected",
            credentials_secret_id=f"tiktok_token_{tenant_id}"
        )
        db.add(connection)
    else:
        connection.status = "connected"
        connection.credentials_secret_id = f"tiktok_token_{tenant_id}"
        
    await db.commit()
    return {"status": "success", "message": "TikTok Shop connected successfully"}

@router.get("/instagram/connect")
async def instagram_connect(
    user: UserClaims = has_permissions(["channels:manage"])
):
    """Generate Instagram (Meta) OAuth authorization URL."""
    return {
        "auth_url": f"https://www.facebook.com/v18.0/dialog/oauth?client_id=mock_meta_id&state={user.tenant_id}&redirect_uri=https://api.kloudshop.biz/api/v1/channels/instagram/callback&scope=instagram_basic,instagram_shopping_tagging"
    }

@router.get("/instagram/callback")
async def instagram_callback(
    code: str,
    state: str,
    db: AsyncSession = Depends(get_db)
):
    """Handle Instagram OAuth callback."""
    tenant_id = state
    
    # Store connection in DB
    result = await db.execute(
        select(models.ChannelConnection).filter(
            models.ChannelConnection.tenant_id == tenant_id,
            models.ChannelConnection.channel_type == "instagram"
        )
    )
    connection = result.scalar_one_or_none()
    
    if not connection:
        connection = models.ChannelConnection(
            tenant_id=tenant_id,
            channel_type="instagram",
            status="connected",
            credentials_secret_id=f"instagram_token_{tenant_id}"
        )
        db.add(connection)
    else:
        connection.status = "connected"
        
    await db.commit()
    return {"status": "success", "message": "Instagram Shopping connected successfully"}

@router.get("/facebook/connect")
async def facebook_connect(
    user: UserClaims = has_permissions(["channels:manage"])
):
    """Generate Facebook OAuth authorization URL."""
    return {
        "auth_url": f"https://www.facebook.com/v18.0/dialog/oauth?client_id=mock_meta_id&state={user.tenant_id}&redirect_uri=https://api.kloudshop.biz/api/v1/channels/facebook/callback&scope=ads_management,catalog_management"
    }

@router.get("/facebook/callback")
async def facebook_callback(
    code: str,
    state: str,
    db: AsyncSession = Depends(get_db)
):
    """Handle Facebook OAuth callback."""
    tenant_id = state
    
    # Store connection in DB
    result = await db.execute(
        select(models.ChannelConnection).filter(
            models.ChannelConnection.tenant_id == tenant_id,
            models.ChannelConnection.channel_type == "facebook"
        )
    )
    connection = result.scalar_one_or_none()
    
    if not connection:
        connection = models.ChannelConnection(
            tenant_id=tenant_id,
            channel_type="facebook",
            status="connected",
            credentials_secret_id=f"facebook_token_{tenant_id}"
        )
        db.add(connection)
    else:
        connection.status = "connected"
        
    await db.commit()
    return {"status": "success", "message": "Facebook Shops connected successfully"}

@router.post("/{channel_type}/sync")
async def sync_channel(
    channel_type: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["channels:manage"])
):
    """Trigger a manual catalog sync for a specific channel."""
    tenant_id = user.tenant_id
    
    sync_service = service.ChannelSyncService(db)
    result = await sync_service.trigger_sync(tenant_id, channel_type)
    
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
        
    return result

@router.delete("/{channel_type}")
async def disconnect_channel(
    channel_type: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["channels:manage"])
):
    """Disconnect a social channel."""
    tenant_id = user.tenant_id
    
    result = await db.execute(
        select(models.ChannelConnection).filter(
            models.ChannelConnection.tenant_id == tenant_id,
            models.ChannelConnection.channel_type == channel_type
        )
    )
    connection = result.scalar_one_or_none()
    
    if not connection:
        raise HTTPException(status_code=404, detail="Channel connection not found")
        
    await db.delete(connection)
    await db.commit()
    return {"message": f"Successfully disconnected from {channel_type}"}
