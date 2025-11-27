# Configure Intune Enrollment for Azure China
# This script configures MDM URLs in CloudDomainJoin registry and triggers Intune enrollment

Write-Host "Starting Intune enrollment configuration for Azure China..."

# Find the tenant ID from CloudDomainJoin registry
$key = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\*'
$keyinfo = Get-Item "HKLM:\$key" -ErrorAction SilentlyContinue

if ($keyinfo) {
    $url = $keyinfo.Name
    $url = $url.Split('\')[-1]
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$url"
    
    Write-Host "Found tenant ID: $url"
    Write-Host "Setting China Intune MDM URLs..."
    
    # Set China-specific MDM URLs
    New-ItemProperty -LiteralPath $path -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoftonline.cn/enrollmentserver/discovery.svc' -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -LiteralPath $path -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoftonline.cn/TermsofUse.aspx' -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -LiteralPath $path -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoftonline.cn/?portalAction=Compliance' -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "China Intune MDM URLs configured successfully."
} else {
    Write-Error "CloudDomainJoin TenantInfo not found. Ensure VM is Entra joined first."
    exit 1
}

# Create scheduled task to trigger Intune enrollment
Write-Host "Creating scheduled task for Intune enrollment..."

$triggers = @()
$triggers += New-ScheduledTaskTrigger -At (Get-Date) -Once -RepetitionInterval (New-TimeSpan -Minutes 1)

$User = "SYSTEM"
$Action = New-ScheduledTaskAction -Execute "$env:windir\system32\deviceenroller.exe" -Argument "/c /AutoEnrollMDM"

# Add action to check enrollment status and cleanup task
$cleanupScript = @"
`$enrollmentPath = 'HKLM:\SOFTWARE\Microsoft\Enrollments\*'
`$enrollments = Get-Item `$enrollmentPath -ErrorAction SilentlyContinue | Where-Object { `$_.Property -contains 'ProviderID' }
foreach (`$enrollment in `$enrollments) {
    `$providerID = Get-ItemPropertyValue -Path `$enrollment.PSPath -Name 'ProviderID' -ErrorAction SilentlyContinue
    if (`$providerID -eq 'MS DM Server') {
        Write-Host 'Device is enrolled in Intune (ProviderID: MS DM Server). Removing scheduled task...'
        Unregister-ScheduledTask -TaskName 'TriggerEnrollment' -Confirm:`$false
        exit 0
    }
}
"@

$cleanupScriptPath = "$env:TEMP\Check-IntuneEnrollment.ps1"
Set-Content -Path $cleanupScriptPath -Value $cleanupScript -Force

# Create a second action to check and cleanup
$CleanupAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$cleanupScriptPath`""

Register-ScheduledTask -TaskName "TriggerEnrollment" -Trigger $triggers -User $User -Action @($Action, $CleanupAction) -Force | Out-Null
Start-ScheduledTask -TaskName "TriggerEnrollment"

Write-Host "Intune enrollment scheduled task created and started successfully."
Write-Host "Enrollment will be triggered every minute until the device is enrolled."
Write-Host "Task will automatically remove itself once enrollment is detected."
