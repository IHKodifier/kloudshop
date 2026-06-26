from sqlalchemy import Column, String, Text, Integer, ForeignKey
from sqlalchemy.orm import relationship
from shared.db import Base
import uuid

class StoreNavigationMenu(Base):
    __tablename__ = "store_navigation_menus"

    menu_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    name = Column(Text, nullable=False)
    handle = Column(String, nullable=False, index=True)

    items = relationship("StoreNavigationItem", back_populates="menu", cascade="all, delete-orphan")

class StoreNavigationItem(Base):
    __tablename__ = "store_navigation_items"

    item_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    menu_id = Column(String, ForeignKey("store_navigation_menus.menu_id", ondelete="CASCADE"), nullable=False)
    tenant_id = Column(String, nullable=False)
    parent_id = Column(String, ForeignKey("store_navigation_items.item_id", ondelete="CASCADE"), nullable=True)
    title = Column(Text, nullable=False)
    url = Column(Text, nullable=False)
    link_type = Column(String(32), nullable=False)  # product / collection / page / policy / custom
    resource_id = Column(String, nullable=True)
    position = Column(Integer, nullable=False, default=0)

    menu = relationship("StoreNavigationMenu", back_populates="items")
    children = relationship("StoreNavigationItem", cascade="all, delete-orphan")
