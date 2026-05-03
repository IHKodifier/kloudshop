import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, ForeignKey, DateTime, Numeric, Text, CheckConstraint, Index
from sqlalchemy.orm import relationship
from shared.db import Base

# StockLocation and Inventory moved to modules.inventory.models

class Order(Base):
    __tablename__ = "orders"

    order_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    order_number = Column(String(32), unique=True, nullable=False) # e.g. KS-1001
    tenant_id = Column(String, nullable=False, index=True)
    
    consumer_id = Column(String) # NULL for guest
    email = Column(String(255), nullable=False)
    
    payment_status = Column(String(16), nullable=False, default="pending")
    fulfilment_status = Column(String(24), nullable=False, default="unfulfilled")
    
    # Financials (Denormalized snapshots)
    currency = Column(String(3), nullable=False, default="USD")
    subtotal = Column(Numeric(12, 2), nullable=False)
    tax_total = Column(Numeric(12, 2), nullable=False, default=0)
    shipping_total = Column(Numeric(12, 2), nullable=False, default=0)
    grand_total = Column(Numeric(12, 2), nullable=False)
    
    # Shipping Address
    shipping_name = Column(Text)
    shipping_address1 = Column(Text)
    shipping_address2 = Column(Text)
    shipping_city = Column(Text)
    shipping_state = Column(Text)
    shipping_postcode = Column(Text)
    shipping_country = Column(String(2))
    
    # Stripe reference
    stripe_payment_intent_id = Column(String(255))
    
    # B2B Specifics
    b2b_account_id = Column(String, index=True)
    b2b_approval_status = Column(String(16), default="not_applicable") # pending | approved | declined | not_applicable
    
    placed_at = Column(DateTime, default=datetime.utcnow)
    cancelled_at = Column(DateTime)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    events = relationship("OrderEvent", back_populates="order", cascade="all, delete-orphan")
    notes = relationship("OrderNote", back_populates="order", cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint(payment_status.in_(['pending', 'paid', 'failed', 'refunded', 'partially_refunded', 'voided']), name='orders_payment_status_check'),
        CheckConstraint(fulfilment_status.in_(['unfulfilled', 'partially_fulfilled', 'fulfilled', 'delivered', 'cancelled', 'returned']), name='orders_fulfilment_status_check'),
    )

class OrderItem(Base):
    __tablename__ = "order_items"

    order_item_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = Column(String, ForeignKey("orders.order_id", ondelete="CASCADE"), nullable=False)
    
    variant_id = Column(String, nullable=False)
    product_id = Column(String, nullable=False)
    
    # Snapshots
    title = Column(Text, nullable=False) # Product + Variant name
    sku = Column(String(64))
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Numeric(12, 2), nullable=False)
    total_price = Column(Numeric(12, 2), nullable=False)
    tax_amount = Column(Numeric(12, 2), nullable=False, default=0)
    taxable = Column(Boolean, nullable=False, default=True)
    is_digital = Column(Boolean, nullable=False, default=False)

    order = relationship("Order", back_populates="items")

class OrderEvent(Base):
    __tablename__ = "order_events"

    event_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = Column(String, ForeignKey("orders.order_id", ondelete="CASCADE"), nullable=False)
    
    event_type = Column(String(32), nullable=False) # e.g. 'payment_confirmed', 'shipped'
    description = Column(Text)
    actor_id = Column(String) # staff or consumer
    
    created_at = Column(DateTime, default=datetime.utcnow)

    order = relationship("Order", back_populates="events")

class OrderNote(Base):
    __tablename__ = "order_notes"

    note_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = Column(String, ForeignKey("orders.order_id", ondelete="CASCADE"), nullable=False)
    
    author_id = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    is_customer_visible = Column(Boolean, nullable=False, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)

    order = relationship("Order", back_populates="notes")
