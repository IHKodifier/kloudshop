from sqlalchemy import Column, String, Text, Boolean, Numeric, ForeignKey, JSON
from sqlalchemy.orm import relationship
from shared.db import Base
import uuid

class StoreShippingProfile(Base):
    __tablename__ = "store_shipping_profiles"

    profile_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    name = Column(Text, nullable=False)
    is_general = Column(Boolean, nullable=False, default=False)

    zones = relationship("StoreShippingZone", back_populates="profile", cascade="all, delete-orphan")

class StoreShippingZone(Base):
    __tablename__ = "store_shipping_zones"

    zone_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    profile_id = Column(String, ForeignKey("store_shipping_profiles.profile_id", ondelete="CASCADE"), nullable=False)
    tenant_id = Column(String, nullable=False)
    name = Column(Text, nullable=False)
    countries = Column(JSON, nullable=False, default=[]) # List of country codes, e.g. ["US", "CA"]

    profile = relationship("StoreShippingProfile", back_populates="zones")
    rates = relationship("StoreShippingRate", back_populates="zone", cascade="all, delete-orphan")

class StoreShippingRate(Base):
    __tablename__ = "store_shipping_rates"

    rate_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    zone_id = Column(String, ForeignKey("store_shipping_zones.zone_id", ondelete="CASCADE"), nullable=False)
    tenant_id = Column(String, nullable=False)
    name = Column(Text, nullable=False)
    price = Column(Numeric(12, 2), nullable=False, default=0.0)
    
    # Conditional thresholds
    min_value = Column(Numeric(12, 2), nullable=True)
    max_value = Column(Numeric(12, 2), nullable=True)
    min_weight = Column(Numeric(10, 3), nullable=True)
    max_weight = Column(Numeric(10, 3), nullable=True)
    
    # flat | weight_based | price_based
    rate_type = Column(String(32), nullable=False, default="flat")

    zone = relationship("StoreShippingZone", back_populates="rates")
