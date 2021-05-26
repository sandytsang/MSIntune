<#
.SYNOPSIS
    This script is for getting no MFA registered users, use in Azure Automation Account

.DESCRIPTION
    This script will get no MFA registered users

.NOTES
    File name: Set-PrimaryUser.ps1
    VERSION: 1.0.0
    AUTHOR: Sandy Zeng
    Created:  2021-05-26
    COPYRIGHT: Sandy Zeng
    Sandy Zeng / https://www.sandyzeng.com
    Licensed under the MIT license.
    Please credit me if you find this script useful and do some cool things with it.


.VERSION HISTORY:
    1.0.0 - (2021-05-26) Script created

#>

#Require MSAL.PS module
Import-Module -Name MSAL.PS

$scope = "https://graph.microsoft.com/.default"
$Tenant = "mvp24.onmicrosoft.com" #List here your tenants
$authority = "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token"
$AppID = "f38c1076-cbf2-48a5-" #Change this to your own app ID
$AppSecret = ConvertTo-SecureString "O5m7k9cuyM_" -AsPlainText -Force #Change this to your own app secret

<#
#If use Azure Automation
$AppID = Get-AutomationVariable -Name "AppID" #Change this to your own app ID
$AppSecret = ConvertTo-SecureString (Get-AutomationVariable -Name "AppSecret") -AsPlainText -Force #Change this to your own app secret
#>

# Get Tokens
try {
    ###Get Access Token for Application permission
    $requestApp = Get-MsalToken -ClientId $AppID -ClientSecret $AppSecret -TenantId $Tenant -Authority $authority -Scopes $scope #-RedirectUri $RedirectUrl
    $AuthTokenApp = @{
        Authorization = $requestApp.CreateAuthorizationHeader()
        ConsistencyLevel = 'eventual'
    }
}
catch {
    Write-Output  "$_.Exception.Message"
    Exit 1
}

#Get all Intune managed devices
$IntuneDevices = @()
$Resource = "deviceManagement/managedDevices?`$filter=(Notes%20eq%20%27bc3e5c73-e224-4e63-9b2b-0c36784b7e80%27)%20and%20(((deviceType%20eq%20%27desktop%27)%20or%20(deviceType%20eq%20%27windowsRT%27)%20or%20(deviceType%20eq%20%27winEmbedded%27)%20or%20(deviceType%20eq%20%27surfaceHub%27)))"
$url = "https://graph.microsoft.com/beta/$($Resource)"

do {
    $RetryIn = "0"
    $ThrottledRun = $false

    try {
        $IntuneDevicesRespond = Invoke-RestMethod -Method Get -Uri $url -Headers $AuthTokenApp
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        $MyError = $_.Exception
        if (($MyError.Response.StatusCode) -eq "429") {
            $ThrottledRun = $true
            $RetryIn = $MyError.Response.Headers["Retry-After"]
            Write-Warning -Message "Graph queries is being throttled by Microsoft"
            Write-Output "Settings throttle retry to $($RetryIn)"
        }
        else {
            Write-Error -Message "Inital graph query failed with $ErrorMessage"
        }
    }

    if ($ThrottledRun -eq $false) {
        #If request is not throttled put data into result object
        $IntuneDevices += $IntuneDevicesRespond.value

        #If a request is not throttled, go to the next link if available to fetch more data
        $url = $IntuneDevicesRespond.'@odata.nextlink'
    }

    Start-Sleep -Seconds $RetryIn
}
Until (!($url))


Foreach ($IntuneDevice in $IntuneDevices) {
    #Get last LoggedOn UserId
    $LastLoggedOnUserId = $IntuneDevices.usersLoggedOn[-1].userId

    if ($LastLoggedOnUserId -ne $null) {

        #Get Intune Managed Device ID
        $IntuneDeviceId = $IntuneDevice.id

        #Get Primary User ID
        $Resource = "deviceManagement/managedDevices"
	    $url = "https://graph.microsoft.com/beta/$($Resource)" + "/" + $IntuneDeviceId + "/users"

        try {
            $PrimaryUser = (Invoke-RestMethod -Method Get -Uri $url -Headers $AuthTokenApp).value.id
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            Write-Error -Message "Inital graph query failed with $ErrorMessage"
        }

        #Set Primary user if it is not same as last logged on user
        if ($LastLoggedOnUserId -ne $PrimaryUser ) {
            Write-Host "Device name: $($IntuneDevice.deviceName)" -ForegroundColor Cyan
            Write-Host "Last LoggedOn User: $($LastLoggedOnUserId)" -ForegroundColor Cyan
            Write-Host "Primary name: $($PrimaryUser)" -ForegroundColor Green

            #Intune Graph API primary user resource url
            $Resource = "deviceManagement/managedDevices('$IntuneDeviceId')/users/`$ref"
            $url = "https://graph.microsoft.com/beta/$($Resource)"

            #Set Azure AD user url
            $userUrl = "https://graph.microsoft.com/beta/users/" + $LastLoggedOnUserId

            #Set Primary user json
            $id = "@odata.id"
            $JSON = @{ $id="$userUrl" } | ConvertTo-Json -Compress

            #Set Primary user for Intune device
            try {
                Invoke-RestMethod -Uri $url -Headers $AuthTokenApp -Method Post -Body $JSON -ContentType "application/json"
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error -Message "Inital graph query failed with $ErrorMessage"
            }

        }
    }
}

