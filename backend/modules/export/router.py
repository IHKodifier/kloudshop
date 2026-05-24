from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from shared.db import get_db, AsyncSessionLocal
from shared.auth import UserClaims, validate_token
from shared.rbac import has_permissions
from . import models, schemas
from datetime import datetime, timezone
import asyncio

router = APIRouter(tags=["Export Engine"])

async def run_export_job(job_id: str, tenant_id: str):
    async with AsyncSessionLocal() as db:
        # 1. Update status to processing
        await db.execute(
            update(models.ExportJob)
            .where(models.ExportJob.job_id == job_id)
            .values(status='processing')
        )
        await db.commit()
        
        # 2. Simulate data gathering and file creation
        await asyncio.sleep(2)
        
        # 3. Simulate upload to GCS and get signed URL
        signed_url = f"https://storage.googleapis.com/kloudshop-exports-{tenant_id}/{job_id}.csv"
        
        # 4. Update status to completed
        await db.execute(
            update(models.ExportJob)
            .where(models.ExportJob.job_id == job_id)
            .values(
                status='completed',
                download_url=signed_url,
                completed_at=datetime.now(timezone.utc)
            )
        )
        await db.commit()

@router.post("/", response_model=schemas.ExportJobResponse, status_code=status.HTTP_202_ACCEPTED)
async def start_export(
    req: schemas.ExportRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = has_permissions(["settings:read"])
):
    job = models.ExportJob(
        tenant_id=user.tenant_id,
        user_id=user.uid,
        format=req.format,
        resource_type=req.resource_type,
        status='pending'
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)
    
    background_tasks.add_task(run_export_job, job.job_id, user.tenant_id)
    
    return job

@router.get("/{job_id}", response_model=schemas.ExportJobResponse)
async def get_export_job(
    job_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserClaims = Depends(validate_token)
):
    result = await db.execute(
        select(models.ExportJob).where(
            models.ExportJob.job_id == job_id,
            models.ExportJob.tenant_id == user.tenant_id
        )
    )
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(status_code=404, detail="Export job not found")
    return job
