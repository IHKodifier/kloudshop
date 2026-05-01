#!/bin/bash
# KloudShop Smart DB Manager
# Helps you minimize GCP costs by providing state-aware actions and cost transparency.

# --- Configuration ---
PROJECT_ID="kloudshop-dev"
INSTANCE_NAME="kloudshop-db-dev"
BACKUP_BUCKET="gs://kloudshop-dev-db-backups"
REGION="us-central1"
ZONE="us-central1-b"
TIER="db-f1-micro"
STORAGE_GB=10

# Cost Constants (Approximate USD)
COST_COMPUTE_HR=0.013
COST_STORAGE_MO=1.70
COST_GCS_GB_MO=0.02

# --- Helpers ---
header() {
    echo "===================================================="
    echo "           KLOUDSHOP DB COST CONTROLLER             "
    echo "===================================================="
}

get_instance_state() {
    # Returns: RUNNING, STOPPED, or DELETED
    DESC=$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format="json(settings.activationPolicy,state)" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "DELETED"
        return
    fi
    POLICY=$(echo $DESC | jq -r '.settings.activationPolicy')
    STATE=$(echo $DESC | jq -r '.state')
    
    if [ "$POLICY" == "ALWAYS" ] && [ "$STATE" == "RUNNABLE" ]; then
        echo "RUNNING"
    elif [ "$POLICY" == "NEVER" ]; then
        echo "STOPPED"
    else
        echo "TRANSITIONING"
    fi
}

do_backup() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_URI="${BACKUP_BUCKET}/archive_${INSTANCE_NAME}_${TIMESTAMP}.sql.gz"
    echo "[INFO] Creating safety archive in GCS: $BACKUP_URI..."
    gcloud sql export sql $INSTANCE_NAME $BACKUP_URI --database=postgres --project=$PROJECT_ID --quiet
    echo "[SUCCESS] Archive saved. Estimated storage cost: ~$0.02/mo."
}

# --- Main Flow ---
header
STATE=$(get_instance_state)
echo "CURRENT STATE: [$STATE]"
echo "----------------------------------------------------"

if [ "$STATE" == "RUNNING" ]; then
    echo "Actions:"
    echo "  [1] STOP Instance"
    echo "      - Stops the $COST_COMPUTE_HR/hr compute charge."
    echo "      - Storage charge of ~$COST_STORAGE_MO/mo continues."
    echo ""
    echo "  [2] ARCHIVE & DELETE (Zero-Cost)"
    echo "      - Moves data to GCS (~$COST_GCS_GB_MO/mo)."
    echo "      - Deletes instance (Stop all SQL billing)."
    echo ""
    read -p "Choose action [1-2 or Q to quit]: " choice
    case $choice in
        1)
            gcloud sql instances patch $INSTANCE_NAME --activation-policy=NEVER --project=$PROJECT_ID
            ;;
        2)
            do_backup
            gcloud sql instances delete $INSTANCE_NAME --project=$PROJECT_ID --quiet
            ;;
        *) exit 0 ;;
    esac

elif [ "$STATE" == "STOPPED" ]; then
    echo "Actions:"
    echo "  [1] START Instance"
    echo "      - Resumes the $COST_COMPUTE_HR/hr compute charge."
    echo ""
    echo "  [2] ARCHIVE & DELETE (Zero-Cost)"
    echo "      - Moves data to GCS (~$COST_GCS_GB_MO/mo)."
    echo "      - Deletes instance (Stop all SQL billing)."
    echo ""
    read -p "Choose action [1-2 or Q to quit]: " choice
    case $choice in
        1)
            gcloud sql instances patch $INSTANCE_NAME --activation-policy=ALWAYS --project=$PROJECT_ID
            ;;
        2)
            # Must start instance briefly to export
            echo "[WAIT] Starting instance briefly to perform backup..."
            gcloud sql instances patch $INSTANCE_NAME --activation-policy=ALWAYS --project=$PROJECT_ID
            do_backup
            gcloud sql instances delete $INSTANCE_NAME --project=$PROJECT_ID --quiet
            ;;
        *) exit 0 ;;
    esac

elif [ "$STATE" == "DELETED" ]; then
    echo "Actions:"
    echo "  [1] RECREATE from Backup"
    echo "      - Will create a new $TIER instance."
    echo "      - Will import the latest backup from GCS."
    echo "      - Takes 5-10 minutes."
    echo ""
    read -p "Choose action [1 or Q to quit]: " choice
    case $choice in
        1)
            # List backups
            echo "Latest backups in $BACKUP_BUCKET:"
            gsutil ls -l "$BACKUP_BUCKET/archive_*" | tail -n 5
            read -p "Paste the full gs:// URI of the backup to restore: " BKP_URI
            
            echo "[INFO] Recreating instance..."
            gcloud sql instances create $INSTANCE_NAME --project=$PROJECT_ID --database-version=POSTGRES_15 --tier=$TIER --region=$REGION --zone=$ZONE --root-password="REPLACE_ME"
            
            echo "[INFO] Restoring data..."
            gcloud sql import sql $INSTANCE_NAME $BKP_URI --database=postgres --project=$PROJECT_ID --quiet
            ;;
        *) exit 0 ;;
    esac
fi
