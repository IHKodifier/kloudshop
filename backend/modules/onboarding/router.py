from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from typing import List, Dict
from datetime import datetime 

from shared.db import get_db 
from shared.auth import UserClaims, validate_token 
from shared.rbac import has_permissions
from .models import OnboardingSession, ImportMapping 
from .schemas import (
    SignupRequest, RegionSelectionRequest, 
    ImportAnalysisRequest, ImportAnalysisResponse,
    OnboardingStatusResponse, MigrationRunbookResponse
)

router = APIRouter(tags=["Onboarding"])

@router.get("/check-availability")
async def check_tenant_availability(
    tenant_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Check if a tenant ID (slug) is available."""
    from modules.platform.models import Tenant
    result = await db.execute(select(Tenant).where(Tenant.id == tenant_id.lower()))
    exists = result.scalar_one_or_none() is not None
    return {"available": not exists, "tenant_id": tenant_id}

@router.get("/status", response_model=OnboardingStatusResponse)
async def get_onboarding_status(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(OnboardingSession).where(OnboardingSession.tenant_id == user.tenant_id)
    )
    session = result.scalar_one_or_none()
    if not session:
        # Auto-create session if missing
        session = OnboardingSession(tenant_id=user.tenant_id)
        db.add(session)
        await db.commit()
        await db.refresh(session)
        return session

@router.get("/tenant", response_model=dict)
async def get_tenant_details(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    """Fetch tenant identity and configuration for the current merchant."""
    from modules.platform.models import Tenant
    result = await db.execute(
        select(Tenant).where(Tenant.id == user.tenant_id)
    )
    tenant = result.scalar_one_or_none()
    if not tenant:
        # Auto-heal: If in testing/dev mode, recreate the tenant record if it's missing
        from shared.db import settings
        if settings.TESTING:
             tenant = Tenant(
                id=user.tenant_id,
                name=user.tenant_id.capitalize(),
                gcp_project_id="kloudshop-dev",
                gcp_bucket_name=f"gs://kloudshop-dev-{user.tenant_id}"
            )
             db.add(tenant)
             await db.commit()
             await db.refresh(tenant)
        else:
            raise HTTPException(status_code=404, detail="Tenant not found")
        
    return {
        "id": tenant.id,
        "name": tenant.name,
        "created_at": tenant.created_at.isoformat(),
        "gcp_project_id": tenant.gcp_project_id,
        "gcp_bucket_name": tenant.gcp_bucket_name,
        "config": tenant.config,
        "supported_locales": tenant.supported_locales
    }

@router.patch("/tenant", response_model=dict)
async def update_tenant_details(
    update_data: dict,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    """Update merchant store details (name, config)."""
    from modules.platform.models import Tenant
    result = await db.execute(
        select(Tenant).where(Tenant.id == user.tenant_id)
    )
    tenant = result.scalar_one_or_none()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
        
    if "name" in update_data:
        tenant.name = update_data["name"]
    if "config" in update_data:
        # Merge config
        current_config = tenant.config or {}
        current_config.update(update_data["config"])
        tenant.config = current_config
        
    await db.commit()
    await db.refresh(tenant)
    
    return {
        "id": tenant.id,
        "name": tenant.name,
        "created_at": tenant.created_at.isoformat(),
        "gcp_project_id": tenant.gcp_project_id,
        "gcp_bucket_name": tenant.gcp_bucket_name,
        "config": tenant.config,
        "supported_locales": tenant.supported_locales
    }

@router.post("/signup", response_model=OnboardingStatusResponse)
async def complete_onboarding_signup(
    req: SignupRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(OnboardingSession).where(OnboardingSession.tenant_id == user.tenant_id)
    )
    session = result.scalar_one()
    session.selected_tier = req.tier
    session.current_step = "region"
    await db.commit()
    await db.refresh(session)
    return session

@router.post("/region", response_model=OnboardingStatusResponse)
async def complete_region_selection(
    req: RegionSelectionRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(OnboardingSession).where(OnboardingSession.tenant_id == user.tenant_id)
    )
    session = result.scalar_one()
    session.selected_region = req.region
    session.current_step = "import"
    await db.commit()
    await db.refresh(session)
    return session

@router.post("/import/analyze", response_model=ImportAnalysisResponse)
async def analyze_import_csv(
    req: ImportAnalysisRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    # Mock AI Header Mapping Logic
    mappings = {
        "product": {
            "title": ["name", "product name", "title"],
            "sku": ["sku", "item code", "reference"],
            "price": ["price", "cost", "msrp", "amount"],
            "description": ["description", "body", "content"],
            "slug": ["slug", "url handle", "permalink"]
        },
        "customer": {
            "first_name": ["first name", "given name"],
            "last_name": ["last name", "surname"],
            "email": ["email", "e-mail", "email address"]
        }
    }
    
    suggested = {}
    entity_mappings = mappings.get(req.entity_type, {})
    
    for model_field, synonyms in entity_mappings.items():
        for header in req.csv_sample:
            if header.lower().strip() in synonyms:
                suggested[header] = model_field
                break
                
    return ImportAnalysisResponse(
        suggested_mapping=suggested,
        confidence_score=0.9 if suggested else 0.1
    )

@router.get("/runbook", response_model=MigrationRunbookResponse)
async def generate_migration_runbook(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    # Generate a personalized migration checklist
    steps = [
        {"id": "s1", "task": "Export your products from your current platform (Shopify/Magento/WooCommerce)", "status": "pending"},
        {"id": "s2", "task": f"Confirm target region: us-central1 (Cloud SQL & GCS)", "status": "info"},
        {"id": "s3", "task": "Upload CSV to KloudShop Import Engine", "status": "pending"},
        {"id": "s4", "task": "Map custom headers to KloudShop schema", "status": "pending"},
        {"id": "s5", "task": "Verify imported variants and pricing", "status": "pending"}
    ]
    
    return MigrationRunbookResponse(
        merchant_name=user.tenant_id,
        steps=steps,
        generated_at=datetime.utcnow()
    )
