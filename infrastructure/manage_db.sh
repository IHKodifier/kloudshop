#!/bin/bash
# GCP Cloud SQL Management Script for KloudShop
# This script helps start, stop, and backup the development Cloud SQL instance to save costs.

PROJECT_ID="kloudshop-dev" # Update this with the actual dev project ID
INSTANCE_NAME="kloudshop-db-dev"
BACKUP_BUCKET="gs://kloudshop-dev-db-backups" # Bucket must exist

usage() {
    echo "Usage: $0 {start|stop|backup|restore}"
    echo "  start   - Starts the Cloud SQL instance."
    echo "  stop    - Stops the Cloud SQL instance to pause billing."
    echo "  backup  - Exports the current database to Cloud Storage (costs less than keeping SQL running)."
    echo "  restore - Imports a backup from Cloud Storage into the instance."
    exit 1
}

case "$1" in
    start)
        echo "Starting Cloud SQL instance: $INSTANCE_NAME..."
        gcloud sql instances patch $INSTANCE_NAME --activation-policy=ALWAYS --project=$PROJECT_ID
        echo "Instance started."
        ;;
    stop)
        echo "Stopping Cloud SQL instance: $INSTANCE_NAME..."
        gcloud sql instances patch $INSTANCE_NAME --activation-policy=NEVER --project=$PROJECT_ID
        echo "Instance stopped."
        ;;
    backup)
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        BACKUP_URI="${BACKUP_BUCKET}/backup_${INSTANCE_NAME}_${TIMESTAMP}.sql.gz"
        echo "Exporting database to $BACKUP_URI..."
        gcloud sql export sql $INSTANCE_NAME $BACKUP_URI --database=postgres --project=$PROJECT_ID
        echo "Backup complete."
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "Error: Please provide the Cloud Storage URI of the backup to restore."
            echo "Example: $0 restore gs://kloudshop-dev-db-backups/backup_kloudshop-db-dev_2026...sql.gz"
            exit 1
        fi
        echo "Restoring database from $2..."
        gcloud sql import sql $INSTANCE_NAME "$2" --database=postgres --project=$PROJECT_ID
        echo "Restore complete."
        ;;
    *)
        usage
        ;;
esac
