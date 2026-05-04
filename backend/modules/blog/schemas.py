from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class BlogTranslationBase(BaseModel):
    locale: str
    title: str
    slug: str
    excerpt: Optional[str] = None
    body: Optional[str] = None
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None

class BlogTranslationCreate(BlogTranslationBase):
    pass

class BlogTranslationRead(BlogTranslationBase):
    id: str
    is_auto_translated: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class BlogCategoryBase(BaseModel):
    name: str
    slug: str
    description: Optional[str] = None
    sort_order: int = 0

class BlogCategoryCreate(BlogCategoryBase):
    pass

class BlogCategoryRead(BlogCategoryBase):
    id: str
    tenant_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class BlogTagBase(BaseModel):
    name: str
    slug: str

class BlogTagCreate(BlogTagBase):
    pass

class BlogTagRead(BlogTagBase):
    id: str
    tenant_id: str

    class Config:
        from_attributes = True

class BlogPostBase(BaseModel):
    title: str
    slug: str
    excerpt: Optional[str] = None
    body: Optional[str] = None
    cover_image_url: Optional[str] = None
    cover_image_alt: Optional[str] = None
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None
    status: str = "draft"
    scheduled_for: Optional[datetime] = None
    is_featured: bool = False
    allow_comments: bool = False

class BlogPostCreate(BlogPostBase):
    author_id: str
    category_ids: List[str] = []
    tag_names: List[str] = []

class BlogPostRead(BlogPostBase):
    id: str
    tenant_id: str
    author_id: str
    published_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    categories: List[BlogCategoryRead] = []
    tags: List[BlogTagRead] = []
    translations: List[BlogTranslationRead] = []

    class Config:
        from_attributes = True
