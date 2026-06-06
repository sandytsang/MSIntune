# This Azure Function is designed to remove the primary user from Intune-managed devices that are members of specific Entra ID groups and match certain criteria.
# The function authenticates using the Function App's managed identity to call Microsoft Graph API, retrieves devices from specified Entra ID groups, checks for devices with names containing "MVP" and enrolled in Intune, and then removes the primary user association for those devices in Intune.
# Note: This function uses the Microsoft Graph API beta endpoint, which may be subject to change. Ensure you have the necessary permissions assigned to the Function App's managed identity to read group memberships and manage Intune devices.
# Input: HTTP trigger
# Output: JSON response with the results of the operation for each processed device.
# Remember change your Entra Group ID in the $EntraGroupIds variable before running the function and change your device name filter in the if condition to target the correct devices. The current filter is set to look for devices with "MVP" in the name.
# Author: Sandy Zeng (@sandytsang)

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

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
            throw "No managed identity endpoint found. Ensure the Function App has a system-assigned managed identity enabled."
        }

        # Validate the endpoint URI
        $TestUri = $null
        if (-not [System.Uri]::TryCreate($Endpoint, [System.UriKind]::Absolute, [ref]$TestUri)) {
            throw "Managed identity endpoint is not a valid URI: '$Endpoint'"
        }

        # Build the token request URI
        $Separator = if ($Endpoint.Contains("?")) { "&" } else { "?" }
        $AuthURI = "${Endpoint}${Separator}resource=${ResourceURI}&api-version=${APIVersion}"

        $Response = Invoke-RestMethod -Uri $AuthURI -Method Get -Headers @{ $HeaderName = $Secret } -ErrorAction Stop

        # Return auth header
        return @{
            "Authorization" = "Bearer $($Response.access_token)"
            "Content-Type"  = "application/json"
        }
    }
}

# Retrieve authentication token
try {
    $Script:AuthToken = Get-ManagedIdentityToken
}
catch {
    Write-Error "Authentication failed: $($_.Exception.Message)"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body       = "Authentication failed: $($_.Exception.Message)"
    })
    return
}

# Entra Group Ids to process - consider moving to app settings
$EntraGroupIds = @(
    "07c0ae23-09b1-45ce-9f74-e63096a13c64" #Change this to your Entra Group ID
)

$Results = [System.Collections.Generic.List[object]]::new()

foreach ($EntraGroupId in $EntraGroupIds) {
    Write-Information "Processing Entra Group Id: $EntraGroupId"
    $url = "https://graph.microsoft.com/beta/groups/$EntraGroupId/members?`$select=id,deviceId,displayName,enrollmentType,mdmAppId"
    Write-Information "Getting members of Entra Group Id: $EntraGroupId"

    $GroupMembers = [System.Collections.Generic.List[object]]::new()
    try {
        do {
            $Response = Invoke-RestMethod -Method Get -Uri $url -Headers $Script:AuthToken -ErrorAction Stop
            if ($Response.value) {
                $GroupMembers.AddRange([object[]]$Response.value)
            }
            $url = $Response.'@odata.nextLink'
        } while ($url)
    }
    catch {
        Write-Error "Failed to retrieve group members for group $EntraGroupId : $($_.Exception.Message)"
        $Results.Add(@{ GroupId = $EntraGroupId; Error = "Failed to retrieve members: $($_.Exception.Message)" })
        continue
    }

    Write-Information "Total members retrieved: $($GroupMembers.Count)"

    foreach ($GroupMember in $GroupMembers) {
        $DeviceId = $GroupMember.deviceId
        $DeviceName = $GroupMember.displayName
        $JoinType = $GroupMember.enrollmentType
        $mdmAppId = $GroupMember.mdmAppId
        Write-Information "Processing Device: $DeviceName with DeviceId: $DeviceId, JoinType: $JoinType, MDM AppId: $mdmAppId"

        if ($DeviceName -like "*MVP*" -and $mdmAppId -eq '0000000a-0000-0000-c000-000000000000') { #Check for device name containing your own device name and enrolled in Intune (mdmAppId for Intune is 0000000a-0000-0000-c000-000000000000)

            # Get Intune managed device Id
            $intuneUrl = "https://graph.microsoft.com/beta/deviceManagement/manageddevices?`$filter=azureADDeviceId eq '$DeviceId'&`$select=id"
            Write-Information "Getting Intune Device Id for device: $DeviceName"

            try {
                $IntuneResponse = Invoke-RestMethod -Method Get -Uri $intuneUrl -Headers $Script:AuthToken -ErrorAction Stop
                $IntuneDeviceId = $IntuneResponse.value[0].id
            }
            catch {
                Write-Error "Failed to retrieve Intune device Id for $DeviceName ($DeviceId): $($_.Exception.Message)"
                $Results.Add(@{ Device = $DeviceName; DeviceId = $DeviceId; Status = "Failed"; Error = "Intune lookup failed: $($_.Exception.Message)" })
                continue
            }

            if (-not $IntuneDeviceId) {
                Write-Warning "Device $DeviceName ($DeviceId) not found in Intune, skipping."
                $Results.Add(@{ Device = $DeviceName; DeviceId = $DeviceId; Status = "Skipped"; Error = "Not found in Intune" })
                continue
            }

            Write-Information "Intune Device Id is: $IntuneDeviceId"

            # Remove primary user
            $deleteUrl = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$IntuneDeviceId')/users/`$ref"
            Write-Information "Removing Primary User for Intune Device: $IntuneDeviceId"

            try {
                Invoke-RestMethod -Method Delete -Uri $deleteUrl -Headers $Script:AuthToken -ErrorAction Stop
                Write-Information "Primary user removed successfully for device: $DeviceName ($IntuneDeviceId)"
                $Results.Add(@{ Device = $DeviceName; DeviceId = $DeviceId; IntuneDeviceId = $IntuneDeviceId; Status = "Success" })
            }
            catch {
                $StatusCode = $_.Exception.Response.StatusCode
                Write-Error "Failed to remove primary user for $DeviceName ($IntuneDeviceId). Status: $StatusCode. Error: $($_.Exception.Message)"
                $Results.Add(@{ Device = $DeviceName; DeviceId = $DeviceId; IntuneDeviceId = $IntuneDeviceId; Status = "Failed"; Error = "Delete failed ($StatusCode): $($_.Exception.Message)" })
            }
        }
        else {
            Write-Information "Device: $DeviceName is not in correct device name filter or not enrolled in Intune."
        }
    }
}

# Return HTTP response
$Body = @{
    Message = "Processing complete"
    Results = $Results
} | ConvertTo-Json -Depth 5

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $Body
    Headers    = @{ "Content-Type" = "application/json" }
})
