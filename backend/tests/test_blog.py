import pytest
from httpx import AsyncClient
from shared.auth import UserClaims
from modules.blog.models import BlogPost, BlogCategory, BlogTag
from modules.storefront.models import BrandProfile

@pytest.mark.asyncio
async def test_create_blog_post(client: AsyncClient, mock_firebase_user, auth_override, db_session):
    auth_override(UserClaims(uid="test_user", tenant_id="t_abc", roles=["owner"], is_owner=True))
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Create a category
    cat_response = await client.post(
        "/api/v1/blog/categories",
        json={"name": "News", "slug": "news"},
        headers=headers
    )
    assert cat_response.status_code == 200
    category_id = cat_response.json()["id"]
    
    # 2. Create a post
    post_data = {
        "title": "Welcome to KloudShop",
        "slug": "welcome-to-kloudshop",
        "body": '{"type": "doc", "content": []}',
        "status": "published",
        "author_id": "test_user",
        "category_ids": [category_id],
        "tag_names": ["announcement", "retail"]
    }
    
    response = await client.post(
        "/api/v1/blog/posts",
        json=post_data,
        headers=headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Welcome to KloudShop"
    assert len(data["categories"]) == 1
    assert len(data["tags"]) == 2

@pytest.mark.asyncio
async def test_storefront_blog(client: AsyncClient, db_session):
    # Setup: Create brand profile and published post
    tenant_id = "t_store"
    profile = BrandProfile(tenant_id=tenant_id, slug="mystore", brand_name="My Store", is_published=True)
    db_session.add(profile)
    
    post = BlogPost(
        tenant_id=tenant_id,
        title="Public Post",
        slug="public-post",
        status="published",
        author_id="author_1",
        published_at=None
    )
    db_session.add(post)
    await db_session.commit()
    
    # 1. List blog
    response = await client.get(f"/api/v1/storefront/mystore/blog")
    assert response.status_code == 200
    assert len(response.json()) >= 1
    
    # 2. Get single post
    response = await client.get(f"/api/v1/storefront/mystore/blog/public-post")
    assert response.status_code == 200
    assert response.json()["title"] == "Public Post"

@pytest.mark.asyncio
async def test_draft_visibility(client: AsyncClient, db_session):
    # Setup: Draft post should not be visible on storefront
    tenant_id = "t_draft"
    profile = BrandProfile(tenant_id=tenant_id, slug="draftstore", brand_name="Draft Store", is_published=True)
    db_session.add(profile)
    
    post = BlogPost(
        tenant_id=tenant_id,
        title="Draft Post",
        slug="draft-post",
        status="draft",
        author_id="author_1"
    )
    db_session.add(post)
    await db_session.commit()
    
    response = await client.get(f"/api/v1/storefront/draftstore/blog")
    assert response.status_code == 200
    assert len(response.json()) == 0
    
    response = await client.get(f"/api/v1/storefront/draftstore/blog/draft-post")
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_blog_translation(client: AsyncClient, db_session):
    tenant_id = "t_lang"
    profile = BrandProfile(tenant_id=tenant_id, slug="langstore", brand_name="Lang Store", is_published=True, enabled_locales=["en", "fr"])
    db_session.add(profile)
    
    from modules.blog.models import BlogPostTranslation
    post = BlogPost(
        tenant_id=tenant_id,
        title="English Title",
        slug="english-slug",
        status="published",
        author_id="author_1"
    )
    db_session.add(post)
    await db_session.flush()
    
    trans = BlogPostTranslation(
        post_id=post.id,
        locale="fr",
        title="Titre Français",
        slug="titre-francais"
    )
    db_session.add(trans)
    await db_session.commit()
    
    # 1. Get in English (default)
    response = await client.get(f"/api/v1/storefront/langstore/blog/english-slug")
    assert response.status_code == 200
    assert response.json()["title"] == "English Title"
    
    # 2. Get in French (?lang=fr)
    response = await client.get(f"/api/v1/storefront/langstore/blog/english-slug?lang=fr")
    assert response.status_code == 200
    assert response.json()["title"] == "Titre Français"
    
    # 3. Get in French (Header)
    response = await client.get(
        f"/api/v1/storefront/langstore/blog/english-slug",
        headers={"Accept-Language": "fr-FR,fr;q=0.9"}
    )
    assert response.status_code == 200
    assert response.json()["title"] == "Titre Français"
