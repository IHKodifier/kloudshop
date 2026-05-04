from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from shared.db import get_db
from modules.catalog.models import Product, Variant
from typing import List
import xml.etree.ElementTree as ET
from datetime import datetime

router = APIRouter(tags=["Feeds"])

@router.get("/google-shopping")
async def google_shopping_feed(
    tenant_id: str, # For MVP, passing tenant_id in query; in prod, extracted from domain
    db: AsyncSession = Depends(get_db)
):
    """Generates a live Google Shopping XML feed for the tenant."""
    # Note: In a real multi-tenant app, the tenant_id would be determined by the host header
    # or a specific path parameter /storefront/{tenant}/feeds/google-shopping
    
    result = await db.execute(
        select(Product).options(selectinload(Product.variants)).filter(
            Product.tenant_id == tenant_id,
            Product.status == 'active'
        )
    )
    products = result.scalars().all()
    
    # Root element
    rss = ET.Element("rss", version="2.0")
    rss.set("xmlns:g", "http://base.google.com/ns/1.0")
    
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = f"KloudShop Product Feed - {tenant_id}"
    ET.SubElement(channel, "link").text = f"https://{tenant_id}.kloudshop.biz"
    ET.SubElement(channel, "description").text = f"Live product feed for {tenant_id}"
    
    for product in products:
        for variant in product.variants:
            if not variant.is_active:
                continue
                
            item = ET.SubElement(channel, "item")
            ET.SubElement(item, "g:id").text = variant.sku
            ET.SubElement(item, "g:title").text = product.title
            ET.SubElement(item, "g:description").text = product.description or product.title
            ET.SubElement(item, "g:link").text = f"https://{tenant_id}.kloudshop.biz/products/{product.slug}"
            # TODO: Add image_link once image handling is finalized
            ET.SubElement(item, "g:image_link").text = "https://placehold.co/600x600.png"
            ET.SubElement(item, "g:availability").text = "in_stock" # TODO: Link to actual inventory
            ET.SubElement(item, "g:price").text = f"{variant.price} USD"
            ET.SubElement(item, "g:brand").text = tenant_id # Fallback to tenant_id
            if variant.barcode:
                ET.SubElement(item, "g:gtin").text = variant.barcode
            ET.SubElement(item, "g:mpn").text = variant.sku
            ET.SubElement(item, "g:condition").text = "new"
            
    xml_data = ET.tostring(rss, encoding='utf-8', method='xml')
    return Response(content=xml_data, media_type="application/xml")
