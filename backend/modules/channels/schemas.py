from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class ChannelConnectionBase(BaseModel):
    channel_type: str
    status: str

class ChannelConnectionCreate(ChannelConnectionBase):
    pass

class ChannelConnectionRead(ChannelConnectionBase):
    connection_id: str
    tenant_id: str
    last_sync_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ChannelSyncStatus(BaseModel):
    channel_type: str
    status: str
    last_sync_at: Optional[datetime] = None
    sync_in_progress: bool = False
