from fastapi import APIRouter, UploadFile, File, HTTPException
import os
import uuid
import shutil
from typing import List

router = APIRouter()

STORAGE_PATH = os.path.join(os.getcwd(), "backend", "storage", "media")

@router.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    # Create storage path if it doesn't exist
    if not os.path.exists(STORAGE_PATH):
        os.makedirs(STORAGE_PATH, exist_ok=True)
    
    # Generate safe filename
    file_extension = os.path.splitext(file.filename)[1]
    safe_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(STORAGE_PATH, safe_filename)
    
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Return the public URL
        # Note: In production, this would be a GCS URL
        public_url = f"/media/{safe_filename}"
        
        return {
            "url": public_url,
            "filename": safe_filename,
            "original_name": file.filename
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {str(e)}")

@router.post("/upload-multiple")
async def upload_multiple_files(files: List[UploadFile] = File(...)):
    results = []
    for file in files:
        res = await upload_file(file)
        results.append(res)
    return results
