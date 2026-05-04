import pytest
from httpx import AsyncClient
from modules.catalog.models import Product, Variant
from modules.blog.models import BlogPost
from modules.storefront.models import BrandProfile

@pytest.mark.asyncio
async def test_jsonld_structured_data(client: AsyncClient, db_session):
    # Setup
    tenant_id = "t_seo"
    profile = BrandProfile(tenant_id=tenant_id, slug="seostore", brand_name="SEO Store", is_published=True)
    db_session.add(profile)
    
    product = Product(tenant_id=tenant_id, title="SEO Jacket", slug="seo-jacket", status="active", created_by="a1")
    db_session.add(product)
    await db_session.flush()
    variant = Variant(product_id=product.product_id, tenant_id=tenant_id, sku="SEO-J", price=99.99)
    db_session.add(variant)
    
    post = BlogPost(tenant_id=tenant_id, title="SEO Post", slug="seo-post", status="published", author_id="a1")
    db_session.add(post)
    await db_session.commit()
    
    # 1. Check Product JSON-LD
    response = await client.get("/api/v1/storefront/seostore/products/seo-jacket")
    assert response.status_code == 200
    data = response.json()
    assert "structured_data" in data
    assert data["structured_data"]["@type"] == "Product"
    assert data["structured_data"]["name"] == "SEO Jacket"
    
    # 2. Check Blog JSON-LD
    response = await client.get("/api/v1/storefront/seostore/blog/seo-post")
    assert response.status_code == 200
    data = response.json()
    assert "structured_data" in data
    assert data["structured_data"]["@type"] == "BlogPosting"
    assert data["structured_data"]["headline"] == "SEO Post"

@pytest.mark.asyncio
async def test_sitemap_xml(client: AsyncClient, db_session):
    # Setup
    tenant_id = "t_sitemap"
    profile = BrandProfile(tenant_id=tenant_id, slug="xmlstore", brand_name="XML Store", is_published=True)
    db_session.add(profile)
    
    product = Product(tenant_id=tenant_id, title="XML Product", slug="xml-prod", status="active", created_by="a1")
    db_session.add(product)
    await db_session.flush()
    variant = Variant(product_id=product.product_id, tenant_id=tenant_id, sku="XML-V", price=10.00)
    db_session.add(variant)
    post = BlogPost(tenant_id=tenant_id, title="XML Post", slug="xml-post", status="published", author_id="a1")
    db_session.add(post)
    await db_session.commit()
    
    response = await client.get("/api/v1/storefront/xmlstore/sitemap.xml")
    assert response.status_code == 200
    assert response.headers["Content-Type"] == "application/xml"
    content = response.text
    assert '<?xml version="1.0" encoding="UTF-8"?>' in content
    assert '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' in content
    assert 'xml-prod' in content
    assert 'xml-post' in content
    assert '<priority>1.0</priority>' in content # Homepage
