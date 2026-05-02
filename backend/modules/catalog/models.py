from sqlalchemy import Column, String, Text, Boolean, Integer, SmallInteger, Numeric, DateTime, JSON, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from shared.db import Base, engine
import uuid
from datetime import datetime

# Schema name for platform-wide tables (not used for tenant tables in SQLite mode)
SCHEMA = "kloudshop_platform" if "sqlite" not in engine.url.drivername else None

class Product(Base):
    __tablename__ = "products"

    product_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    # Identity & Content
    title = Column(Text, nullable=False)
    description = Column(Text)
    
    # Status
    status = Column(String(16), nullable=False, default='draft') # draft | active | archived
    
    # SEO
    slug = Column(String(255), nullable=False)
    meta_title = Column(Text)
    meta_description = Column(Text)
    
    # Flags
    is_digital = Column(Boolean, nullable=False, default=False)
    in_store_eligible = Column(Boolean, nullable=False, default=True)
    
    # Shipping Fallbacks
    weight_value = Column(Numeric(10, 3))
    weight_unit = Column(String(4)) # kg | lb
    length_value = Column(Numeric(10, 2))
    width_value = Column(Numeric(10, 2))
    height_value = Column(Numeric(10, 2))
    dimension_unit = Column(String(4)) # cm | in
    
    # Compliance & Regulatory
    compliance_metadata = Column(JSON, nullable=False, default={})
    compliance_document_url = Column(Text)
    
    # Age Restriction
    minimum_age_years = Column(SmallInteger)
    age_verification_required = Column(Boolean, nullable=False, default=False)
    
    # Prescription / Controlled Products
    requires_prescription = Column(Boolean, nullable=False, default=False)
    prescription_document_required = Column(Boolean, nullable=False, default=False)
    
    # AI Semantic Search (Skipped pgvector for SQLite compatibility)
    # embedding = Column(...)
    
    # Metadata
    created_by = Column(String, nullable=False) # staff_user_id
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    variants = relationship("Variant", back_populates="product", cascade="all, delete-orphan")
    collections = relationship("Collection", secondary="collection_products", back_populates="products")

    __table_args__ = (
        CheckConstraint(status.in_(['draft', 'active', 'archived']), name='products_status_check'),
        CheckConstraint(weight_unit.in_(['kg', 'lb']), name='products_weight_unit_check'),
        CheckConstraint(dimension_unit.in_(['cm', 'in']), name='products_dimension_unit_check'),
        CheckConstraint('NOT (prescription_document_required = 1 AND requires_prescription = 0)', name='products_prescription_logic'),
        CheckConstraint('minimum_age_years IS NULL OR minimum_age_years > 0', name='products_minimum_age_positive'),
    )

class Variant(Base):
    __tablename__ = "variants"

    variant_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    product_id = Column(String, ForeignKey("products.product_id", ondelete="CASCADE"), nullable=False)
    tenant_id = Column(String, nullable=False, index=True)
    
    # Identity
    sku = Column(String(255), nullable=False, unique=True)
    barcode = Column(String(128))
    
    # Options
    option_1 = Column(Text)
    option_2 = Column(Text)
    option_3 = Column(Text)
    
    # Pricing Model
    pricing_model = Column(String(16), nullable=False, default='fixed') # fixed | pwyw | donation
    
    # Pricing
    price = Column(Numeric(12, 2), nullable=False)
    compare_at_price = Column(Numeric(12, 2))
    cost_per_item = Column(Numeric(12, 2))
    
    # PWYW Fields
    pwyw_minimum_price = Column(Numeric(10, 2))
    pwyw_suggested_price = Column(Numeric(10, 2))
    
    # Shipping Attributes
    weight_value = Column(Numeric(10, 3))
    weight_unit = Column(String(4))
    length_value = Column(Numeric(10, 2))
    width_value = Column(Numeric(10, 2))
    height_value = Column(Numeric(10, 2))
    dimension_unit = Column(String(4))
    ships_in_own_packaging = Column(Boolean, nullable=False, default=False)
    
    # Digital Asset Delivery
    digital_asset_url = Column(Text)
    download_limit = Column(Integer)
    download_expiry_hours = Column(Integer)
    
    # Perishable / Batch Tracking
    is_perishable = Column(Boolean, nullable=False, default=False)
    best_before_days = Column(Integer)
    lot_number = Column(Text)
    
    # Pet Species
    pet_species = Column(JSON, nullable=False, default=[]) # Stored as list in JSON
    
    # Flags
    is_active = Column(Boolean, nullable=False, default=True)
    requires_shipping = Column(Boolean, nullable=False, default=True)
    taxable = Column(Boolean, nullable=False, default=True)
    
    # Metadata
    position = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    product = relationship("Product", back_populates="variants")
    inventory_items = relationship("Inventory", back_populates="variant", cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint(pricing_model.in_(['fixed', 'pwyw', 'donation']), name='variants_pricing_model_check'),
        CheckConstraint(price >= 0, name='variants_price_non_negative'),
        CheckConstraint(weight_unit.in_(['kg', 'lb']), name='variants_weight_unit_check'),
        CheckConstraint(dimension_unit.in_(['cm', 'in']), name='variants_dimension_unit_check'),
        CheckConstraint("pricing_model = 'fixed' OR compare_at_price IS NULL", name='variants_pwyw_no_compare_at'),
        CheckConstraint("digital_asset_url IS NOT NULL OR (download_limit IS NULL AND download_expiry_hours IS NULL)", name='variants_download_fields_require_digital'),
        CheckConstraint("is_perishable = 1 OR best_before_days IS NULL", name='variants_perishable_logic'),
        CheckConstraint("pwyw_minimum_price IS NULL OR pwyw_minimum_price >= 0", name='variants_pwyw_minimum_non_negative'),
        CheckConstraint("pricing_model IN ('pwyw', 'donation') OR (pwyw_minimum_price IS NULL AND pwyw_suggested_price IS NULL)", name='variants_pwyw_fields_require_pwyw_model'),
        CheckConstraint("compare_at_price IS NULL OR compare_at_price > price", name='variants_compare_at_price_check'),
    )

class Collection(Base):
    __tablename__ = "collections"

    collection_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)

    title = Column(Text, nullable=False)
    description = Column(Text)
    slug = Column(String(255), nullable=False, unique=True)
    image_url = Column(Text)
    meta_title = Column(Text)
    meta_description = Column(Text)

    collection_type = Column(String(16), nullable=False, default='manual') # manual | automated
    sort_type = Column(String(16), nullable=False, default='manual') 
    # manual | best_selling | price_asc | price_desc | newest | alpha_asc | alpha_desc

    is_visible = Column(Boolean, nullable=False, default=True)
    position = Column(Integer, nullable=False, default=0)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    products = relationship("Product", secondary="collection_products", back_populates="collections")

    __table_args__ = (
        CheckConstraint(collection_type.in_(['manual', 'automated']), name='collections_type_check'),
        CheckConstraint(sort_type.in_([
            'manual', 'best_selling', 'price_asc', 'price_desc',
            'newest', 'alpha_asc', 'alpha_desc'
        ]), name='collections_sort_type_check'),
    )

class CollectionProduct(Base):
    __tablename__ = "collection_products"

    collection_id = Column(String, ForeignKey("collections.collection_id", ondelete="CASCADE"), primary_key=True)
    product_id = Column(String, ForeignKey("products.product_id", ondelete="CASCADE"), primary_key=True)
    sort_order = Column(Integer, nullable=False, default=0)
    added_at = Column(DateTime, default=datetime.utcnow)

class ImportJob(Base):
    __tablename__ = "import_jobs"

    job_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    status = Column(String(16), nullable=False, default='pending') # pending | processing | completed | failed
    rows_total = Column(Integer, default=0)
    rows_processed = Column(Integer, default=0)
    rows_failed = Column(Integer, default=0)
    
    error_log = Column(JSON, default=[]) # List of {row: N, error: "msg"}
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class RedirectRule(Base):
    __tablename__ = "redirect_rules"

    rule_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)

    source_path = Column(Text, nullable=False)
    destination_path = Column(Text, nullable=False)
    redirect_type = Column(SmallInteger, nullable=False, default=301)
    is_auto_generated = Column(Boolean, nullable=False, default=False)

    created_by = Column(String) # staff_user_id
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint(redirect_type.in_([301, 302]), name='redirect_rules_type_check'),
        CheckConstraint("source_path LIKE '/%'", name='redirect_rules_source_starts_with_slash'),
        CheckConstraint("source_path != destination_path", name='redirect_rules_no_self_redirect'),
    )
