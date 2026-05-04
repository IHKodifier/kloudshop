from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from shared.db import get_db
from shared.auth import UserClaims, validate_token
from modules.platform.models import Tenant
from typing import List

router = APIRouter(tags=["Internationalization"])

@router.get("/locales", response_model=List[str])
async def get_locales(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    """Get the list of supported locales for the current tenant."""
    result = await db.execute(select(Tenant).where(Tenant.id == user.tenant_id))
    tenant = result.scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
        
    return tenant.supported_locales or ["en"]

@router.put("/locales", response_model=List[str])
async def update_locales(
    locales: List[str],
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    """Update the list of supported locales for the current tenant."""
    if not locales:
        raise HTTPException(status_code=400, detail="Locales list cannot be empty")
        
    # Ensure 'en' is always included as fallback if not present (optional, but safe)
    if "en" not in locales:
        locales.append("en")
        
    result = await db.execute(select(Tenant).where(Tenant.id == user.tenant_id))
    tenant = result.scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
        
    tenant.supported_locales = locales
    await db.commit()
    return tenant.supported_locales
