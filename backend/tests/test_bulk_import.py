import pytest
from httpx import AsyncClient
import io
import asyncio

@pytest.mark.asyncio
async def test_bulk_import_csv_success(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that a CSV can be uploaded and products are created."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # Create a dummy CSV
    csv_content = "title,price,sku\nProduct 1,10.50,SKU-100\nProduct 2,20.00,SKU-200"
    files = {'file': ('products.csv', io.BytesIO(csv_content.encode()), 'text/csv')}
    
    response = await client.post("/api/v1/products/bulk-import", files=files, headers=headers)
    
    assert response.status_code == 202
    data = response.json()
    job_id = data["job_id"]
    assert data["status"] == "pending"
    
    # Wait for background task to complete (polling)
    for _ in range(5):
        await asyncio.sleep(0.5)
        job_resp = await client.get(f"/api/v1/products/import-jobs/{job_id}", headers=headers)
        job_data = job_resp.json()
        if job_data["status"] == "completed":
            break
    
    assert job_data["status"] == "completed"
    assert job_data["rows_total"] == 2
    assert job_data["rows_processed"] == 2
    
    # Verify products exist
    prod_resp = await client.get("/api/v1/products/", headers=headers)
    products = prod_resp.json()
    assert len(products) >= 2
    titles = [p["title"] for p in products]
    assert "Product 1" in titles
    assert "Product 2" in titles

@pytest.mark.asyncio
async def test_bulk_import_csv_partial_failure(client: AsyncClient, mock_firebase_user, db_session):
    """Verify that some rows can fail while others succeed."""
    headers = {"Authorization": "Bearer valid_token"}
    
    # Row 2 is missing price
    csv_content = "title,price,sku\nGood Prod,10.0,S1\nBad Prod,,S2"
    files = {'file': ('partial.csv', io.BytesIO(csv_content.encode()), 'text/csv')}
    
    response = await client.post("/api/v1/products/bulk-import", files=files, headers=headers)
    job_id = response.json()["job_id"]
    
    # Wait
    for _ in range(5):
        await asyncio.sleep(0.5)
        job_resp = await client.get(f"/api/v1/products/import-jobs/{job_id}", headers=headers)
        if job_resp.json()["status"] == "completed":
            break
            
    job_data = job_resp.json()
    assert job_data["rows_total"] == 2
    assert job_data["rows_processed"] == 1
    assert job_data["rows_failed"] == 1
    assert len(job_data["error_log"]) == 1
    assert "Missing required fields" in job_data["error_log"][0]["error"]
