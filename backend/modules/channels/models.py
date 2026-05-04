from sqlalchemy import Column, String, Text, Boolean, Integer, SmallInteger, Numeric, DateTime, JSON, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from shared.db import Base, engine
import uuid
from datetime import datetime

class ChannelConnection(Base):
    __tablename__ = "channel_connections"

    connection_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    
    channel_type = Column(String(32), nullable=False) # tiktok | instagram | facebook | google
    status = Column(String(16), nullable=False, default='disconnected') # connected | disconnected | error
    
    credentials_secret_id = Column(String) # Reference to Secret Manager
    
    last_sync_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        CheckConstraint(channel_type.in_(['tiktok', 'instagram', 'facebook', 'google']), name='channel_type_check'),
        CheckConstraint(status.in_(['connected', 'disconnected', 'error']), name='channel_status_check'),
    )

class ChannelSyncLog(Base):
    __tablename__ = "channel_sync_logs"

    log_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    connection_id = Column(String, ForeignKey("channel_connections.connection_id", ondelete="CASCADE"), nullable=False)
    tenant_id = Column(String, nullable=False, index=True)
    
    status = Column(String(16), nullable=False) # success | failure
    items_synced = Column(Integer, default=0)
    items_failed = Column(Integer, default=0)
    error_message = Column(Text)
    
    started_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime)
