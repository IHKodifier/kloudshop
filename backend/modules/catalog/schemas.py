# [MODIFY] backend/modules/catalog/schemas.py
# Added VariantUpdate and integrated it into ProductUpdate for full product reconciliation.

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from decimal import Decimal

class VariantBase(BaseModel):
    sku: str
    barcode: Optional[str] = None
    option_1: Optional[str] = None
    option_2: Optional[str] = None
    option_3: Optional[str] = None
    pricing_model: str = "fixed"
    price: Decimal = Field(ge=0)
    compare_at_price: Optional[Decimal] = Field(None, gt=0)
    cost_per_item: Optional[Decimal] = Field(None, ge=0)
    pwyw_minimum_price: Optional[Decimal] = Field(None, ge=0)
    pwyw_suggested_price: Optional[Decimal] = Field(None, ge=0)
    weight_value: Optional[Decimal] = Field(None, ge=0)
    weight_unit: Optional[str] = Field(None, pattern="^(kg|lb)$")
    length_value: Optional[Decimal] = Field(None, ge=0)
    width_value: Optional[Decimal] = Field(None, ge=0)
    height_value: Optional[Decimal] = Field(None, ge=0)
    dimension_unit: Optional[str] = Field(None, pattern="^(cm|in)$")
    ships_in_own_packaging: bool = False
    digital_asset_url: Optional[str] = None
    download_limit: Optional[int] = None
    download_expiry_hours: Optional[int] = None
    is_perishable: bool = False
    best_before_days: Optional[int] = None
    lot_number: Optional[str] = None
    pet_species: List[str] = []
    is_active: bool = True
    requires_shipping: bool = True
    taxable: bool = True
    position: int = 0

class VariantCreate(VariantBase):
    pass

class VariantUpdate(BaseModel):
    variant_id: Optional[str] = None # If provided, update; else create
    sku: Optional[str] = None
    barcode: Optional[str] = None
    option_1: Optional[str] = None
    option_2: Optional[str] = None
    option_3: Optional[str] = None
    pricing_model: Optional[str] = None
    price: Optional[Decimal] = Field(None, ge=0)
    compare_at_price: Optional[Decimal] = Field(None, gt=0)
    cost_per_item: Optional[Decimal] = Field(None, ge=0)
    is_active: Optional[bool] = None
    requires_shipping: Optional[bool] = None
    taxable: Optional[bool] = None
    position: Optional[int] = None

class VariantResponse(VariantBase):
    variant_id: str
    product_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ProductBase(BaseModel):
    title: str
    description: Optional[str] = None
    status: str = Field("draft", pattern="^(draft|active|archived)$")
    slug: str = Field(..., pattern=r"^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$")
    image_url: Optional[str] = None
    images: List[str] = []
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None
    is_digital: bool = False
    in_store_eligible: bool = True
    weight_value: Optional[Decimal] = Field(None, ge=0)
    weight_unit: Optional[str] = Field(None, pattern="^(kg|lb)$")
    length_value: Optional[Decimal] = Field(None, ge=0)
    width_value: Optional[Decimal] = Field(None, ge=0)
    height_value: Optional[Decimal] = Field(None, ge=0)
    dimension_unit: Optional[str] = Field(None, pattern="^(cm|in)$")
    compliance_metadata: Dict[str, Any] = {}
    compliance_document_url: Optional[str] = None
    minimum_age_years: Optional[int] = None
    age_verification_required: bool = False
    requires_prescription: bool = False
    prescription_document_required: bool = False

class ProductCreate(ProductBase):
    variants: List[VariantCreate] = []

class ProductResponse(ProductBase):
    product_id: str
    tenant_id: str
    created_by: str
    created_at: datetime
    updated_at: datetime
    variants: List[VariantResponse] = []

    class Config:
        from_attributes = True

class CollectionBase(BaseModel):
    title: str
    description: Optional[str] = None
    slug: str = Field(..., pattern=r"^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$")
    image_url: Optional[str] = None
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None
    collection_type: str = Field("manual", pattern="^(manual|automated)$")
    sort_type: str = Field("manual", pattern="^(manual|best_selling|price_asc|price_desc|newest|alpha_asc|alpha_desc)$")
    is_visible: bool = True
    position: int = 0

class CollectionCreate(CollectionBase):
    pass

class CollectionUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    slug: Optional[str] = Field(None, pattern=r"^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$")
    image_url: Optional[str] = None
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None
    collection_type: Optional[str] = Field(None, pattern="^(manual|automated)$")
    sort_type: Optional[str] = Field(None, pattern="^(manual|best_selling|price_asc|price_desc|newest|alpha_asc|alpha_desc)$")
    is_visible: Optional[bool] = None
    position: Optional[int] = None

class CollectionResponse(CollectionBase):
    collection_id: str
    tenant_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ProductAssignment(BaseModel):
    product_ids: List[str]

class ImportJobResponse(BaseModel):
    job_id: str
    tenant_id: str
    status: str
    rows_total: int
    rows_processed: int
    rows_failed: int
    error_log: List[Dict[str, Any]]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ProductUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = Field(None, pattern="^(draft|active|archived)$")
    slug: Optional[str] = Field(None, pattern=r"^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$")
    image_url: Optional[str] = None
    images: Optional[List[str]] = None
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None
    is_digital: Optional[bool] = None
    in_store_eligible: Optional[bool] = None
    weight_value: Optional[Decimal] = Field(None, ge=0)
    weight_unit: Optional[str] = Field(None, pattern="^(kg|lb)$")
    length_value: Optional[Decimal] = Field(None, ge=0)
    width_value: Optional[Decimal] = Field(None, ge=0)
    height_value: Optional[Decimal] = Field(None, ge=0)
    dimension_unit: Optional[str] = Field(None, pattern="^(cm|in)$")
    compliance_metadata: Optional[Dict[str, Any]] = None
    compliance_document_url: Optional[str] = None
    minimum_age_years: Optional[int] = None
    age_verification_required: Optional[bool] = None
    requires_prescription: Optional[bool] = None
    prescription_document_required: Optional[bool] = None
    variants: Optional[List[VariantUpdate]] = None

class RedirectRuleResponse(BaseModel):
    rule_id: str
    tenant_id: str
    source_path: str
    destination_path: str
    redirect_type: int
    is_auto_generated: bool
    created_at: datetime

    class Config:
        from_attributes = True
