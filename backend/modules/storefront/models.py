from sqlalchemy import Column, String, Boolean, Text, JSON, DateTime, ForeignKey, Integer, Numeric, Index
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from shared.db import Base

class BrandProfile(Base):
    __tablename__ = "brand_profiles"

    brand_profile_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    storefront_type = Column(String(8), nullable=False, default="dtc")
    brand_name = Column(Text, nullable=False)
    slug = Column(String(63), nullable=False, unique=True)
    logo_url = Column(Text)
    favicon_url = Column(Text)
    primary_color = Column(String(7))
    secondary_color = Column(String(7))
    is_age_gated = Column(Boolean, nullable=False, default=False)
    minimum_age_years_gate = Column(Integer)
    theme_id = Column(String(64))
    active_theme_config_url = Column(Text)
    draft_theme_config_url = Column(Text)
    enabled_locales = Column(JSON, nullable=False, default=["en"]) # Changed from ARRAY
    custom_domain = Column(Text)
    custom_domain_verified = Column(Boolean, nullable=False, default=False)
    timezone = Column(String, nullable=False, default="UTC")
    contact_email = Column(Text)
    social_links = Column(JSON, nullable=False, default={}) # Changed from JSONB
    default_meta_title = Column(Text)
    default_meta_description = Column(Text)
    is_published = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class StorefrontContent(Base):
    __tablename__ = "storefront_content"

    slot_id = Column(String(128), primary_key=True)
    locale = Column(String(8), primary_key=True, default="en")
    tenant_id = Column(String, nullable=False, index=True)
    slot_type = Column(String(16), nullable=False)
    content_value = Column(Text)
    is_auto_translated = Column(Boolean, nullable=False, default=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    updated_by = Column(String) # Changed from UUID

class StaticPage(Base):
    __tablename__ = "static_pages"

    page_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    title = Column(Text, nullable=False)
    slug = Column(String(255), nullable=False)
    body = Column(JSON) # Changed from JSONB
    meta_title = Column(Text)
    meta_description = Column(Text)
    page_type = Column(String(32), nullable=False, default="custom")
    status = Column(String(16), nullable=False, default="draft")
    show_in_nav = Column(Boolean, nullable=False, default=False)
    nav_label = Column(Text)
    created_by = Column(String, nullable=False) # Changed from UUID
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class MerchantCarrierConnection(Base):
    __tablename__ = "merchant_carrier_connections"

    connection_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    carrier_id = Column(String(64), nullable=False, unique=True)
    account_number = Column(Text)
    credentials_secret_ref = Column(Text)
    is_active = Column(Boolean, nullable=False, default=True)
    last_verified_at = Column(DateTime)
    connected_by = Column(String, nullable=False) # Changed from UUID
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class CarrierCheckoutOption(Base):
    __tablename__ = "carrier_checkout_options"

    option_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    service_level_id = Column(String(64), nullable=False, unique=True)
    is_enabled = Column(Boolean, nullable=False, default=True)
    display_name_override = Column(Text)
    handling_markup_type = Column(String(16), nullable=False, default="none")
    handling_markup_value = Column(Numeric(10, 2), nullable=False, default=0.00)
    allowed_destination_countries = Column(JSON, nullable=False, default=[]) # Changed from ARRAY
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
