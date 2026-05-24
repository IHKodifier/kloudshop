from abc import ABC, abstractmethod
from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from .models import ChannelConnection, ChannelSyncLog
from datetime import datetime, timezone

class ChannelAdapter(ABC):
    @abstractmethod
    async def sync_catalog(self, tenant_id: str, credentials: Any) -> Dict[str, Any]:
        pass

from modules.catalog.models import Product, Variant
from sqlalchemy.orm import selectinload

class TikTokAdapter(ChannelAdapter):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def sync_catalog(self, tenant_id: str, credentials: Any) -> Dict[str, Any]:
        # 1. Fetch active products with variants
        result = await self.db.execute(
            select(Product).options(selectinload(Product.variants)).filter(
                Product.tenant_id == tenant_id,
                Product.status == 'active'
            )
        )
        products = result.scalars().all()
        
        # 2. Transform to TikTok format
        tiktok_payloads = []
        for product in products:
            skus = []
            for variant in product.variants:
                if not variant.is_active:
                    continue
                skus.append({
                    "seller_sku": variant.sku,
                    "original_price": str(variant.price),
                    "stock": 100, # TODO: Use real inventory
                })
            
            if skus:
                tiktok_payloads.append({
                    "product_name": product.title,
                    "description": product.description or product.title,
                    "skus": skus
                })
        
        # 3. Mock API Upload
        # In a real app, this would use httpx to call TikTok Shop API
        items_synced = len(tiktok_payloads)
        print(f"DEBUG: Syncing {items_synced} products to TikTok for tenant {tenant_id}")
        
        return {
            "status": "success", 
            "items_synced": items_synced,
            "items_failed": 0
        }

class InstagramAdapter(ChannelAdapter):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def sync_catalog(self, tenant_id: str, credentials: Any) -> Dict[str, Any]:
        # 1. Fetch active products with variants
        result = await self.db.execute(
            select(Product).options(selectinload(Product.variants)).filter(
                Product.tenant_id == tenant_id,
                Product.status == 'active'
            )
        )
        products = result.scalars().all()
        
        # 2. Transform to Meta (Instagram/Facebook) format
        meta_payloads = []
        for product in products:
            for variant in product.variants:
                if not variant.is_active:
                    continue
                meta_payloads.append({
                    "id": variant.sku,
                    "title": product.title,
                    "description": product.description or product.title,
                    "availability": "in stock",
                    "condition": "new",
                    "price": f"{variant.price} USD",
                    "link": f"https://{tenant_id}.kloudshop.biz/products/{product.slug}",
                    "image_link": "https://placehold.co/600x600.png",
                    "brand": tenant_id
                })
        
        # 3. Mock Meta Batch API Upload
        items_synced = len(meta_payloads)
        print(f"DEBUG: Syncing {items_synced} products to Instagram for tenant {tenant_id}")
        
        return {
            "status": "success", 
            "items_synced": items_synced,
            "items_failed": 0
        }

class FacebookAdapter(ChannelAdapter):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def sync_catalog(self, tenant_id: str, credentials: Any) -> Dict[str, Any]:
        # Facebook uses the same Meta Catalog format as Instagram
        result = await self.db.execute(
            select(Product).options(selectinload(Product.variants)).filter(
                Product.tenant_id == tenant_id,
                Product.status == 'active'
            )
        )
        products = result.scalars().all()
        
        meta_payloads = []
        for product in products:
            for variant in product.variants:
                if not variant.is_active:
                    continue
                meta_payloads.append({
                    "id": variant.sku,
                    "title": product.title,
                    "description": product.description or product.title,
                    "availability": "in stock",
                    "condition": "new",
                    "price": f"{variant.price} USD",
                    "link": f"https://{tenant_id}.kloudshop.biz/products/{product.slug}",
                    "brand": tenant_id
                })
        
        items_synced = len(meta_payloads)
        print(f"DEBUG: Syncing {items_synced} products to Facebook for tenant {tenant_id}")
        
        return {
            "status": "success", 
            "items_synced": items_synced,
            "items_failed": 0
        }

class ChannelSyncService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.adapters = {
            "tiktok": TikTokAdapter(db),
            "instagram": InstagramAdapter(db),
            "facebook": FacebookAdapter(db),
            # "google": GoogleAdapter(),
        }

    async def trigger_sync(self, tenant_id: str, channel_type: str):
        result = await self.db.execute(
            select(ChannelConnection).filter(
                ChannelConnection.tenant_id == tenant_id,
                ChannelConnection.channel_type == channel_type
            )
        )
        connection = result.scalar_one_or_none()

        if not connection or connection.status != "connected":
            return {"error": "Channel not connected"}

        adapter = self.adapters.get(channel_type)
        if not adapter:
            return {"error": "Channel adapter not found"}

        # Create log entry
        log = ChannelSyncLog(
            connection_id=connection.connection_id,
            tenant_id=tenant_id,
            status="processing"
        )
        self.db.add(log)
        await self.db.commit()

        try:
            result = await adapter.sync_catalog(tenant_id, connection.credentials_secret_id)
            
            log.status = result.get("status", "success")
            log.items_synced = result.get("items_synced", 0)
            log.items_failed = result.get("items_failed", 0)
            log.completed_at = datetime.now(timezone.utc)
            
            connection.last_sync_at = log.completed_at
            await self.db.commit()
            
            return result
        except Exception as e:
            log.status = "failure"
            log.error_message = str(e)
            log.completed_at = datetime.now(timezone.utc)
            await self.db.commit()
            return {"error": str(e)}
