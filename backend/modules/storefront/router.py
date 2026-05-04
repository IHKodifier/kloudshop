from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime

from shared.db import get_db
from shared.auth import UserClaims
from shared.rbac import has_permissions
from .models import (
    BrandProfile, StorefrontContent, StaticPage,
    MerchantCarrierConnection, CarrierCheckoutOption
)
from .schemas import (
    BrandProfileCreate, BrandProfileUpdate, BrandProfileResponse,
    StorefrontContentCreate, StorefrontContentResponse,
    StaticPageCreate, StaticPageUpdate, StaticPageResponse,
    CarrierConnectionCreate, CarrierConnectionResponse,
    CheckoutOptionCreate, CheckoutOptionResponse,
    ShippingRateRequest, ShippingRateResponse
)
from modules.catalog.models import Product, Variant
from modules.blog.models import BlogPost, BlogCategory, BlogTag
from modules.blog import schemas as blog_schemas
from shared.analytics import track_event
from shared.locale import resolve_locale
from shared.seo import generate_article_jsonld, generate_product_jsonld

router = APIRouter(tags=["Storefront"])

# --- Public Storefront Endpoints ---

@router.get("/{tenant}/profile", response_model=BrandProfileResponse)
async def get_storefront_profile(
    tenant: str,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(BrandProfile).where(
            BrandProfile.slug == tenant,
            BrandProfile.is_published == True
        )
    )
    profile = result.scalar_one_or_none()
    if not profile:
        # Try finding by tenant_id if slug didn't match (for admin/preview)
        result = await db.execute(
            select(BrandProfile).where(BrandProfile.tenant_id == tenant)
        )
        profile = result.scalar_one_or_none()
    
    if not profile:
        raise HTTPException(status_code=404, detail="Storefront not found")
    return profile

@router.get("/{tenant}/content", response_model=List[StorefrontContentResponse])
async def get_storefront_content(
    tenant: str,
    locale: str = "en",
    db: AsyncSession = Depends(get_db)
):
    # Find brand profile to get tenant_id
    profile_result = await db.execute(
        select(BrandProfile).where(BrandProfile.slug == tenant)
    )
    profile = profile_result.scalar_one_or_none()
    if not profile:
        # Fallback to direct tenant_id
        tenant_id = tenant
    else:
        tenant_id = profile.tenant_id
        
    result = await db.execute(
        select(StorefrontContent).where(
            StorefrontContent.tenant_id == tenant_id,
            StorefrontContent.locale == locale
        )
    )
    return result.scalars().all()

@router.get("/{tenant}/products")
async def list_storefront_products(
    tenant: str,
    db: AsyncSession = Depends(get_db)
):
    # Public read-only product list for a tenant
    # Find brand profile to get tenant_id
    profile_result = await db.execute(
        select(BrandProfile).where(BrandProfile.slug == tenant)
    )
    profile = profile_result.scalar_one_or_none()
    if not profile:
        tenant_id = tenant
    else:
        tenant_id = profile.tenant_id

    result = await db.execute(
        select(Product)
        .where(Product.tenant_id == tenant_id, Product.status == "active")
        .options(selectinload(Product.variants))
    )
    return result.scalars().all()

@router.get("/{tenant}/products/{product_slug}")
async def get_storefront_product(
    tenant: str,
    product_slug: str,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    profile_result = await db.execute(
        select(BrandProfile).where(BrandProfile.slug == tenant)
    )
    profile = profile_result.scalar_one_or_none()
    if not profile:
        tenant_id = tenant
    else:
        tenant_id = profile.tenant_id
        
    result = await db.execute(
        select(Product)
        .where(
            Product.tenant_id == tenant_id, 
            Product.slug == product_slug,
            Product.status == "active"
        )
        .options(selectinload(Product.variants))
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
        
    # Track performance analytics
    background_tasks.add_task(
        track_event,
        tenant_id=tenant_id,
        event_type="product_view",
        data={"product_id": product.product_id, "product_slug": product_slug}
    )
    
    # Generate SEO structured data
    base_url = f"https://{tenant}.kloudshop.biz" # Mock base URL
    product_data = product.__dict__.copy()
    product_data["structured_data"] = generate_product_jsonld(product, product.variants, tenant_id, base_url)
    
    return product_data

@router.get("/{tenant}/pages/{page_slug}", response_model=StaticPageResponse)
async def get_storefront_page(
    tenant: str,
    page_slug: str,
    db: AsyncSession = Depends(get_db)
):
    profile_result = await db.execute(
        select(BrandProfile).where(BrandProfile.slug == tenant)
    )
    profile = profile_result.scalar_one_or_none()
    if not profile:
        tenant_id = tenant
    else:
        tenant_id = profile.tenant_id

    result = await db.execute(
        select(StaticPage).where(
            StaticPage.tenant_id == tenant_id,
            StaticPage.slug == page_slug,
            StaticPage.status == "published"
        )
    )
    page = result.scalar_one_or_none()
    if not page:
        raise HTTPException(status_code=404, detail="Page not found")
    return page

@router.get("/{tenant}/search")
async def storefront_search(
    tenant: str,
    q: str,
    db: AsyncSession = Depends(get_db)
):
    profile_result = await db.execute(
        select(BrandProfile).where(BrandProfile.slug == tenant)
    )
    profile = profile_result.scalar_one_or_none()
    tenant_id = profile.tenant_id if profile else tenant
    
    # Simple keyword search (fallback for pgvector)
    result = await db.execute(
        select(Product)
        .where(
            Product.tenant_id == tenant_id,
            Product.status == "active",
            (Product.title.ilike(f"%{q}%")) | (Product.description.ilike(f"%{q}%"))
        )
        .options(selectinload(Product.variants))
    )
    return result.scalars().all()

@router.get("/{tenant}/blog")
async def list_storefront_blog(
    tenant: str,
    request: Request,
    category: Optional[str] = None,
    tag: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    profile_result = await db.execute(
        select(BrandProfile).where(BrandProfile.slug == tenant)
    )
    profile = profile_result.scalar_one_or_none()
    tenant_id = profile.tenant_id if profile else tenant
    supported_locales = profile.enabled_locales if profile else ["en"]
    locale = resolve_locale(request, supported_locales)

    query = select(BlogPost).options(
        selectinload(BlogPost.categories),
        selectinload(BlogPost.tags),
        selectinload(BlogPost.translations)
    ).where(
        BlogPost.tenant_id == tenant_id,
        BlogPost.status == "published"
    )
    
    if category:
        query = query.join(BlogPost.categories).where(BlogCategory.slug == category)
    if tag:
        query = query.join(BlogPost.tags).where(BlogTag.slug == tag)
        
    result = await db.execute(query.order_by(BlogPost.published_at.desc()))
    posts = result.scalars().all()
    
    # Apply translations
    if locale != "en":
        for post in posts:
            for trans in post.translations:
                if trans.locale == locale:
                    post.title = trans.title
                    post.excerpt = trans.excerpt
                    break
                    
    return posts

@router.get("/{tenant}/blog/{post_slug}")
async def get_storefront_blog_post(
    tenant: str,
    post_slug: str,
    request: Request,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    profile_result = await db.execute(
        select(BrandProfile).where(BrandProfile.slug == tenant)
    )
    profile = profile_result.scalar_one_or_none()
    tenant_id = profile.tenant_id if profile else tenant
    supported_locales = profile.enabled_locales if profile else ["en"]
    locale = resolve_locale(request, supported_locales)

    result = await db.execute(
        select(BlogPost).options(
            selectinload(BlogPost.categories),
            selectinload(BlogPost.tags),
            selectinload(BlogPost.translations)
        ).where(
            BlogPost.tenant_id == tenant_id,
            BlogPost.slug == post_slug,
            BlogPost.status == "published"
        )
    )
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="Blog post not found")
        
    # Apply translations
    if locale != "en":
        for trans in post.translations:
            if trans.locale == locale:
                post.title = trans.title
                post.excerpt = trans.excerpt
                post.body = trans.body
                post.meta_title = trans.meta_title
                post.meta_description = trans.meta_description
                break
                
    # Track performance analytics
    background_tasks.add_task(
        track_event,
        tenant_id=tenant_id,
        event_type="blog_post_view",
        data={"post_id": post.id, "post_slug": post_slug, "locale": locale}
    )
    
    # Generate SEO structured data
    base_url = f"https://{tenant}.kloudshop.biz" # Mock base URL
    post_data = post.__dict__.copy()
    post_data["structured_data"] = generate_article_jsonld(post, tenant_id, base_url)
    
    return post_data

# --- Admin / Management Endpoints ---

@router.post("/profile", response_model=BrandProfileResponse)
async def create_brand_profile(
    profile_in: BrandProfileCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["storefront:write"])
):
    profile = BrandProfile(
        **profile_in.model_dump(),
        tenant_id=user.tenant_id
    )
    db.add(profile)
    await db.commit()
    await db.refresh(profile)
    return profile

@router.patch("/profile", response_model=BrandProfileResponse)
async def update_brand_profile(
    profile_in: BrandProfileUpdate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["storefront:write"])
):
    result = await db.execute(
        select(BrandProfile).where(BrandProfile.tenant_id == user.tenant_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Brand profile not found")
    
    for field, value in profile_in.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    
    await db.commit()
    await db.refresh(profile)
    return profile

@router.post("/content", response_model=StorefrontContentResponse)
async def upsert_storefront_content(
    content_in: StorefrontContentCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["storefront:write"])
):
    # Check if exists
    result = await db.execute(
        select(StorefrontContent).where(
            StorefrontContent.tenant_id == user.tenant_id,
            StorefrontContent.slot_id == content_in.slot_id,
            StorefrontContent.locale == content_in.locale
        )
    )
    content = result.scalar_one_or_none()
    
    if content:
        content.content_value = content_in.content_value
        content.slot_type = content_in.slot_type
        content.updated_by = user.uid
    else:
        content = StorefrontContent(
            **content_in.model_dump(),
            tenant_id=user.tenant_id,
            updated_by=user.uid
        )
        db.add(content)
    
    await db.commit()
    await db.refresh(content)
    return content

@router.post("/pages", response_model=StaticPageResponse)
async def create_static_page(
    page_in: StaticPageCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["storefront:write"])
):
    page = StaticPage(
        **page_in.model_dump(),
        tenant_id=user.tenant_id,
        created_by=user.uid
    )
    db.add(page)
    await db.commit()
    await db.refresh(page)
    return page

# --- Shipping Management ---

@router.post("/shipping/connections", response_model=CarrierConnectionResponse)
async def create_carrier_connection(
    conn_in: CarrierConnectionCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["storefront:write"])
):
    conn = MerchantCarrierConnection(
        **conn_in.model_dump(),
        tenant_id=user.tenant_id,
        connected_by=user.uid
    )
    db.add(conn)
    await db.commit()
    await db.refresh(conn)
    return conn

@router.get("/shipping/options", response_model=List[CheckoutOptionResponse])
async def list_checkout_options(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["storefront:write"])
):
    result = await db.execute(
        select(CarrierCheckoutOption).where(CarrierCheckoutOption.tenant_id == user.tenant_id)
    )
    return result.scalars().all()

@router.post("/shipping/options", response_model=CheckoutOptionResponse)
async def create_checkout_option(
    opt_in: CheckoutOptionCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["storefront:write"])
):
    opt = CarrierCheckoutOption(
        **opt_in.model_dump(),
        tenant_id=user.tenant_id
    )
    db.add(opt)
    await db.commit()
    await db.refresh(opt)
    return opt

@router.post("/shipping/rates", response_model=List[ShippingRateResponse])
async def get_shipping_rates(
    rate_req: ShippingRateRequest,
    db: AsyncSession = Depends(get_db),
):
    # In a real app, we'd find the tenant from the context or header
    # For now, let's assume we fetch all enabled options for a tenant
    # (In production, this would be scoped to the storefront's tenant)
    result = await db.execute(
        select(CarrierCheckoutOption).where(CarrierCheckoutOption.is_enabled == True)
    )
    options = result.scalars().all()
    
    rates = []
    for opt in options:
        # Filter by country if restricted
        if opt.allowed_destination_countries and rate_req.country not in opt.allowed_destination_countries:
            continue
            
        # Base rate (mocked carrier response)
        base_rate = 10.0 if opt.service_level_id == "standard" else 25.0
        
        # Free Shipping Rules Engine (Mocked threshold: $100)
        cart_total = sum(item.get("price", 0) * item.get("quantity", 1) for item in rate_req.items)
        if cart_total >= 100.0 and opt.service_level_id == "standard":
            final_rate = 0.0
            display_name = "Free Standard Shipping"
        else:
            # Apply markup
            final_rate = base_rate
            if opt.handling_markup_type == "flat":
                final_rate += float(opt.handling_markup_value)
            elif opt.handling_markup_type == "percentage":
                final_rate *= (1 + float(opt.handling_markup_value) / 100)
            display_name = opt.display_name_override or opt.service_level_id.capitalize()
            
        rates.append({
            "service_level_id": opt.service_level_id,
            "display_name": display_name,
            "rate": round(final_rate, 2),
            "currency": "USD",
            "estimated_days": 5 if opt.service_level_id == "standard" else 2
        })
    
    # Fallback if no options configured
    if not rates:
        cart_total = sum(item.get("price", 0) * item.get("quantity", 1) for item in rate_req.items)
        rate = 0.0 if cart_total >= 100.0 else 10.0
        display_name = "Free Standard Shipping" if rate == 0.0 else "Standard Shipping"
        
        rates.append({
            "service_level_id": "standard",
            "display_name": display_name,
            "rate": rate,
            "currency": "USD",
            "estimated_days": 7
        })
        
    return rates

@router.post("/shipping/labels/{order_id}")
async def generate_shipping_label(
    order_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["storefront:write"])
):
    # Mock label generation
    return {
        "order_id": order_id,
        "label_url": f"https://storage.googleapis.com/kloudshop-labels/{order_id}.pdf",
        "tracking_number": f"1Z{uuid4().hex[:12].upper()}",
        "carrier": "USPS",
        "status": "generated"
    }
