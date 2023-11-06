<#
.SYNOPSIS
    Create local admin account with randomized password
.DESCRIPTION
    Create local admin account with randomized password

.EXAMPLE
    Detect-LocalAdminLAPS.ps1      

.NOTES
    FileName:    Detect-LocalAdminLAPS.ps1
    Author:      Sandy Zeng
    Contributor: Sandy Zeng
    Contact:     
    Created:     2023-10-12
    Updated:     2023-10-12

    Version history:
    1.0.0 - (2023-10-12) Script created
    1.0.1 - (2023-11-06) added Make sure account isn't the local admin account renamed
#>

 
$localAdminName = "PLocalAdmin"
#Get local admin group name by using knonw sid
$Localadmingroupname = $((Get-LocalGroup -SID "S-1-5-32-544").Name)

try {
    #Find the custom local admin account and check if it's a renamed buit-in account
    $check = Get-LocalUser -Name $localAdminName -ErrorAction stop
    if ($check.sid -like 'S-1-5-21-*-500')
    {
        Write-Error "Account: $localAdminName was renamed from built-in administrator account"
        exit 1
    }
    else 
    {
        Write-Output "Account: $localAdminName already exist"
    }

    #Get all local administrators group members that is Azure AD user, use net localgroup because some machine has errors when using Get-LocalGroupMember. 
    #see details on https://github.com/PowerShell/PowerShell/issues/2996
    try {
        $administrators = net localgroup $Localadmingroupname
        $member = $administrators[6..($Localadmingroupname.Length - 3)] | Where-Object { $_ -match "$localAdminName" }
    
        if ($member) {
            Write-Output "Account: $localAdminName is member of group: $Localadmingroupname"
            exit 0
        }
        else {
            Write-Error "Account: $localAdminName is not member of group: $Localadmingroupname"
            exit 1
        }       
    }
    catch {
        Write-Error "failed getting group $Localadmingroupname membership"
        exit 1
    }

}
catch {
    Write-Error "Account: $localAdminName does not exist"
    Exit 1
}