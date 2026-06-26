from sqlalchemy import Column, String, Boolean, Numeric
from shared.db import Base
import uuid

class StoreTaxRate(Base):
    __tablename__ = "store_tax_rates"

    tax_rate_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String, nullable=False, index=True)
    country_code = Column(String(2), nullable=False)
    state_code = Column(String(8), nullable=True)
    tax_percentage = Column(Numeric(5, 2), nullable=False, default=0.0)
    is_active = Column(Boolean, nullable=False, default=True)
