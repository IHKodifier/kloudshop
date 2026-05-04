from fastapi import APIRouter, Depends, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from shared.db import get_db
from modules.catalog.models import Product, Collection
from modules.blog.models import BlogPost
from .models import BrandProfile
from datetime import datetime

router = APIRouter(tags=["SEO"])

@router.get("/{tenant}/sitemap.xml")
async def get_sitemap(
    tenant: str,
    db: AsyncSession = Depends(get_db)
):
    """Generates a dynamic XML sitemap for the storefront."""
    # 1. Resolve tenant_id
    profile_result = await db.execute(select(BrandProfile).where(BrandProfile.slug == tenant))
    profile = profile_result.scalar_one_or_none()
    tenant_id = profile.tenant_id if profile else tenant
    
    base_url = f"https://{tenant}.kloudshop.biz"
    
    # 2. Fetch URLs
    # Products
    products_result = await db.execute(select(Product.slug, Product.updated_at).where(Product.tenant_id == tenant_id, Product.status == "active"))
    products = products_result.all()
    
    # Collections
    collections_result = await db.execute(select(Collection.slug, Collection.updated_at).where(Collection.tenant_id == tenant_id))
    collections = collections_result.all()
    
    # Blog Posts
    posts_result = await db.execute(select(BlogPost.slug, BlogPost.updated_at).where(BlogPost.tenant_id == tenant_id, BlogPost.status == "published"))
    posts = posts_result.all()
    
    # 3. Build XML
    xml_content = '<?xml version="1.0" encoding="UTF-8"?>\n'
    xml_content += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    
    # Homepage
    xml_content += f'  <url><loc>{base_url}/</loc><priority>1.0</priority></url>\n'
    
    # Products
    for p in products:
        lastmod = p.updated_at.date().isoformat() if p.updated_at else datetime.utcnow().date().isoformat()
        xml_content += f'  <url><loc>{base_url}/products/{p.slug}</loc><lastmod>{lastmod}</lastmod><priority>0.8</priority></url>\n'
        
    # Collections
    for c in collections:
        lastmod = c.updated_at.date().isoformat() if c.updated_at else datetime.utcnow().date().isoformat()
        xml_content += f'  <url><loc>{base_url}/collections/{c.slug}</loc><lastmod>{lastmod}</lastmod><priority>0.6</priority></url>\n'
        
    # Blog Posts
    for b in posts:
        lastmod = b.updated_at.date().isoformat() if b.updated_at else datetime.utcnow().date().isoformat()
        xml_content += f'  <url><loc>{base_url}/blog/{b.slug}</loc><lastmod>{lastmod}</lastmod><priority>0.5</priority></url>\n'
        
    xml_content += '</urlset>'
    
    return Response(content=xml_content, media_type="application/xml")
