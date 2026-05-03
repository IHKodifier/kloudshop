from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from typing import List, Dict, Any
from shared.db import get_db
from shared.auth import UserClaims
from shared.rbac import has_permissions
from . import models, schemas
import json
from datetime import datetime

router = APIRouter(tags=["Features"])

async def simulate_feature_migration(tenant_id: str, feature_id: str):
    """
    Simulates the cloud tasks migration job described in US-049.
    In production, this would trigger a series of Alembic migrations
    or schema-driven layout updates in Realtime DB.
    """
    print(f"[MIGRATION] Running schema migration for tenant {tenant_id}, feature {feature_id}...")
    # Simulate delay
    import asyncio
    await asyncio.sleep(2)
    print(f"[MIGRATION] Migration completed for {tenant_id}:{feature_id}")

@router.get("/", response_model=List[schemas.FeatureResponse])
async def list_features(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["features:read"])
):
    # Fetch all global features
    result = await db.execute(select(models.Feature))
    features = result.scalars().all()
    
    # Fetch activation status for this tenant
    activation_result = await db.execute(
        select(models.TenantFeatureActivation).where(models.TenantFeatureActivation.tenant_id == user.tenant_id)
    )
    activations = {a.feature_id: a.is_active for a in activation_result.scalars().all()}
    
    response = []
    for f in features:
        # Pydantic v2 from_orm is now model_validate
        resp = schemas.FeatureResponse.model_validate(f)
        resp.is_active = activations.get(f.feature_id, False)
        response.append(resp)
        
    return response

@router.post("/{feature_id}/activate")
async def activate_feature(
    feature_id: str,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["features:write"])
):
    # Verify feature exists
    result = await db.execute(select(models.Feature).where(models.Feature.feature_id == feature_id))
    feature = result.scalar_one_or_none()
    if not feature:
        raise HTTPException(status_code=404, detail="Feature not found")
        
    # Update/Create activation record
    activation_result = await db.execute(
        select(models.TenantFeatureActivation).where(
            models.TenantFeatureActivation.tenant_id == user.tenant_id,
            models.TenantFeatureActivation.feature_id == feature_id
        )
    )
    activation = activation_result.scalar_one_or_none()
    
    if activation:
        activation.is_active = True
        activation.activated_at = datetime.utcnow()
        activation.activated_by = user.uid
    else:
        activation = models.TenantFeatureActivation(
            tenant_id=user.tenant_id,
            feature_id=feature_id,
            is_active=True,
            activated_at=datetime.utcnow(),
            activated_by=user.uid
        )
        db.add(activation)
    
    await db.commit()
    
    # Trigger background migration
    background_tasks.add_task(simulate_feature_migration, user.tenant_id, feature_id)
    
    return {"message": f"Feature {feature_id} activation triggered", "status": "processing"}

@router.post("/{feature_id}/deactivate")
async def deactivate_feature(
    feature_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["features:write"])
):
    await db.execute(
        update(models.TenantFeatureActivation)
        .where(
            models.TenantFeatureActivation.tenant_id == user.tenant_id,
            models.TenantFeatureActivation.feature_id == feature_id
        )
        .values(is_active=False)
    )
    await db.commit()
    return {"message": f"Feature {feature_id} deactivated"}

@router.get("/{feature_id}/config")
async def get_feature_config(
    feature_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["features:read"])
):
    result = await db.execute(
        select(models.TenantFeatureConfig).where(
            models.TenantFeatureConfig.tenant_id == user.tenant_id,
            models.TenantFeatureConfig.feature_id == feature_id
        )
    )
    configs = result.scalars().all()
    return {c.config_key: c.config_value for c in configs}

@router.put("/{feature_id}/config")
async def update_feature_config(
    feature_id: str,
    config_req: schemas.FeatureConfigRequest,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["features:write"])
):
    # In a real app, we would validate against models.Feature.config_schema here
    
    # Delete old config and insert new (or upsert)
    await db.execute(
        delete(models.TenantFeatureConfig).where(
            models.TenantFeatureConfig.tenant_id == user.tenant_id,
            models.TenantFeatureConfig.feature_id == feature_id
        )
    )
    
    for key, value in config_req.config.items():
        db_config = models.TenantFeatureConfig(
            tenant_id=user.tenant_id,
            feature_id=feature_id,
            config_key=key,
            config_value=str(value) # Simplification: store as string
        )
        db.add(db_config)
        
    await db.commit()
    return {"message": "Configuration updated"}

@router.get("/requests", response_model=List[schemas.FeatureRequestResponse])
async def list_requests(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["features:read"])
):
    # This endpoint is for community requests (US-051)
    # We'll reuse FeatureResponse schema or create a specific one if needed
    # For now, let's just implement the logic
    result = await db.execute(
        select(models.FeatureRequest).order_by(models.FeatureRequest.votes_count.desc())
    )
    requests = result.scalars().all()
    
    # Check if current user has voted for each
    voted_result = await db.execute(
        select(models.FeatureRequestVote.request_id).where(models.FeatureRequestVote.user_id == user.uid)
    )
    voted_ids = set(voted_result.scalars().all())
    
    response = []
    for r in requests:
        resp = schemas.FeatureRequestResponse.model_validate(r)
        resp.has_voted = r.request_id in voted_ids
        response.append(resp)
        
    return response

@router.post("/requests", response_model=schemas.FeatureRequestResponse)
async def create_request(
    req: schemas.FeatureRequestCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["features:write"])
):
    new_req = models.FeatureRequest(
        tenant_id=user.tenant_id,
        user_id=user.uid,
        title=req.title,
        description=req.description
    )
    db.add(new_req)
    await db.commit()
    await db.refresh(new_req)
    return schemas.FeatureRequestResponse.model_validate(new_req)

@router.post("/requests/{request_id}/vote", response_model=schemas.FeatureVoteResponse)
async def vote_request(
    request_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["features:write"])
):
    # Check if already voted
    voted_result = await db.execute(
        select(models.FeatureRequestVote).where(
            models.FeatureRequestVote.request_id == request_id,
            models.FeatureRequestVote.user_id == user.uid
        )
    )
    if voted_result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Already voted")
        
    # Record vote
    vote = models.FeatureRequestVote(
        request_id=request_id,
        user_id=user.uid,
        tenant_id=user.tenant_id
    )
    db.add(vote)
    
    # Increment count
    await db.execute(
        update(models.FeatureRequest)
        .where(models.FeatureRequest.request_id == request_id)
        .values(votes_count=models.FeatureRequest.votes_count + 1)
    )
    
    await db.commit()
    
    # Fetch updated count
    result = await db.execute(select(models.FeatureRequest).where(models.FeatureRequest.request_id == request_id))
    req = result.scalar_one()
    
    return {
        "request_id": request_id,
        "votes_count": req.votes_count,
        "has_voted": True
    }
