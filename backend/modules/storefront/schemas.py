from pydantic import BaseModel, ConfigDict, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from uuid import UUID

# --- Brand Profile ---

class BrandProfileBase(BaseModel):
    brand_name: str
    slug: str
    logo_url: Optional[str] = None
    favicon_url: Optional[str] = None
    primary_color: Optional[str] = None
    secondary_color: Optional[str] = None
    is_age_gated: bool = False
    minimum_age_years_gate: Optional[int] = None
    enabled_locales: List[str] = ["en"]
    timezone: str = "UTC"
    contact_email: Optional[str] = None
    social_links: Dict[str, str] = {}
    default_meta_title: Optional[str] = None
    default_meta_description: Optional[str] = None

class BrandProfileCreate(BrandProfileBase):
    storefront_type: str = "dtc"

class BrandProfileUpdate(BaseModel):
    brand_name: Optional[str] = None
    logo_url: Optional[str] = None
    favicon_url: Optional[str] = None
    primary_color: Optional[str] = None
    secondary_color: Optional[str] = None
    is_age_gated: Optional[bool] = None
    minimum_age_years_gate: Optional[int] = None
    enabled_locales: Optional[List[str]] = None
    timezone: Optional[str] = None
    contact_email: Optional[str] = None
    social_links: Optional[Dict[str, str]] = None
    default_meta_title: Optional[str] = None
    default_meta_description: Optional[str] = None
    is_published: Optional[bool] = None

class BrandProfileResponse(BrandProfileBase):
    brand_profile_id: UUID
    storefront_type: str
    is_published: bool
    theme_id: Optional[str] = None
    active_theme_config_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- Storefront Content ---

class StorefrontContentBase(BaseModel):
    slot_id: str
    locale: str = "en"
    slot_type: str
    content_value: Optional[str] = None

class StorefrontContentCreate(StorefrontContentBase):
    pass

class StorefrontContentResponse(StorefrontContentBase):
    is_auto_translated: bool
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- Static Pages ---

class StaticPageBase(BaseModel):
    title: str
    slug: str
    body: Optional[Dict[str, Any]] = None
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None
    page_type: str = "custom"
    status: str = "draft"
    show_in_nav: bool = False
    nav_label: Optional[str] = None

class StaticPageCreate(StaticPageBase):
    pass

class StaticPageUpdate(BaseModel):
    title: Optional[str] = None
    slug: Optional[str] = None
    body: Optional[Dict[str, Any]] = None
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None
    page_type: Optional[str] = None
    status: Optional[str] = None
    show_in_nav: Optional[bool] = None
    nav_label: Optional[str] = None

class StaticPageResponse(StaticPageBase):
    page_id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- Shipping ---

class CarrierConnectionBase(BaseModel):
    carrier_id: str
    account_number: Optional[str] = None
    is_active: bool = True

class CarrierConnectionCreate(CarrierConnectionBase):
    credentials_secret_ref: Optional[str] = None

class CarrierConnectionResponse(CarrierConnectionBase):
    connection_id: UUID
    last_verified_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class CheckoutOptionBase(BaseModel):
    service_level_id: str
    is_enabled: bool = True
    display_name_override: Optional[str] = None
    handling_markup_type: str = "none"
    handling_markup_value: float = 0.0

class CheckoutOptionCreate(CheckoutOptionBase):
    allowed_destination_countries: List[str] = []

class CheckoutOptionResponse(CheckoutOptionBase):
    option_id: UUID
    allowed_destination_countries: List[str]
    
    model_config = ConfigDict(from_attributes=True)

class ShippingRateRequest(BaseModel):
    country: str
    postcode: Optional[str] = None
    items: List[Dict[str, Any]] # variant_id, quantity

class ShippingRateResponse(BaseModel):
    service_level_id: str
    display_name: str
    rate: float
    currency: str
    estimated_days: Optional[int] = None
