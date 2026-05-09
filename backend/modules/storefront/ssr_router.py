from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from typing import Optional
import os

from shared.db import get_db
from modules.catalog.models import Product, Collection
from modules.blog.models import BlogPost
from .models import BrandProfile
from shared.seo import generate_product_jsonld, generate_article_jsonld, generate_meta_tags

router = APIRouter()

# Path to templates
templates_path = os.path.join(os.getcwd(), "backend", "templates")
if not os.path.exists(templates_path):
    # Fallback for different execution contexts
    templates_path = "templates"
    
templates = Jinja2Templates(directory=templates_path)

@router.get("/{tenant}", response_class=HTMLResponse)
async def serve_storefront_home(
    request: Request,
    tenant: str,
    db: AsyncSession = Depends(get_db)
):
    profile_result = await db.execute(select(BrandProfile).where(BrandProfile.slug == tenant))
    profile = profile_result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Storefront not found")
        
    meta = generate_meta_tags(
        title=profile.brand_name,
        description=f"Shop at {profile.brand_name} - Powered by KloudShop",
        url=str(request.url),
        image=profile.logo_url
    )
    
    return templates.TemplateResponse(
        "storefront.html",
        {
            "request": request,
            "type": "home",
            **meta
        }
    )

@router.get("/{tenant}/products/{product_slug}", response_class=HTMLResponse)
async def serve_storefront_product(
    request: Request,
    tenant: str,
    product_slug: str,
    db: AsyncSession = Depends(get_db)
):
    profile_result = await db.execute(select(BrandProfile).where(BrandProfile.slug == tenant))
    profile = profile_result.scalar_one_or_none()
    tenant_id = profile.tenant_id if profile else tenant
    
    result = await db.execute(
        select(Product)
        .where(Product.tenant_id == tenant_id, Product.slug == product_slug, Product.status == "active")
        .options(selectinload(Product.variants))
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
        
    base_url = f"{request.url.scheme}://{request.url.netloc}/{tenant}"
    structured_data = generate_product_jsonld(product, product.variants, tenant_id, base_url)
    
    # Get main image and price
    image_url = product.image_url if hasattr(product, 'image_url') else (product.images[0] if hasattr(product, 'images') and product.images else None)
    price = f"${product.variants[0].price}" if product.variants else ""
    
    meta = generate_meta_tags(
        title=f"{product.title} | {profile.brand_name if profile else 'Store'}",
        description=(product.description or "Shop our amazing products on KloudShop.")[:160],
        url=str(request.url),
        image=image_url
    )
    
    return templates.TemplateResponse(
        "storefront.html",
        {
            "request": request,
            "type": "product",
            "price": price,
            "structured_data": structured_data,
            **meta
        }
    )

@router.get("/{tenant}/blog/{post_slug}", response_class=HTMLResponse)
async def serve_storefront_blog_post(
    request: Request,
    tenant: str,
    post_slug: str,
    db: AsyncSession = Depends(get_db)
):
    profile_result = await db.execute(select(BrandProfile).where(BrandProfile.slug == tenant))
    profile = profile_result.scalar_one_or_none()
    tenant_id = profile.tenant_id if profile else tenant
    
    result = await db.execute(
        select(BlogPost)
        .where(BlogPost.tenant_id == tenant_id, BlogPost.slug == post_slug, BlogPost.status == "published")
    )
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="Blog post not found")
        
    base_url = f"{request.url.scheme}://{request.url.netloc}/{tenant}"
    structured_data = generate_article_jsonld(post, tenant_id, base_url)
    
    meta = generate_meta_tags(
        title=f"{post.title} | {profile.brand_name if profile else 'Blog'}",
        description=(post.excerpt or post.content or "Read our latest updates on KloudShop.")[:160],
        url=str(request.url),
        image=post.cover_image_url
    )
    
    return templates.TemplateResponse(
        "storefront.html",
        {
            "request": request,
            "type": "blog",
            "structured_data": structured_data,
            **meta
        }
    )

@router.get("/{tenant}/orders/{order_id}/success", response_class=HTMLResponse)
async def serve_order_success(
    request: Request,
    tenant: str,
    order_id: str,
    db: AsyncSession = Depends(get_db)
):
    from ..orders.models import Order
    
    profile_result = await db.execute(select(BrandProfile).where(BrandProfile.slug == tenant))
    profile = profile_result.scalar_one_or_none()
    tenant_id = profile.tenant_id if profile else tenant

    order_result = await db.execute(
        select(Order).where(Order.order_id == order_id, Order.tenant_id == tenant_id)
    )
    order = order_result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    meta = generate_meta_tags(
        title=f"Order Success | {profile.brand_name if profile else 'Store'}",
        description="Thank you for your order!",
        url=str(request.url),
        image=profile.logo_url if profile else None
    )

    return templates.TemplateResponse(
        "storefront.html",
        {
            "request": request,
            "type": "order_success",
            "order_id": order_id,
            "customer_email": order.email,
            **meta
        }
    )
