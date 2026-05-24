from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from sqlalchemy.orm import selectinload
from typing import List, Dict
from datetime import datetime

from shared.db import get_db
from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from .models import Theme, ThemeConfiguration
from .schemas import (
    ThemeResponse, ThemeConfigResponse, 
    ThemeConfigRequest, ThemeSelectionRequest
)

router = APIRouter(tags=["Themes"])

@router.get("", response_model=List[ThemeResponse])
async def list_themes(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Theme))
    themes = result.scalars().all()
    
    if not themes:
        # Seed default theme
        default_theme = Theme(
            theme_id="modern-dark",
            name="Modern Dark",
            description="A sleek, professional dark theme with vibrant accents.",
            base_config={
                "tokens": {"primary": "#6366f1", "secondary": "#1e293b", "background": "#0f172a"},
                "slots": {"header": "centered", "hero": "full-width", "hero_heading": "Modern Store"}
            }
        )
        minimal_theme = Theme(
            theme_id="minimal-light",
            name="Minimal Light",
            description="A clean, minimalist white theme for high-end brands.",
            base_config={
                "tokens": {"primary": "#000000", "secondary": "#f8fafc", "background": "#ffffff"},
                "slots": {"header": "left", "hero": "centered", "hero_heading": "Minimalist"}
            }
        )
        db.add_all([default_theme, minimal_theme])
        await db.commit()
        themes = [default_theme, minimal_theme]
        
    return themes

@router.get("/active", response_model=ThemeConfigResponse)
async def get_active_theme_config(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="User has no tenant_id assigned")
        
    result = await db.execute(
        select(ThemeConfiguration)
        .where(ThemeConfiguration.tenant_id == user.tenant_id, ThemeConfiguration.is_active == True)
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="No active theme found")
    return config

@router.post("/select", response_model=ThemeConfigResponse)
async def select_theme(
    req: ThemeSelectionRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="User has no tenant_id assigned")
        
    # Check if theme exists
    theme_res = await db.execute(select(Theme).where(Theme.theme_id == req.theme_id))
    theme = theme_res.scalar_one_or_none()
    if not theme:
        raise HTTPException(status_code=404, detail="Theme not found")
        
    # Get current active config for carry-forward
    active_res = await db.execute(
        select(ThemeConfiguration)
        .where(ThemeConfiguration.tenant_id == user.tenant_id, ThemeConfiguration.is_active == True)
    )
    prev_config = active_res.scalar_one_or_none()
    
    # Deactivate all existing configs for this tenant
    await db.execute(
        update(ThemeConfiguration)
        .where(ThemeConfiguration.tenant_id == user.tenant_id)
        .values(is_active=False)
    )
    
    # Check if already has config for the TARGET theme
    result = await db.execute(
        select(ThemeConfiguration)
        .where(ThemeConfiguration.tenant_id == user.tenant_id, ThemeConfiguration.theme_id == req.theme_id)
    )
    config = result.scalar_one_or_none()
    
    if not config:
        # Start with theme defaults
        slots = theme.base_config["slots"].copy()
        
        # Apply Carry-Forward: Copy matching slots from prev_config
        if prev_config:
            for key, value in prev_config.draft_slots.items():
                if key in slots:
                    slots[key] = value
                    
        config = ThemeConfiguration(
            tenant_id=user.tenant_id,
            theme_id=req.theme_id,
            draft_tokens=theme.base_config["tokens"],
            live_tokens=theme.base_config["tokens"],
            draft_slots=slots,
            live_slots=slots,
            is_active=True
        )
        db.add(config)
    else:
        config.is_active = True
        
    await db.commit()
    await db.refresh(config)
    return config

@router.patch("/config", response_model=ThemeConfigResponse)
async def update_theme_config_draft(
    req: ThemeConfigRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="User has no tenant_id assigned")
        
    result = await db.execute(
        select(ThemeConfiguration)
        .where(ThemeConfiguration.tenant_id == user.tenant_id, ThemeConfiguration.is_active == True)
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="Active theme config not found")
        
    if req.tokens is not None:
        new_tokens = config.draft_tokens.copy()
        new_tokens.update(req.tokens)
        config.draft_tokens = new_tokens
        
    if req.slots is not None:
        new_slots = config.draft_slots.copy()
        new_slots.update(req.slots)
        config.draft_slots = new_slots
        
    await db.commit()
    await db.refresh(config)
    return config

@router.post("/publish", response_model=ThemeConfigResponse)
async def publish_theme_config(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    if not user.tenant_id:
        raise HTTPException(status_code=400, detail="User has no tenant_id assigned")
        
    result = await db.execute(
        select(ThemeConfiguration)
        .where(ThemeConfiguration.tenant_id == user.tenant_id, ThemeConfiguration.is_active == True)
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="Active theme config not found")
        
    config.live_tokens = config.draft_tokens
    config.live_slots = config.draft_slots
    
    await db.commit()
    await db.refresh(config)
    return config
