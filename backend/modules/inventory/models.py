import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, ForeignKey, DateTime, Numeric, Text, CheckConstraint, Index, Date
from sqlalchemy.orm import relationship
from shared.db import Base

class StockLocation(Base):
    __tablename__ = "stock_locations"

    stock_location_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    name = Column(Text, nullable=False)
    location_type = Column(String(16), nullable=False, default="warehouse") # 'warehouse', 'store', '3pl', 'virtual'
    
    # Address
    address_line1 = Column(Text)
    address_line2 = Column(Text)
    city = Column(Text)
    state = Column(Text)
    postcode = Column(Text)
    country_code = Column(String(2)) # ISO 3166-1 alpha-2

    # Fulfilment Capabilities
    fulfils_online = Column(Boolean, nullable=False, default=True)
    fulfils_pos = Column(Boolean, nullable=False, default=False)
    is_default = Column(Boolean, nullable=False, default=False)
    is_active = Column(Boolean, nullable=False, default=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    inventory_items = relationship("Inventory", back_populates="location")
    purchase_orders = relationship("PurchaseOrder", back_populates="receiving_location")

    __table_args__ = (
        CheckConstraint(location_type.in_(['warehouse', 'store', '3pl', 'virtual']), name="stock_locations_type_check"),
    )

class Inventory(Base):
    __tablename__ = "inventory"

    inventory_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    variant_id = Column(String, ForeignKey("variants.variant_id", ondelete="CASCADE"), nullable=False)
    stock_location_id = Column(String, ForeignKey("stock_locations.stock_location_id", ondelete="RESTRICT"), nullable=False)

    quantity_on_hand = Column(Integer, nullable=False, default=0)
    quantity_reserved = Column(Integer, nullable=False, default=0)
    
    reorder_point = Column(Integer)
    reorder_quantity = Column(Integer)

    last_received_at = Column(DateTime)
    last_sold_at = Column(DateTime)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    location = relationship("StockLocation", back_populates="inventory_items")
    variant = relationship("Variant", back_populates="inventory_items")

    __table_args__ = (
        CheckConstraint(quantity_on_hand >= 0, name="inventory_on_hand_non_negative"),
        CheckConstraint(quantity_reserved >= 0, name="inventory_reserved_non_negative"),
        Index("idx_inventory_variant_location", "variant_id", "stock_location_id", unique=True),
    )

class Supplier(Base):
    __tablename__ = "suppliers"

    supplier_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    name = Column(Text, nullable=False)
    contact_name = Column(Text)
    contact_email = Column(String(255))
    contact_phone = Column(String(32))
    
    address_line1 = Column(Text)
    address_line2 = Column(Text)
    city = Column(Text)
    state = Column(Text)
    postcode = Column(Text)
    country_code = Column(String(2))
    
    payment_terms = Column(Text)
    default_lead_time_days = Column(Integer)
    currency = Column(String(3), nullable=False, default="USD")
    
    status = Column(String(16), nullable=False, default="active") # 'active', 'inactive', 'archived'
    notes = Column(Text)
    
    created_by = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    purchase_orders = relationship("PurchaseOrder", back_populates="supplier")
    performance_events = relationship("SupplierPerformanceEvent", back_populates="supplier")

    __table_args__ = (
        CheckConstraint(status.in_(['active', 'inactive', 'archived']), name="suppliers_status_check"),
    )

class PurchaseOrder(Base):
    __tablename__ = "purchase_orders"

    po_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    po_number = Column(String(32), unique=True, nullable=False)
    tenant_id = Column(String, nullable=False, index=True)
    
    supplier_id = Column(String, ForeignKey("suppliers.supplier_id", ondelete="RESTRICT"), nullable=False)
    status = Column(String(16), nullable=False, default="draft") # 'draft', 'sent', 'acknowledged', 'partial', 'received', 'cancelled'
    
    receiving_location_id = Column(String, ForeignKey("stock_locations.stock_location_id", ondelete="RESTRICT"))
    
    ordered_at = Column(DateTime)
    expected_delivery_at = Column(DateTime)
    received_at = Column(DateTime)
    cancelled_at = Column(DateTime)
    
    total_cost = Column(Numeric(14, 4))
    total_cost_currency = Column(String(3))
    
    notes = Column(Text)
    sent_by = Column(String)
    created_by = Column(String, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    supplier = relationship("Supplier", back_populates="purchase_orders")
    receiving_location = relationship("StockLocation", back_populates="purchase_orders")
    lines = relationship("PurchaseOrderLine", back_populates="po", cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint(status.in_(['draft', 'sent', 'acknowledged', 'partial', 'received', 'cancelled']), name="purchase_orders_status_check"),
    )

class PurchaseOrderLine(Base):
    __tablename__ = "purchase_order_lines"

    po_line_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    po_id = Column(String, ForeignKey("purchase_orders.po_id", ondelete="CASCADE"), nullable=False)
    variant_id = Column(String, ForeignKey("variants.variant_id", ondelete="RESTRICT"), nullable=False)
    
    quantity_ordered = Column(Integer, nullable=False)
    quantity_received = Column(Integer)
    
    unit_cost = Column(Numeric(12, 4))
    unit_cost_currency = Column(String(3))
    
    received_at = Column(DateTime)
    manufacture_date = Column(Date)
    
    discrepancy_flag = Column(Boolean, nullable=False, default=False)
    discrepancy_notes = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    po = relationship("PurchaseOrder", back_populates="lines")
    variant = relationship("Variant")

class SupplierPerformanceEvent(Base):
    __tablename__ = "supplier_performance_events"

    event_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    supplier_id = Column(String, ForeignKey("suppliers.supplier_id", ondelete="RESTRICT"), nullable=False)
    po_id = Column(String, ForeignKey("purchase_orders.po_id", ondelete="RESTRICT"))
    
    event_type = Column(String(32), nullable=False)
    severity = Column(String(16)) # 'minor', 'moderate', 'severe'
    notes = Column(Text)
    
    logged_by = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    supplier = relationship("Supplier", back_populates="performance_events")

class StockTransfer(Base):
    __tablename__ = "stock_transfers"

    transfer_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    source_location_id = Column(String, ForeignKey("stock_locations.stock_location_id", ondelete="RESTRICT"), nullable=False)
    destination_location_id = Column(String, ForeignKey("stock_locations.stock_location_id", ondelete="RESTRICT"), nullable=False)
    
    variant_id = Column(String, ForeignKey("variants.variant_id", ondelete="RESTRICT"), nullable=False)
    quantity_transferred = Column(Integer, nullable=False)
    quantity_received = Column(Integer)
    
    status = Column(String(16), nullable=False, default="draft") # 'draft', 'in_transit', 'received', 'cancelled'
    
    initiated_by = Column(String)
    initiated_at = Column(DateTime)
    received_by = Column(String)
    received_at = Column(DateTime)
    
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        CheckConstraint(source_location_id != destination_location_id, name="stock_transfers_different_locations"),
        CheckConstraint(status.in_(['draft', 'in_transit', 'received', 'cancelled']), name="stock_transfers_status_check"),
    )

class PackagingPreset(Base):
    __tablename__ = "packaging_presets"

    preset_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    name = Column(Text, nullable=False)
    
    length_value = Column(Numeric(10, 2), nullable=False)
    width_value = Column(Numeric(10, 2), nullable=False)
    height_value = Column(Numeric(10, 2), nullable=False)
    dimension_unit = Column(String(4), nullable=False, default="cm")
    
    max_weight_value = Column(Numeric(10, 3), nullable=False)
    max_weight_unit = Column(String(4), nullable=False, default="kg")
    
    is_default = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class SupplierScoreWeights(Base):
    __tablename__ = "supplier_score_weights"

    weights_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    on_time_weight = Column(Numeric(4, 2), nullable=False, default=0.35)
    fill_rate_weight = Column(Numeric(4, 2), nullable=False, default=0.25)
    quality_weight = Column(Numeric(4, 2), nullable=False, default=0.25)
    price_stability_weight = Column(Numeric(4, 2), nullable=False, default=0.15)
    
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class ShippingSettings(Base):
    __tablename__ = "shipping_settings"

    settings_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    default_dimension_unit = Column(String(4), nullable=False, default="cm")
    default_weight_unit = Column(String(4), nullable=False, default="kg")
    
    handling_days = Column(Integer, nullable=False, default=1)
    order_cutoff_time = Column(String(5)) # e.g. "14:00"
    
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
