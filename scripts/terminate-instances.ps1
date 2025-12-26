# Clean Deployment Script - Terminate All EC2 Instances
# This ensures a clean slate before running GitHub Actions deployment

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        EC2 Instance Cleanup for Clean Deployment          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Disable AWS pager to avoid 'cat' errors
$env:AWS_PAGER = ""

# Step 1: Find all running and shutting-down instances
Write-Host "🔍 Searching for EC2 instances..." -ForegroundColor Yellow

try {
    $instancesJson = aws ec2 describe-instances --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error: Failed to connect to AWS" -ForegroundColor Red
        Write-Host "   Make sure AWS CLI is configured with valid credentials." -ForegroundColor Red
        exit 1
    }
    
    $allInstances = ($instancesJson | ConvertFrom-Json).Reservations.Instances
    
    # Filter out already terminated instances
    $instances = $allInstances | Where-Object { $_.State.Name -ne 'terminated' }
    
    if ($instances.Count -eq 0) {
        Write-Host "✅ No running instances found!" -ForegroundColor Green
        Write-Host "   Your AWS account is clean. Ready for deployment!" -ForegroundColor Green
        Write-Host ""
        exit 0
    }
    
    # Step 2: Display found instances
    Write-Host ""
    Write-Host "📋 Found $($instances.Count) instance(s) to terminate:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($inst in $instances) {
        $name = ($inst.Tags | Where-Object { $_.Key -eq 'Name' }).Value
        $state = $inst.State.Name
        $stateColor = if ($state -eq 'running') { 'White' } else { 'Gray' }
        Write-Host "  • $($inst.InstanceId) - $name [$state]" -ForegroundColor $stateColor
    }
    
    Write-Host ""
    
    # Step 3: Confirmation
    Write-Host "⚠️  WARNING: This will TERMINATE all listed instances!" -ForegroundColor Red
    Write-Host "   Type 'yes' to confirm, or anything else to cancel: " -ForegroundColor Yellow -NoNewline
    $confirm = Read-Host
    
    if ($confirm -ne 'yes') {
        Write-Host ""
        Write-Host "❌ Cancelled. No instances were terminated." -ForegroundColor Yellow
        exit 0
    }
    
    # Step 4: Terminate instances
    Write-Host ""
    Write-Host "🧹 Terminating instances..." -ForegroundColor Cyan
    
    $instanceIds = $instances | ForEach-Object { $_.InstanceId }
    $idList = $instanceIds -join " "
    
    $terminateResult = aws ec2 terminate-instances --instance-ids $idList --output json 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error: Termination command failed" -ForegroundColor Red
        Write-Host "   $terminateResult" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Termination command sent successfully!" -ForegroundColor Green
    
    # Step 5: Wait for termination to complete
    Write-Host ""
    Write-Host "⏳ Waiting for instances to terminate (max 60 seconds)..." -ForegroundColor Cyan
    
    $maxWait = 60
    $waited = 0
    $checkInterval = 5
    
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds $checkInterval
        $waited += $checkInterval
        
        $currentInstances = (aws ec2 describe-instances --output json | ConvertFrom-Json).Reservations.Instances
        $remaining = $currentInstances | Where-Object { 
            $_.InstanceId -in $instanceIds -and $_.State.Name -ne 'terminated' 
        }
        
        if ($remaining.Count -eq 0) {
            Write-Host "✅ All instances terminated successfully!" -ForegroundColor Green
            break
        }
        
        Write-Host "   Still terminating... ($($remaining.Count) remaining)" -ForegroundColor Gray
    }
    
    if ($waited -ge $maxWait) {
        Write-Host "⚠️  Timeout: Some instances may still be terminating" -ForegroundColor Yellow
        Write-Host "   Check AWS Console to verify termination" -ForegroundColor Yellow
    }
    
    # Step 6: Success message
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                 ✅ CLEANUP COMPLETE ✅                     ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Your AWS account is now clean!" -ForegroundColor Green
    Write-Host "   You can safely run the GitHub Actions deployment workflow." -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ Error occurred: $_" -ForegroundColor Red
    exit 1
}
