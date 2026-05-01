#!/bin/bash
# GCP Tenant Provisioning Script (KloudShop)
# This script provisions isolated GCP resources for a new KloudShop tenant.
# It creates a tenant-specific Cloud Storage bucket and configures CORS for the storefront.
# Note: The Cloud SQL PostgreSQL schema (tenant_{tenant_id}) is provisioned programmatically
# via the FastAPI backend during the merchant onboarding flow.

usage() {
    echo "Usage: $0 <tenant_id> <environment>"
    echo "  tenant_id    - Unique identifier for the tenant (e.g. acmeco)"
    echo "  environment  - Deployment environment (dev | staging | prod)"
    echo ""
    echo "Example: $0 acmeco dev"
    exit 1
}

if [ -z "$1" ] || [ -z "$2" ]; then
    usage
fi

TENANT_ID=$1
ENV=$2
PROJECT_ID="kloudshop-${ENV}"
BUCKET_NAME="gs://kloudshop-${ENV}-${TENANT_ID}"

echo "========================================"
echo " Provisioning GCP Resources for Tenant"
echo " Tenant ID:   $TENANT_ID"
echo " Environment: $ENV"
echo " Project ID:  $PROJECT_ID"
echo "========================================"
echo ""

# 1. Verify Project
gcloud config set project $PROJECT_ID --quiet
if [ $? -ne 0 ]; then
    echo "Error: Could not switch to project $PROJECT_ID. Does it exist?"
    exit 1
fi

# 2. Create Cloud Storage Bucket
echo "[1/3] Checking/Creating Cloud Storage Bucket: $BUCKET_NAME"
if gcloud storage buckets describe $BUCKET_NAME --project=$PROJECT_ID > /dev/null 2>&1; then
    echo "✅ Bucket already exists."
else
    gcloud storage buckets create $BUCKET_NAME \
        --project=$PROJECT_ID \
        --location=us-central1 \
        --uniform-bucket-level-access
    if [ $? -eq 0 ]; then
        echo "✅ Bucket created successfully."
    else
        echo "❌ Failed to create bucket."
        exit 1
    fi
fi

# 3. Apply CORS Policy to the Bucket
echo "[2/3] Applying CORS configuration to allow Flutter Web direct access..."
cat <<EOF > cors.json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin", "Authorization"],
    "maxAgeSeconds": 3600
  }
]
EOF

gcloud storage buckets update $BUCKET_NAME --cors-file=cors.json
if [ $? -eq 0 ]; then
    echo "✅ CORS configuration applied successfully."
else
    echo "❌ Failed to apply CORS configuration."
fi
rm cors.json

# 4. Final summary
echo "[3/3] Setting up IAM/Service Accounts (Skipped/Managed by Workload Identity)"
echo ""
echo "========================================"
echo " GCP Provisioning Complete for $TENANT_ID!"
echo " Note: The database schema 'tenant_${TENANT_ID}' must be created"
echo " via the KloudShop FastAPI application."
echo "========================================"
