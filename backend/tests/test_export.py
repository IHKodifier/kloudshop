import pytest
import pytest_asyncio
from httpx import AsyncClient
from modules.export.models import ExportJob
from sqlalchemy import select
import asyncio

@pytest.mark.asyncio
async def test_export_flow(client: AsyncClient, mock_firebase_user, db_session):
    headers = {"Authorization": "Bearer valid_token"}
    
    # 1. Start export
    payload = {"format": "csv", "resource_type": "products"}
    response = await client.post("/api/v1/export/", json=payload, headers=headers)
    assert response.status_code == 202
    job_id = response.json()["job_id"]
    
    # 2. Poll for completion
    for _ in range(10):
        resp_get = await client.get(f"/api/v1/export/{job_id}", headers=headers)
        assert resp_get.status_code == 200
        if resp_get.json()["status"] == "completed":
            break
        await asyncio.sleep(0.5)
    else:
        pytest.fail("Export job did not complete in time")
    
    # 3. Verify final state
    data = resp_get.json()
    assert data["status"] == "completed"
    assert "download_url" in data
    assert data["download_url"].startswith("https://storage.googleapis.com")
