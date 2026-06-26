from pydantic import BaseModel, Field
from typing import List, Optional

class NavigationItemBase(BaseModel):
    title: str
    url: str
    link_type: str  # product / collection / page / policy / custom
    resource_id: Optional[str] = None
    position: int = 0
    parent_id: Optional[str] = None

class NavigationItemCreate(NavigationItemBase):
    pass

class NavigationItemResponse(NavigationItemBase):
    item_id: str
    menu_id: str
    tenant_id: str

    class Config:
        from_attributes = True

# Nested Item representation for tree hierarchy responses
class NavigationItemTreeResponse(NavigationItemResponse):
    children: List['NavigationItemTreeResponse'] = Field(default_factory=list)

    class Config:
        from_attributes = True

class NavigationMenuBase(BaseModel):
    name: str
    handle: str

class NavigationMenuCreate(NavigationMenuBase):
    pass

class NavigationMenuResponse(NavigationMenuBase):
    menu_id: str
    tenant_id: str
    items: List[NavigationItemTreeResponse] = Field(default_factory=list)

    class Config:
        from_attributes = True

# Reordering request schemas
class NavigationReorderItem(BaseModel):
    item_id: str
    parent_id: Optional[str] = None
    position: int

class NavigationReorderRequest(BaseModel):
    items: List[NavigationReorderItem]

# Resolution schema
class LinkResolveResponse(BaseModel):
    relative_url: str
    title: str
