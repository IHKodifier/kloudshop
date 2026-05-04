import uuid
from datetime import datetime
from typing import List, Optional
from sqlalchemy import Column, String, Text, Boolean, Integer, DateTime, ForeignKey, Table, CheckConstraint
from sqlalchemy.orm import relationship
from shared.db import Base, engine

# Schema detection
IS_SQLITE = "sqlite" in engine.url.drivername

class BlogPost(Base):
    __tablename__ = "blog_posts"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    author_id = Column(String, nullable=False) # Ref to staff_users
    
    title = Column(String(500), nullable=False)
    slug = Column(String(500), nullable=False, unique=True)
    excerpt = Column(String(1000))
    body = Column(Text) # Tiptap JSON string (PostgreSQL uses JSONB, but Text is safe for SQLite/Universal)
    
    cover_image_url = Column(Text)
    cover_image_alt = Column(String(500))
    
    meta_title = Column(String(120))
    meta_description = Column(String(320))
    
    status = Column(String(20), nullable=False, default='draft') # draft, scheduled, published, archived
    scheduled_for = Column(DateTime)
    published_at = Column(DateTime)
    
    is_featured = Column(Boolean, nullable=False, default=False)
    allow_comments = Column(Boolean, nullable=False, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    categories = relationship("BlogCategory", secondary="blog_post_categories", back_populates="posts")
    tags = relationship("BlogTag", secondary="blog_post_tags", back_populates="posts")
    translations = relationship("BlogPostTranslation", back_populates="post", cascade="all, delete-orphan")

class BlogPostTranslation(Base):
    __tablename__ = "blog_post_translations"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    post_id = Column(String, ForeignKey("blog_posts.id", ondelete="CASCADE"), nullable=False)
    locale = Column(String(10), nullable=False) # e.g. 'fr', 'es'
    
    title = Column(String(500), nullable=False)
    slug = Column(String(500), nullable=False)
    excerpt = Column(String(1000))
    body = Column(Text)
    
    meta_title = Column(String(120))
    meta_description = Column(String(320))
    
    is_auto_translated = Column(Boolean, nullable=False, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    post = relationship("BlogPost", back_populates="translations")

class BlogCategory(Base):
    __tablename__ = "blog_categories"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    name = Column(String(200), nullable=False)
    slug = Column(String(200), nullable=False)
    description = Column(String(1000))
    sort_order = Column(Integer, nullable=False, default=0)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    posts = relationship("BlogPost", secondary="blog_post_categories", back_populates="categories")
    translations = relationship("BlogCategoryTranslation", back_populates="category", cascade="all, delete-orphan")

class BlogCategoryTranslation(Base):
    __tablename__ = "blog_category_translations"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    category_id = Column(String, ForeignKey("blog_categories.id", ondelete="CASCADE"), nullable=False)
    locale = Column(String(10), nullable=False)
    
    name = Column(String(200), nullable=False)
    slug = Column(String(200), nullable=False)
    description = Column(String(1000))
    
    is_auto_translated = Column(Boolean, nullable=False, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    category = relationship("BlogCategory", back_populates="translations")

class BlogTag(Base):
    __tablename__ = "blog_tags"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    name = Column(String(100), nullable=False)
    slug = Column(String(100), nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    posts = relationship("BlogPost", secondary="blog_post_tags", back_populates="tags")

# Join Tables
blog_post_categories = Table(
    "blog_post_categories",
    Base.metadata,
    Column("post_id", String, ForeignKey("blog_posts.id", ondelete="CASCADE"), primary_key=True),
    Column("category_id", String, ForeignKey("blog_categories.id", ondelete="CASCADE"), primary_key=True)
)

blog_post_tags = Table(
    "blog_post_tags",
    Base.metadata,
    Column("post_id", String, ForeignKey("blog_posts.id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", String, ForeignKey("blog_tags.id", ondelete="CASCADE"), primary_key=True)
)
