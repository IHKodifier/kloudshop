from sqlalchemy import Column, String, Text, Boolean, Integer, SmallInteger, DateTime, JSON, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from shared.db import Base, engine
import uuid
from datetime import datetime, timezone

class BrandVoiceProfile(Base):
    __tablename__ = "brand_voice_profiles"

    tenant_id = Column(String, primary_key=True)
    brand_profile_id = Column(String, primary_key=True) # Independent profiles for DTC/B2B
    
    tone = Column(String(64))
    target_audience = Column(Text)
    brand_adjectives = Column(JSON, nullable=False, default=[]) # List of strings
    writing_style_rules = Column(Text)
    negative_brands = Column(JSON, nullable=False, default=[]) # List of strings
    
    configured_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    configured_by = Column(String) # user_id

class AICopywriterLog(Base):
    __tablename__ = "ai_copywriter_logs"

    log_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    user_id = Column(String, nullable=False)
    
    content_type = Column(String(32), nullable=False) # product_title | product_description | blog_title | blog_body
    prompt_context = Column(JSON) # What was sent to Gemini
    generated_variants = Column(JSON) # The 3 variants received
    
    variant_accepted = Column(SmallInteger) # 1, 2, or 3
    was_edited = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        CheckConstraint(content_type.in_(['product_title', 'product_description', 'blog_title', 'blog_body']), name='ai_copywriter_content_type_check'),
    )
