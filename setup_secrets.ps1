$project = "kloudshop-dev"
$saEmail = "github-actions@$project.iam.gserviceaccount.com"
$roles = @(
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin",
    "roles/cloudbuild.builds.editor",
    "roles/firebase.admin",
    "roles/apiKeys.viewer"
)

foreach ($role in $roles) {
    Write-Host "Adding role $role..."
    gcloud projects add-iam-policy-binding $project --member="serviceAccount:$saEmail" --role="$role" --condition=None --quiet
}

Write-Host "Generating key..."
gcloud iam service-accounts keys create sa-key.json --iam-account=$saEmail --project=$project

Write-Host "Setting GitHub Secrets..."
Get-Content sa-key.json -Raw | gh secret set GCP_CREDENTIALS
Get-Content sa-key.json -Raw | gh secret set FIREBASE_SERVICE_ACCOUNT

Write-Host "Cleaning up key..."
Remove-Item sa-key.json

Write-Host "Done!"
