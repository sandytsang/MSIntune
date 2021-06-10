function import-ADMX
{
<#
http://www.scconfigmgr.com/2019/01/17/use-intune-graph-api-export-and-import-intune-admx-templates/
Version 1.0 2019 Jan.17 First version


#>
	
	Param (
		
		[Parameter(Mandatory = $true)]
		[string]$ImportPath
		
	)
	
	####################################################
	
	function Get-AuthToken
	{
		
<#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>
		
		[cmdletbinding()]
		param
		(
			[Parameter(Mandatory = $true)]
			$User
		)
		
		$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
		
		$tenant = $userUpn.Host
		
		Write-Host "Checking for AzureAD module..."
		
		$AadModule = Get-Module -Name "AzureAD" -ListAvailable
		
		if ($AadModule -eq $null)
		{
			
			Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
			$AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
			
		}
		
		if ($AadModule -eq $null)
		{
			write-host
			write-host "AzureAD Powershell module not installed..." -f Red
			write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
			write-host "Script can't continue..." -f Red
			write-host
			exit
		}
		
		# Getting path to ActiveDirectory Assemblies
		# If the module count is greater than 1 find the latest version
		
		if ($AadModule.count -gt 1)
		{
			
			$Latest_Version = ($AadModule | select version | Sort-Object)[-1]
			
			$aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
			
			# Checking if there are multiple versions of the same module found
			
			if ($AadModule.count -gt 1)
			{
				
				$aadModule = $AadModule | select -Unique
				
			}
			
			$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
			$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
			
		}
		
		else
		{
			
			$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
			$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
			
		}
		
		[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
		
		[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
		
		$clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
		
		$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
		
		$resourceAppIdURI = "https://graph.microsoft.com"
		
		$authority = "https://login.microsoftonline.com/$Tenant"
		
		try
		{
			
			$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
			
			# https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
			# Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
			
			$platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
			
			$userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
			
			$authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters, $userId).Result
			
			# If the accesstoken is valid then create the authentication header
			
			if ($authResult.AccessToken)
			{
				
				# Creating header for Authorization token
				
				$authHeader = @{
					'Content-Type'  = 'application/json'
					'Authorization' = "Bearer " + $authResult.AccessToken
					'ExpiresOn'	    = $authResult.ExpiresOn
				}
				
				return $authHeader
				
			}
			
			else
			{
				
				Write-Host
				Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
				Write-Host
				break
				
			}
			
		}
		
		catch
		{
			
			write-host $_.Exception.Message -f Red
			write-host $_.Exception.ItemName -f Red
			write-host
			break
			
		}
		
	}
	
	####################################################
	
	Function Create-GroupPolicyConfigurations()
	{
		
<#
.SYNOPSIS
This function is used to add an device configuration policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a device configuration policy
.EXAMPLE
Add-DeviceConfigurationPolicy -JSON $JSON
Adds a device configuration policy in Intune
.NOTES
NAME: Add-DeviceConfigurationPolicy
#>
		
		[cmdletbinding()]
		param
		(
			$DisplayName
		)
		
		$jsonCode = @"
{
    "description":"",
    "displayName":"$($DisplayName)"
}
"@
		
		$graphApiVersion = "Beta"
		$DCP_resource = "deviceManagement/groupPolicyConfigurations"
		Write-Verbose "Resource: $DCP_resource"
		
		try
		{
			
			$uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
			$responseBody = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $jsonCode -ContentType "application/json"
			
			
		}
		
		catch
		{
			
			$ex = $_.Exception
			$errorResponse = $ex.Response.GetResponseStream()
			$reader = New-Object System.IO.StreamReader($errorResponse)
			$reader.BaseStream.Position = 0
			$reader.DiscardBufferedData()
			$responseBody = $reader.ReadToEnd();
			Write-Host "Response content:`n$responseBody" -f Red
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			write-host
			break
			
		}
		$responseBody.id
	}
	
	
	Function Create-GroupPolicyConfigurationsDefinitionValues()
	{
		
    <#
    .SYNOPSIS
    This function is used to get device configuration policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device configuration policies
    .EXAMPLE
    Get-DeviceConfigurationPolicy
    Returns any device configuration policies configured in Intune
    .NOTES
    NAME: Get-GroupPolicyConfigurations
    #>
		
		[cmdletbinding()]
		Param (
			
			[string]$GroupPolicyConfigurationID,
			$JSON
			
		)
		
		$graphApiVersion = "Beta"
		
		$DCP_resource = "deviceManagement/groupPolicyConfigurations/$($GroupPolicyConfigurationID)/definitionValues"
		write-host $DCP_resource
		try
		{
			if ($JSON -eq "" -or $JSON -eq $null)
			{
				
				write-host "No JSON specified, please specify valid JSON for the Device Configuration Policy..." -f Red
				
			}
			
			else
			{
				
				Test-JSON -JSON $JSON
				
				$uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
				Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
			}
			
		}
		
		catch
		{
			
			$ex = $_.Exception
			$errorResponse = $ex.Response.GetResponseStream()
			$reader = New-Object System.IO.StreamReader($errorResponse)
			$reader.BaseStream.Position = 0
			$reader.DiscardBufferedData()
			$responseBody = $reader.ReadToEnd();
			Write-Host "Response content:`n$responseBody" -f Red
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			write-host
			break
			
		}
		
	}
	
	
	####################################################

	Function Add-GroupPolicyConfigurationsAssignment(){

	<#
	.SYNOPSIS
	This function is used to assign a group to a group policy configuration using the Graph API REST interface
	.DESCRIPTION
	The function connects to the Graph API Interface and adds a device compliance policy assignment
	.EXAMPLE
	Add-GroupPolicyConfigurationsAssignment -GroupPolicyId $GroupPolicyConfigurationID -TargetGroupId $TargetGroupId
	Adds a group policy assignment in Intune
	.NOTES
	NAME: Add-GroupPolicyConfigurationsAssignment
	#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory = $false)]
	[string]$GroupPolicyId,
    [Parameter(Mandatory = $true)]
	[string]$TargetGroupId
)

$graphApiVersion = "beta"
$Resource = "deviceManagement/groupPolicyConfigurations/$GroupPolicyId/assign"
    
    try {

$JSON = @"

    {
        "assignments": [
        {
            "target": {
            "@odata.type": "#microsoft.graph.groupAssignmentTarget",
            "groupId": "$TargetGroupId"
            }
        }
        ]
    }
    
"@

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    Invoke-RestMethod -Uri $uri -ContentType "application/json" -Headers $authToken -Method Post -Body $JSON

    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################
	
	Function Test-JSON()
	{
		
<#
.SYNOPSIS
This function is used to test if the JSON passed to a REST Post request is valid
.DESCRIPTION
The function tests if the JSON passed to the REST Post is valid
.EXAMPLE
Test-JSON -JSON $JSON
Test if the JSON is valid before calling the Graph REST interface
.NOTES
NAME: Test-AuthHeader
#>
		
		param (
			
			$JSON
			
		)
		
		try
		{
			
			$TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
			$validJson = $true
			
		}
		
		catch
		{
			
			$validJson = $false
			$_.Exception
			
		}
		
		if (!$validJson)
		{
			
			Write-Host "Provided JSON isn't in valid JSON format" -f Red
			break
			
		}
		
	}
	
	####################################################
	
	#region Authentication
	
	write-host
	
	# Checking if authToken exists before running authentication
	if ($global:authToken)
	{
		
		# Setting DateTime to Universal time to work in all timezones
		$DateTime = (Get-Date).ToUniversalTime()
		
		# If the authToken exists checking when it expires
		$TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes
		
		if ($TokenExpires -le 0)
		{
			
			write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
			write-host
			
			# Defining User Principal Name if not present
			
			if ($User -eq $null -or $User -eq "")
			{
				
				$User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
				Write-Host
				
			}
			
			$global:authToken = Get-AuthToken -User $User
			
		}
	}
	
	# Authentication doesn't exist, calling Get-AuthToken function
	
	else
	{
		
		if ($User -eq $null -or $User -eq "")
		{
			
			$User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
			Write-Host
			
		}
		
		# Getting the authorization token
		$global:authToken = Get-AuthToken -User $User
		
	}
	
	#endregion
	
	####################################################
	
	$ImportPath = $ImportPath.replace('"', '')
	
	if (!(Test-Path "$ImportPath"))
	{
		
		Write-Host "Import Path doesn't exist..." -ForegroundColor Red
		Write-Host "Script can't continue..." -ForegroundColor Red
		break
		
	}
	$PolicyName = (Get-Item $ImportPath).Name
	Write-Host "Adding ADMX Configuration Policy '$PolicyName'" -ForegroundColor Yellow
	$GroupPolicyConfigurationID = Create-GroupPolicyConfigurations -DisplayName $PolicyName
	
	$JsonFiles = Get-ChildItem $ImportPath
	
	foreach ($JsonFile in $JsonFiles)
	{
		
		Write-Host "Adding ADMX Configuration setting $($JsonFile.Name)" -ForegroundColor Yellow
		$JSON_Data = Get-Content "$($JsonFile.FullName)"
		
		# Excluding entries that are not required - id,createdDateTime,lastModifiedDateTime,version
		$JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version, supportsScopeTags
		$JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
		Create-GroupPolicyConfigurationsDefinitionValues -JSON $JSON_Output -GroupPolicyConfigurationID $GroupPolicyConfigurationID
	}
}

$ImportPath = Read-Host -Prompt "Please specify a path to import the policy data to e.g. C:\IntuneOutput"
$ImportPath = $ImportPath.replace('"', '')
# If the directory path doesn't exist prompt user to create the directory

if (!(Test-Path "$ImportPath"))
{
	Write-Host "Path '$ImportPath' doesn't exist" -ForegroundColor Yellow
	break
}

Get-ChildItem "$ImportPath" | Where-Object { $_.PSIsContainer -eq $True } | ForEach-Object { import-ADMX $_.FullName }

Add-GroupPolicyConfigurationsAssignment -GroupPolicyId $GroupPolicyConfigurationID
