<#
.SYNOPSIS
Automatically updates the primary user for Intune managed Windows devices based on sign in activity.

.DESCRIPTION
This script runs in an Azure Automation environment to update the primary user for Intune managed Windows devices based on sign in activity.
Converted to use direct REST API calls without any PowerShell modules.

.NOTES
Author:      Sandy Zeng

Required API Permissions (Application):
DeviceManagementManagedDevices.ReadWrite.All
AuditLog.Read.All
User.Read.All
#>

#region Variables
$dateRangeDays = 30 # Number of days to look back for sign in activity
$dataToday = Get-Date
$dateRange = $dataToday.AddDays(-$dateRangeDays)

$UpdateCount = 0
#endregion

#region Functions

function Get-ManagedIdentityToken {
    [CmdletBinding()]
    param (
        [string]$ResourceURI = "https://graph.microsoft.com"
    )
    Process {
        # Determine which managed identity endpoint is available
        if ($env:IDENTITY_ENDPOINT -and $env:IDENTITY_HEADER) {
            $Endpoint = ($env:IDENTITY_ENDPOINT).Trim()
            $Secret = $env:IDENTITY_HEADER
            $HeaderName = "X-IDENTITY-HEADER"
            $APIVersion = "2019-08-01"
        }
        elseif ($env:MSI_ENDPOINT -and $env:MSI_SECRET) {
            $Endpoint = ($env:MSI_ENDPOINT).Trim()
            $Secret = $env:MSI_SECRET
            $HeaderName = "Secret"
            $APIVersion = "2017-09-01"
        }
        else {
            throw "No managed identity endpoint found. Ensure the Automation Account has a system-assigned managed identity enabled."
        }

        # Validate the endpoint URI
        $TestUri = $null
        if (-not [System.Uri]::TryCreate($Endpoint, [System.UriKind]::Absolute, [ref]$TestUri)) {
            throw "Managed identity endpoint is not a valid URI: '$Endpoint'"
        }

        # Build the token request URI
        $Separator = if ($Endpoint.Contains("?")) { "&" } else { "?" }
        $AuthURI = "${Endpoint}${Separator}resource=${ResourceURI}&api-version=${APIVersion}"

        Write-Information " - Requesting token from: $AuthURI"

        $Response = Invoke-RestMethod -Uri $AuthURI -Method Get -Headers @{ $HeaderName = $Secret } -ErrorAction Stop

        # Return auth header
        return @{
            "Authorization" = "Bearer $($Response.access_token)"
            "Content-Type"  = "application/json"
        }
    }
}

function Invoke-GraphRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [hashtable]$Headers,

        [ValidateSet("Get", "Post", "Delete", "Patch")]
        [string]$Method = "Get",

        [string]$Body,

        [switch]$AllPages
    )
    Process {
        if ($AllPages -and $Method -eq "Get") {
            # Handle pagination
            $Results = [System.Collections.Generic.List[object]]::new()
            $url = $Uri
            do {
                try {
                    $Response = Invoke-RestMethod -Uri $url -Method $Method -Headers $Headers -ErrorAction Stop
                }
                catch {
                    $StatusCode = $_.Exception.Response.StatusCode
                    throw "Graph API request failed (${Method} ${url}). Status: $StatusCode. Error: $($_.Exception.Message)"
                }
                if ($Response.value) {
                    foreach ($item in $Response.value) {
                        $Results.Add($item)
                    }
                }
                $url = $Response.'@odata.nextLink'
            } while ($url)
            return $Results
        }
        else {
            $Params = @{
                Uri         = $Uri
                Method      = $Method
                Headers     = $Headers
                ErrorAction = "Stop"
            }
            if ($Body) {
                $Params.Add("Body", $Body)
            }
            try {
                $Response = Invoke-RestMethod @Params
                return $Response
            }
            catch {
                $StatusCode = $_.Exception.Response.StatusCode
                throw "Graph API request failed (${Method} ${Uri}). Status: $StatusCode. Error: $($_.Exception.Message)"
            }
        }
    }
}

#endregion

#region MainScript

Write-Output "[Initialising] Starting Automation Runbook"
Write-Output "  Date range     : $($dateRange.ToString('yyyy-MM-ddTHH:mm:ssZ')) to $($dataToday.ToString('yyyy-MM-ddTHH:mm:ssZ'))"

# Acquire managed identity token
Write-Output "[Authentication] Acquiring managed identity token"
try {
    $Script:AuthHeaders = Get-ManagedIdentityToken -ResourceURI "https://graph.microsoft.com"
    Write-Output "  Token acquired successfully"
}
catch {
    Write-Error "[Authentication] Failed: $($_.Exception.Message)"
    exit 1
}

# Get all Windows devices
try {
    Write-Output "[Devices] Fetching Intune managed Windows devices"
    $DeviceUrl = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$select=userPrincipalName,deviceName,azureADDeviceId,id"
    $IntuneDevices = Invoke-GraphRequest -Uri $DeviceUrl -Headers $Script:AuthHeaders -Method Get -AllPages
    Write-Output "  Found $($IntuneDevices.Count) devices"
}
catch {
    Write-Error "[Devices] Failed to retrieve devices: $($_.Exception.Message)"
    exit 1
}

# Gather sign in events
try {
    Write-Output "[Sign-ins] Fetching Windows Sign In events from the last $dateRangeDays days"
    $DateFilter = $dateRange.ToString('yyyy-MM-ddTHH:mm:ssZ')

    # Query interactive sign-ins only
    $SignInUrl = "https://graph.microsoft.com/beta/auditLogs/signIns?`$filter=(appDisplayName eq 'Windows Sign In') and (createdDateTime ge $DateFilter)"
    $RawSignInEvents = Invoke-GraphRequest -Uri $SignInUrl -Headers $Script:AuthHeaders -Method Get -AllPages
    Write-Output "  Found $($RawSignInEvents.Count) interactive sign-in events:"

    # Process sign in events - extract deviceId (no isManaged filter; we already match against Intune devices later)
    $SignInEvents = [System.Collections.Generic.List[object]]::new()
    foreach ($SignInEvent in $RawSignInEvents) {
        $DevId = $SignInEvent.deviceDetail.deviceId
        if (-not([string]::IsNullOrEmpty($DevId))) {
            $SignInEvents.Add([PSCustomObject]@{
                UserId            = $SignInEvent.userId
                UserPrincipalName = $SignInEvent.userPrincipalName
                CreatedDateTime   = $SignInEvent.createdDateTime
                DeviceId          = $DevId
            })
            Write-Output "    - $($SignInEvent.userPrincipalName) | DeviceId: $DevId | Date: $($SignInEvent.createdDateTime)"
        }
    }

    Write-Output "  $($SignInEvents.Count) events matched to devices after filtering"
}
catch {
    Write-Error "[Sign-ins] Failed to retrieve sign-in events: $($_.Exception.Message)"
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
        $PrimaryUserPrincipalName = [string]($Device.userPrincipalName).ToLower()
        $DeviceLabel = "$($Device.deviceName) ($($Device.azureADDeviceId))"
        Write-Output "[Processing] $DeviceLabel | Current primary user: $(if ($PrimaryUserPrincipalName) { $PrimaryUserPrincipalName } else { '<none>' })"
        $UserActivity = $SignInEvents | Where-Object { $_.DeviceId -eq $Device.azureADDeviceId } | Group-Object UserPrincipalName | Sort-Object Count -Descending | Select-Object -First 1

        # If sign in activity is not null, compare against primary user
        if ($null -ne $UserActivity) {
            $FrequentUserPrincipalName = [string]($UserActivity.Name).ToLower()
            $FrequentUserID = $UserActivity.Group.UserId | Select-Object -First 1
            if (-not([string]::IsNullOrEmpty($FrequentUserPrincipalName))) {
                Write-Output "  Most frequent user: $FrequentUserPrincipalName ($($UserActivity.Count) sign-ins)"
            }

            # If primary user does not match sign in activity (or is empty), update primary user
            if (-not([string]::IsNullOrEmpty($FrequentUserPrincipalName)) -and ($FrequentUserPrincipalName -ne $PrimaryUserPrincipalName) -and ($UserActivity.Count -gt 1)) {
                    try {
                        $URI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$($Device.id)')/users/`$ref"

                        Write-Output "  >> Changing primary user: $(if ($PrimaryUserPrincipalName) { $PrimaryUserPrincipalName } else { '<none>' }) -> $FrequentUserPrincipalName"
                        $JsonPayload = @{ "@odata.id" = "https://graph.microsoft.com/beta/users/$FrequentUserID" } | ConvertTo-Json
                        Invoke-GraphRequest -Uri $URI -Headers $Script:AuthHeaders -Method Post -Body $JsonPayload

                        $AutomationSummary.Add([PSCustomObject]@{
                            "Intune Device ID"  = $Device.azureADDeviceId
                            "Azure AD Device ID" = $Device.id
                            "Computer Name"      = $Device.deviceName
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

    exit 0
}
else {
    Write-Error "[Sign-ins] No sign-in events found in the last $dateRangeDays days. Nothing to process."
    exit 1
}

#endregion
