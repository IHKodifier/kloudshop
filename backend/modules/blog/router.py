from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from sqlalchemy.orm import selectinload
from shared.db import get_db
from shared.auth import UserClaims
from shared.rbac import has_permissions
from . import models, schemas
from typing import List, Optional, Any
from datetime import datetime, timezone

router = APIRouter(tags=["Blog Admin"])

# --- Categories ---

@router.get("/categories", response_model=List[schemas.BlogCategoryRead])
async def list_categories(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["blog:manage"])
):
    result = await db.execute(
        select(models.BlogCategory).filter(models.BlogCategory.tenant_id == user.tenant_id).order_by(models.BlogCategory.sort_order, models.BlogCategory.name)
    )
    return result.scalars().all()

@router.post("/categories", response_model=schemas.BlogCategoryRead)
async def create_category(
    category: schemas.BlogCategoryCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["blog:manage"])
):
    db_category = models.BlogCategory(**category.model_dump(), tenant_id=user.tenant_id)
    db.add(db_category)
    await db.commit()
    await db.refresh(db_category)
    return db_category

# --- Tags ---

@router.get("/tags", response_model=List[schemas.BlogTagRead])
async def list_tags(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["blog:manage"])
):
    result = await db.execute(
        select(models.BlogTag).filter(models.BlogTag.tenant_id == user.tenant_id)
    )
    return result.scalars().all()

# --- Posts ---

@router.get("/posts", response_model=List[schemas.BlogPostRead])
async def list_posts(
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["blog:manage"])
):
    query = select(models.BlogPost).options(
        selectinload(models.BlogPost.categories),
        selectinload(models.BlogPost.tags),
        selectinload(models.BlogPost.translations)
    ).filter(models.BlogPost.tenant_id == user.tenant_id)
    
    if status:
        query = query.filter(models.BlogPost.status == status)
        
    result = await db.execute(query.order_by(models.BlogPost.created_at.desc()))
    return result.scalars().all()

@router.post("/posts", response_model=schemas.BlogPostRead)
async def create_post(
    post: schemas.BlogPostCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["blog:manage"])
):
    # Extract IDs and names
    category_ids = post.category_ids
    tag_names = post.tag_names
    
    # Create the post object without related IDs in the main constructor
    post_data = post.model_dump(exclude={"category_ids", "tag_names"})
    
    # Auto-populate author_id from authenticated user if not provided
    if not post_data.get("author_id"):
        post_data["author_id"] = user.uid
        
    db_post = models.BlogPost(**post_data, tenant_id=user.tenant_id)
    
    # Associate categories
    if category_ids:
        res = await db.execute(select(models.BlogCategory).filter(models.BlogCategory.id.in_(category_ids)))
        db_post.categories = res.scalars().all()
        
    # Associate tags (create if not exist)
    if tag_names:
        for tag_name in tag_names:
            tag_slug = tag_name.lower().replace(" ", "-") # Simple slugify
            res = await db.execute(select(models.BlogTag).filter(models.BlogTag.tenant_id == user.tenant_id, models.BlogTag.name == tag_name))
            db_tag = res.scalar_one_or_none()
            if not db_tag:
                db_tag = models.BlogTag(tenant_id=user.tenant_id, name=tag_name, slug=tag_slug)
                db.add(db_tag)
            db_post.tags.append(db_tag)
            
    db.add(db_post)
    await db.commit()
    
    # Re-fetch with relations to satisfy the Pydantic schema
    result = await db.execute(
        select(models.BlogPost).options(
            selectinload(models.BlogPost.categories),
            selectinload(models.BlogPost.tags),
            selectinload(models.BlogPost.translations)
        ).filter(models.BlogPost.id == db_post.id)
    )
    return result.scalar_one()

@router.get("/posts/{post_id}", response_model=schemas.BlogPostRead)
async def get_post(
    post_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["blog:manage"])
):
    result = await db.execute(
        select(models.BlogPost).options(
            selectinload(models.BlogPost.categories),
            selectinload(models.BlogPost.tags),
            selectinload(models.BlogPost.translations)
        ).filter(models.BlogPost.id == post_id, models.BlogPost.tenant_id == user.tenant_id)
    )
    db_post = result.scalar_one_or_none()
    if not db_post:
        raise HTTPException(status_code=404, detail="Post not found")
    return db_post

@router.put("/posts/{post_id}", response_model=schemas.BlogPostRead)
@router.patch("/posts/{post_id}", response_model=schemas.BlogPostRead)
async def update_post(
    post_id: str,
    post_update: schemas.BlogPostUpdate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["blog:manage"])
):
    result = await db.execute(
        select(models.BlogPost).options(
            selectinload(models.BlogPost.categories),
            selectinload(models.BlogPost.tags)
        ).filter(models.BlogPost.id == post_id, models.BlogPost.tenant_id == user.tenant_id)
    )
    db_post = result.scalar_one_or_none()
    if not db_post:
        raise HTTPException(status_code=404, detail="Post not found")
        
    update_data = post_update.model_dump(exclude_unset=True, exclude={"category_ids", "tag_names"})
    
    # Apply standard fields
    for key, value in update_data.items():
        setattr(db_post, key, value)
        
    # Update categories if provided
    if post_update.category_ids is not None:
        res = await db.execute(select(models.BlogCategory).filter(models.BlogCategory.id.in_(post_update.category_ids)))
        db_post.categories = res.scalars().all()
        
    # Update tags if provided
    if post_update.tag_names is not None:
        db_post.tags = [] # Clear existing
        for tag_name in post_update.tag_names:
            tag_slug = tag_name.lower().replace(" ", "-")
            res = await db.execute(select(models.BlogTag).filter(models.BlogTag.tenant_id == user.tenant_id, models.BlogTag.name == tag_name))
            db_tag = res.scalar_one_or_none()
            if not db_tag:
                db_tag = models.BlogTag(tenant_id=user.tenant_id, name=tag_name, slug=tag_slug)
                db.add(db_tag)
            db_post.tags.append(db_tag)
            
    db_post.updated_at = datetime.now(timezone.utc)
    await db.commit()
    
    # Re-fetch with all relations
    result = await db.execute(
        select(models.BlogPost).options(
            selectinload(models.BlogPost.categories),
            selectinload(models.BlogPost.tags),
            selectinload(models.BlogPost.translations)
        ).filter(models.BlogPost.id == post_id)
    )
    return result.scalar_one()

@router.delete("/posts/{post_id}")
async def delete_post(
    post_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["blog:manage"])
):
    result = await db.execute(
        select(models.BlogPost).filter(models.BlogPost.id == post_id, models.BlogPost.tenant_id == user.tenant_id)
    )
    db_post = result.scalar_one_or_none()
    if not db_post:
        raise HTTPException(status_code=404, detail="Post not found")
        
    await db.delete(db_post)
    await db.commit()
    return {"message": "Post deleted successfully"}
