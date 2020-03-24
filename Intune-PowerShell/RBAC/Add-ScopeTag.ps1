$scope = "https://graph.microsoft.com/.default"
$Tenant = "yourtenant.onmicrosoft.com" #List here your tenants
$AppID = "23567e61-a6e4-4be3-xxxxx" #Change this to your own app ID
$AppSecret = "O7MTNZ[]L/xxxxxxxxx" #Change this to your own App Secret
$ScopeTagName = "YourScopeTagName"


$authHeader = @{
	'Content-Type' = 'application/x-www-form-urlencoded'
}

$authBody = @{
	'client_id'	    = $AppId
	'grant_type'    = "client_credentials"
	'client_secret' = "$AppSecret"
	'scope'		    = $scope
}

#Change token authority endpont
$authority = "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token"

#Get Access Token
$Request = Invoke-RestMethod -Headers $authHeader -Uri $authority -Body $authBody -Method POST
$AuthToken = @{
	Authorization = "Bearer $($Request.access_token)"
}

Write-Host "checking from tenant : $Tenant" -ForegroundColor Yellow

#URL for query autopilot device, always use filter, this moment only support contains as filter


$url = "https://graph.microsoft.com/beta/deviceManagement/roleScopeTags"
$ScopeTagID = ((Invoke-RestMethod -Uri $url -Method Get -Headers $authToken -ErrorAction SilentlyContinue).Value | Where-Object { $_.displayname -like $ScopeTagName }).id

$JSON = @"
{
  "roleScopeTagIds": []
}
"@


#URL for query autopilot device, always use filter, this moment only support contains as filter
$url = "https://graph.microsoft.com/beta/deviceManagement/managedDevices"
$DeviceResults = (Invoke-RestMethod -Uri $url -Method Get -Headers $authToken).Value | Where-Object { $_.operatingsystem -notcontains "Windows" -and $_.operatingsystem -notcontains "mac" }


foreach ($Device in $DeviceResults)
{
	$deviceID = $Device.id
	$url = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($deviceid)"
	$result = Invoke-RestMethod -Uri $url -Method Get -Headers $authToken
	
	if ($result.roleScopeTagIds -and ($result.roleScopeTagIds).contains("$ScopeTagId"))
	{
		write-host "$($Device.devicename) already have scopetag $($ScopeTagId)" -ForegroundColor Gray
	}
	else
	{
        $ScopeTags = @($result.roleScopeTagIds) + @("$ScopeTagId")		
		$object = New-Object -TypeName PSObject
		$object | Add-Member -MemberType NoteProperty -Name 'roleScopeTagIds' -Value @($ScopeTags)
		$JSON = $object | ConvertTo-Json
		
		Write-Host "start adding scopetag to $($Device.devicename), scopetag $($ScopeTags)" -ForegroundColor Green
		$url = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($deviceid)"
		Invoke-RestMethod -Uri $url -Headers $authToken -Method Patch -Body $JSON -ContentType "application/json"
		
		Start-Sleep -Milliseconds 100
	}	
}
