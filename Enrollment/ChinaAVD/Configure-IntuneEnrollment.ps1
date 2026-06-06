<#
.SYNOPSIS
    Configure Intune Enrollment for Azure Virtual Desktop in Azure China Cloud

.DESCRIPTION
    This script automates the Intune enrollment process for Azure Virtual Desktop (AVD) session hosts 
    deployed in Azure China (21Vianet). It performs the following tasks:
    
    1. Configures China-specific MDM (Mobile Device Management) discovery URLs in the CloudDomainJoin registry
    2. Sets the assigned user's UPN in the JoinInfo registry for user-based enrollment
    3. Creates a scheduled task to trigger automatic Intune enrollment
    4. Monitors enrollment status and automatically removes the scheduled task once enrollment completes
    
    This script is designed to run as a CustomScriptExtension during AVD VM deployment and requires 
    the VM to be Entra ID (Azure AD) joined before execution.

.PARAMETER UserUpn
    The User Principal Name (UPN) of the user assigned to this personal desktop VM (e.g., user@domain.com).
    This is required for Intune enrollment in personal desktop pools.

.EXAMPLE
    .\Configure-IntuneEnrollment.ps1 -UserUpn "john.doe@contoso.com"

.NOTES
    Author:         Sandy Zeng
    Company:        CloudWay
    Date:           November 27, 2025
    Version:        1.0
    
    Requirements:
    - VM must be Entra ID (Azure AD) joined
    - Running in Azure China Cloud (21Vianet)
    - Intune tenant configured for China region
    - User must have appropriate Intune licenses
    
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$UserUpn
)

Write-Host "Starting Intune enrollment configuration for Azure China..."
Write-Host "Assigned user UPN: $UserUpn"

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

# Set UserEmail in JoinInfo registry for Intune enrollment
Write-Host "Configuring UserEmail in CloudDomainJoin JoinInfo..."

$joinInfoPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\*'
$joinInfo = Get-Item $joinInfoPath -ErrorAction SilentlyContinue

if ($joinInfo) {
    foreach ($ji in $joinInfo) {
        Write-Host "Found JoinInfo GUID: $($ji.PSChildName)"
        New-ItemProperty -LiteralPath $ji.PSPath -Name 'UserEmail' -Value $UserUpn -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host "UserEmail set to: $UserUpn"
    }
} else {
    Write-Warning "CloudDomainJoin JoinInfo not found. This may be set after user login."
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
