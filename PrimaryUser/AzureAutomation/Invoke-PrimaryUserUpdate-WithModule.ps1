<#
.SYNOPSIS
Automatically updates the primary user for Intune managed Windows devices based on sign in activity.

.DESCRIPTION
This script runs in an Azure Automation environment to update the primary user for Intune managed Windows devices based on sign in activity.
Uses Microsoft Graph PowerShell modules.

.NOTES
Author:      Maurice Daly, Jan Ketil Skanke and Sandy Zeng


Requires the following modules:
Microsoft.Graph.Authentication
Microsoft.Graph.Beta.DeviceManagement
Microsoft.Graph.Beta.DeviceManagement.Actions
Microsoft.Graph.Beta.Identity.DirectoryManagement
Microsoft.Graph.Beta.Users
Microsoft.Graph.Beta.Reports
#>

#region Variables
$dateRangeDays = 30 # Number of days to look back for sign in activity
$dataToday = Get-Date
$dateRange = $dataToday.AddDays(-$dateRangeDays)

$UpdateCount = 0
#endregion

#region MainScript

Write-Output "[Initialising] Starting Automation Runbook"
Write-Output "  Date range     : $($dateRange.ToString('yyyy-MM-ddTHH:mm:ssZ')) to $($dataToday.ToString('yyyy-MM-ddTHH:mm:ssZ'))"

# Import required PowerShell modules
Write-Output "[Modules] Importing required modules"
$RequiredModules = @('Microsoft.Graph.Authentication', 'Microsoft.Graph.Beta.DeviceManagement', 'Microsoft.Graph.Beta.DeviceManagement.Actions', 'Microsoft.Graph.Beta.Identity.DirectoryManagement', 'Microsoft.Graph.Beta.Users', 'Microsoft.Graph.Beta.Reports')
foreach ($RequiredModule in $RequiredModules) {
    try {
        Import-Module $RequiredModule -Force -ErrorAction Stop
        Write-Output "  Imported $RequiredModule"
    }
    catch {
        Write-Error "[Modules] Failed to import $RequiredModule : $($_.Exception.Message)"
        exit 1
    }
}

# Connect to Microsoft Graph
Write-Output "[Authentication] Connecting to Microsoft Graph"
try {
    Connect-AzAccount -Identity -ErrorAction Stop
    $Token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com" -ErrorAction Stop
    $SecureToken = $Token.Token | ConvertTo-SecureString -AsPlainText -Force
    Connect-MgGraph -AccessToken $SecureToken -NoWelcome -ErrorAction Stop
    Write-Output "  Connected successfully"
}
catch {
    Write-Error "[Authentication] Failed: $($_.Exception.Message)"
    exit 1
}

# Get all Windows devices
try {
    Write-Output "[Devices] Fetching Intune managed Windows devices"
    $IntuneDevices = Get-MgBetaDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'" -All -ErrorAction Stop | Select-Object -Property UserPrincipalName, DeviceName, AzureAdDeviceId, Id
    Write-Output "  Found $($IntuneDevices.Count) devices"
}
catch {
    Write-Error "[Devices] Failed to retrieve devices: $($_.Exception.Message)"
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    exit 1
}

# Gather sign in events (interactive only)
try {
    Write-Output "[Sign-ins] Fetching Windows Sign In events from the last $dateRangeDays days"
    $DateFilter = $dateRange.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $RawSignInEvents = Get-MgBetaAuditLogSignIn -Filter "(appDisplayName eq 'Windows Sign In') and (createdDateTime ge $DateFilter)" -All -ErrorAction Stop

    # Process sign in events - extract deviceId from deviceDetail
    $SignInEvents = [System.Collections.Generic.List[object]]::new()
    foreach ($SignInEvent in $RawSignInEvents) {
        $DevId = $SignInEvent.DeviceDetail.DeviceId
        if (-not([string]::IsNullOrEmpty($DevId))) {
            $SignInEvents.Add([PSCustomObject]@{
                UserId            = $SignInEvent.UserId
                UserPrincipalName = $SignInEvent.UserPrincipalName
                CreatedDateTime   = $SignInEvent.CreatedDateTime
                DeviceId          = $DevId
            })
        }
    }

    Write-Output "  Found $($RawSignInEvents.Count) interactive sign-in events:"
    foreach ($SignInEvent in $SignInEvents) {
        Write-Output "    - $($SignInEvent.UserPrincipalName) | DeviceId: $($SignInEvent.DeviceId) | Date: $($SignInEvent.CreatedDateTime)"
    }
    Write-Output "  $($SignInEvents.Count) events matched to devices after filtering"
}
catch {
    Write-Error "[Sign-ins] Failed to retrieve sign-in events: $($_.Exception.Message)"
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    exit 1
}

# Process if sign in events are greater than 0
if ($SignInEvents.Count -gt 0) {
    # Define summary list
    $AutomationSummary = [System.Collections.Generic.List[object]]::new()

    # For each device, get the primary user and update where required
    foreach ($Device in $IntuneDevices) {

        # Reset variables
        $PrimaryUserPrincipalName = $null
        $UserActivity = $null
        $FrequentUserPrincipalName = $null
        $FrequentUserID = $null

        # Obtain Primary user
        $PrimaryUserPrincipalName = [string]($Device.UserPrincipalName).ToLower()
        $DeviceLabel = "$($Device.DeviceName) ($($Device.AzureAdDeviceId))"
        Write-Output "[Processing] $DeviceLabel | Current primary user: $(if ($PrimaryUserPrincipalName) { $PrimaryUserPrincipalName } else { '<none>' })"

        $UserActivity = $SignInEvents | Where-Object { $_.DeviceId -eq $Device.AzureAdDeviceId } | Group-Object UserPrincipalName | Sort-Object Count -Descending | Select-Object -First 1

        # If sign in activity found, compare against primary user
        if ($null -ne $UserActivity) {
            $FrequentUserPrincipalName = [string]($UserActivity.Name).ToLower()
            $FrequentUserID = $UserActivity.Group.UserId | Select-Object -First 1
            if (-not([string]::IsNullOrEmpty($FrequentUserPrincipalName))) {
                Write-Output "  Most frequent user: $FrequentUserPrincipalName ($($UserActivity.Count) sign-ins)"
            }

            # If primary user does not match sign in activity (or is empty), update primary user
            if (-not([string]::IsNullOrEmpty($FrequentUserPrincipalName)) -and ($FrequentUserPrincipalName -ne $PrimaryUserPrincipalName) -and ($UserActivity.Count -gt 1)) {
                try {
                    $URI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$($Device.Id)')/users/`$ref"

                    Write-Output "  >> Changing primary user: $(if ($PrimaryUserPrincipalName) { $PrimaryUserPrincipalName } else { '<none>' }) -> $FrequentUserPrincipalName"
                    $JsonPayload = @{ "@odata.id" = "https://graph.microsoft.com/beta/users/$FrequentUserID" } | ConvertTo-Json
                    Invoke-MgGraphRequest -Method POST -Uri $URI -Body $JsonPayload -ErrorAction Stop

                    $AutomationSummary.Add([PSCustomObject]@{
                        "Intune Device ID"   = $Device.AzureAdDeviceId
                        "Azure AD Device ID" = $Device.Id
                        "Computer Name"      = $Device.DeviceName
                        "Old Primary User"   = $PrimaryUserPrincipalName
                        "New Primary User"   = $FrequentUserPrincipalName
                    })
                    $UpdateCount++
                }
                catch {
                    Write-Error "  [Error] Failed to update $DeviceLabel : $($_.Exception.Message)"
                }
            }
            else {
                Write-Output "  No change needed"
            }
        }
        else {
            Write-Output "  No sign-in activity found, skipping"
        }
    }

    # Output summary
    Write-Output ""
    Write-Output "[Summary] $UpdateCount device(s) updated"
    if ($AutomationSummary.Count -gt 0) {
        $TableOutput = ($AutomationSummary | Format-Table -AutoSize | Out-String).Trim()
        Write-Output $TableOutput
    }

    # Disconnect Graph session
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    exit 0
}
else {
    Write-Error "[Sign-ins] No sign-in events found in the last $dateRangeDays days. Nothing to process."
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    exit 1
}

#endregion
