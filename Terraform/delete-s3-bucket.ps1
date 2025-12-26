# Script to delete all versions from S3 bucket
$bucketName = "devops-project-terraform-state-724772082485"

Write-Host "Deleting all object versions from bucket: $bucketName" -ForegroundColor Yellow

# List and delete all object versions
$versions = aws s3api list-object-versions --bucket $bucketName | ConvertFrom-Json

if ($versions.Versions) {
    foreach ($version in $versions.Versions) {
        Write-Host "Deleting version: $($version.Key) ($($version.VersionId))" -ForegroundColor Gray
        aws s3api delete-object --bucket $bucketName --key $version.Key --version-id $version.VersionId
    }
}

if ($versions.DeleteMarkers) {
    foreach ($marker in $versions.DeleteMarkers) {
        Write-Host "Deleting delete marker: $($marker.Key) ($($marker.VersionId))" -ForegroundColor Gray
        aws s3api delete-object --bucket $bucketName --key $marker.Key --version-id $marker.VersionId
    }
}

Write-Host "All versions deleted. Now deleting bucket..." -ForegroundColor Green
aws s3api delete-bucket --bucket $bucketName

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Bucket deleted successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to delete bucket" -ForegroundColor Red
}
