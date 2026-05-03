from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from typing import List
from shared.db import get_db
from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from . import models, schemas

router = APIRouter(tags=["Dynamic Pricing"])

@router.post("/", response_model=schemas.PricingRuleResponse, status_code=status.HTTP_201_CREATED)
async def create_pricing_rule(
    req: schemas.PricingRuleCreate,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    rule = models.PricingRule(
        **req.model_dump(),
        tenant_id=user.tenant_id,
        created_by=user.uid
    )
    db.add(rule)
    await db.commit()
    await db.refresh(rule)
    return rule

@router.get("/", response_model=List[schemas.PricingRuleResponse])
async def list_pricing_rules(
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:read"])
):
    result = await db.execute(
        select(models.PricingRule).where(models.PricingRule.tenant_id == user.tenant_id)
    )
    return result.scalars().all()

@router.delete("/{rule_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_pricing_rule(
    rule_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["catalog:write"])
):
    result = await db.execute(
        select(models.PricingRule).where(
            models.PricingRule.rule_id == rule_id,
            models.PricingRule.tenant_id == user.tenant_id
        )
    )
    rule = result.scalar_one_or_none()
    if not rule:
        raise HTTPException(status_code=404, detail="Pricing rule not found")
    
    await db.delete(rule)
    await db.commit()
    return None
