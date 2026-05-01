param (
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    [Parameter(Mandatory=$true)]
    [string]$Environment
)

$ProjectID = "kloudshop-$Environment"
$BucketName = "gs://kloudshop-$Environment-$TenantId"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Provisioning GCP Resources for Tenant"
Write-Host " Tenant ID:   $TenantId"
Write-Host " Environment: $Environment"
Write-Host " Project ID:  $ProjectID"
Write-Host "========================================"
Write-Host ""

# 1. Verify Project
Write-Host "[1/3] Setting GCP Project: $ProjectID"
gcloud config set project $ProjectID --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Error "Could not switch to project $ProjectID. Does it exist?"
    exit 1
}

# 2. Create Cloud Storage Bucket
Write-Host "[1/3] Checking/Creating Cloud Storage Bucket: $BucketName"
$bucketExists = gcloud storage buckets describe $BucketName --project=$ProjectID 2>$null
if ($bucketExists) {
    Write-Host "✅ Bucket already exists." -ForegroundColor Green
} else {
    gcloud storage buckets create $BucketName --project=$ProjectID --location=us-central1 --uniform-bucket-level-access
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Bucket created successfully." -ForegroundColor Green
    } else {
        Write-Error "Failed to create bucket."
        exit 1
    }
}

# 3. Apply CORS Policy
Write-Host "[2/3] Applying CORS configuration..."
$corsJson = @'
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin", "Authorization"],
    "maxAgeSeconds": 3600
  }
]
'@
$corsJson | Out-File -FilePath "cors.json" -Encoding ascii
gcloud storage buckets update $BucketName --cors-file="cors.json"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ CORS configuration applied successfully." -ForegroundColor Green
} else {
    Write-Error "Failed to apply CORS configuration."
}
Remove-Item "cors.json"

# 4. Final summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " GCP Provisioning Complete for $TenantId!"
Write-Host "========================================"
