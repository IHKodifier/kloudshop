from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, insert
from typing import List, Dict, Any
from shared.db import get_db
from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from . import models, schemas
from datetime import datetime, timezone
import json

router = APIRouter(tags=["AI Copywriter"])

class GeminiClient:
    """Mock Gemini Client for Sprint 10 TDD."""
    async def generate_variants(self, content_type: str, brand_voice: Dict[str, Any], context: Dict[str, Any]) -> List[Dict[str, Any]]:
        tone = brand_voice.get("tone", "Professional")
        title = context.get("title", "Product")
        
        if content_type == "product_title":
            return [
                {"variant_id": 1, "label": "Benefit-led", "content": f"Experience the Best {title} for Your Needs"},
                {"variant_id": 2, "label": "Problem-solution", "content": f"Finally, a {title} That Works"},
                {"variant_id": 3, "label": "Authority", "content": f"Premium {title} - {tone} Edition"}
            ]
        elif content_type == "product_description":
            return [
                {"variant_id": 1, "label": "Benefit-led", "content": f"Our {title} is designed to provide maximum value with a {tone} touch."},
                {"variant_id": 2, "label": "Problem-solution", "content": f"Tired of mediocre products? Our {title} solves your problems efficiently."},
                {"variant_id": 3, "label": "Authority", "content": f"Expertly crafted {title}, adhering to the highest standards of quality."}
            ]
        return []

gemini_client = GeminiClient()

@router.get("/brand-voice", response_model=schemas.BrandVoiceProfileResponse)
async def get_brand_voice(
    brand_profile_id: str = "default",
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(models.BrandVoiceProfile).where(
            models.BrandVoiceProfile.tenant_id == user.tenant_id,
            models.BrandVoiceProfile.brand_profile_id == brand_profile_id
        )
    )
    profile = result.scalar_one_or_none()
    if not profile:
        # Return a default empty profile instead of 404
        return models.BrandVoiceProfile(
            tenant_id=user.tenant_id,
            brand_profile_id=brand_profile_id,
            tone="Professional",
            brand_adjectives=[],
            negative_brands=[],
            configured_at=datetime.now(timezone.utc)
        )
    return profile

@router.put("/brand-voice", response_model=schemas.BrandVoiceProfileResponse)
async def update_brand_voice(
    req: schemas.BrandVoiceProfileBase,
    brand_profile_id: str = "default",
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(models.BrandVoiceProfile).where(
            models.BrandVoiceProfile.tenant_id == user.tenant_id,
            models.BrandVoiceProfile.brand_profile_id == brand_profile_id
        )
    )
    profile = result.scalar_one_or_none()
    
    data = req.model_dump()
    if profile:
        for key, value in data.items():
            setattr(profile, key, value)
        profile.configured_at = datetime.now(timezone.utc)
        profile.configured_by = user.uid
    else:
        profile = models.BrandVoiceProfile(
            tenant_id=user.tenant_id,
            brand_profile_id=brand_profile_id,
            configured_at=datetime.now(timezone.utc),
            configured_by=user.uid,
            **data
        )
        db.add(profile)
    
    await db.commit()
    await db.refresh(profile)
    return profile

async def generate_copy_impl(content_type: str, req: schemas.CopyGenerationRequest, db: AsyncSession, user: UserClaims):
    # 1. Fetch Brand Voice
    bv_result = await db.execute(
        select(models.BrandVoiceProfile).where(
            models.BrandVoiceProfile.tenant_id == user.tenant_id,
            models.BrandVoiceProfile.brand_profile_id == req.brand_profile_id
        )
    )
    bv = bv_result.scalar_one_or_none()
    bv_dict = bv.__dict__ if bv else {"tone": "Professional"}
    
    # 2. Call Gemini
    variants = await gemini_client.generate_variants(content_type, bv_dict, req.context_data)
    
    # 3. Log Generation
    log = models.AICopywriterLog(
        tenant_id=user.tenant_id,
        user_id=user.uid,
        content_type=content_type,
        prompt_context={"source": req.source_content, "context": req.context_data},
        generated_variants=variants
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    
    return schemas.CopyGenerationResponse(
        log_id=log.log_id,
        variants=[schemas.CopyVariant(**v) for v in variants]
    )

@router.post("/copy/product-title", response_model=schemas.CopyGenerationResponse)
async def generate_product_title(
    req: schemas.CopyGenerationRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    return await generate_copy_impl("product_title", req, db, user)

@router.post("/copy/product-description", response_model=schemas.CopyGenerationResponse)
async def generate_product_description(
    req: schemas.CopyGenerationRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    return await generate_copy_impl("product_description", req, db, user)

@router.post("/copy/accept/{log_id}")
async def accept_copy_variant(
    log_id: str,
    req: schemas.CopyAcceptanceRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(models.AICopywriterLog).where(
            models.AICopywriterLog.log_id == log_id,
            models.AICopywriterLog.tenant_id == user.tenant_id
        )
    )
    log = result.scalar_one_or_none()
    if not log:
        raise HTTPException(status_code=404, detail="Log not found")
    
    log.variant_accepted = req.variant_accepted
    log.was_edited = req.was_edited
    # In a real app, final_content might be stored elsewhere (e.g. updated on product)
    
    await db.commit()
    return {"message": "Acceptance recorded"}
