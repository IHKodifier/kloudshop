from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

class InvitationCreate(BaseModel):
    email: EmailStr
    roles: List[str]

class InvitationResponse(BaseModel):
    id: str
    email: EmailStr
    tenant_id: str
    roles: List[str]
    invited_by: str
    created_at: datetime
    accepted_at: Optional[datetime] = None
    is_cancelled: bool

class RoleUpdate(BaseModel):
    roles: List[str]

class StaffMember(BaseModel):
    uid: str
    email: str
    roles: List[str]
    is_owner: bool

class OwnershipTransferRequest(BaseModel):
    new_owner_uid: str

class B2BBuyerRegistration(BaseModel):
    invite_token: str
    password: str
    display_name: Optional[str] = None

class ConsumerRegistration(BaseModel):
    email: EmailStr
    password: str
    tenant_id: str
    display_name: Optional[str] = None
    full_name: Optional[str] = None
    shipping_address: Optional[dict] = None
    order_id: Optional[str] = None # Link this order to the new consumer
