<#
.SYNOPSIS
    Create local admin account with randomized password
.DESCRIPTION
    Create local admin account with randomized password

.EXAMPLE
    Create-LocalAdminLAPSRemediation.ps1      

.NOTES
    FileName:    Create-LocalAdminLAPS.ps1
    Author:      Sandy Zeng
    Contributor: Jan Ketil Skanke
    Contact:     
    Created:     2023-10-12
    Updated:     2023-11-10

    Version history:
    1.0.0 - (2023-10-12) Script created
    1.0.1 - (2023-10-13) Add random password generator
    1.0.2 - (2023-11-10) fixed enable user account logic
#>


function New-RandomPassword {
    #define parameters
    param([int]$PasswordLength = 25)
    #ASCII Character set for Password
    $CharacterSet = @{
        Uppercase   = (97..122) | Get-Random -Count 10 | % { [char]$_ }
        Lowercase   = (65..90)  | Get-Random -Count 10 | % { [char]$_ }
        Numeric     = (48..57)  | Get-Random -Count 10 | % { [char]$_ }
        SpecialChar = (33..47) + (58..64) + (91..96) + (123..126) | Get-Random -Count 10 | % { [char]$_ }
    }
    #Frame Random Password from given character set
    $StringSet = $CharacterSet.Uppercase + $CharacterSet.Lowercase + $CharacterSet.Numeric + $CharacterSet.SpecialChar
    -join (Get-Random -Count $PasswordLength -InputObject $StringSet)
}

#Find built-in Administrator account, rename it to Administrator, set random password and disable the account
try {
    $BuiltinAdmin = Get-LocalUser | Where-Object { $_.sid -like 'S-1-5-21-*-500' }
    Rename-LocalUser -Name $BuiltinAdmin.Name -NewName "Administrator"
    $password = New-RandomPassword -PasswordLength 30 | ConvertTo-SecureString -AsPlainText -Force
    Set-LocalUser -Name "Administrator" -Password $password
    Disable-LocalUser -Name "Administrator"
    Write-Output "Built-in administrator account is renamed and disabled"
}
catch {
    Write-Error "Issue with handling built-in administrator account"
}

#Custom local admin account   
$localAdminName = "PLocalAdmin"
$password = New-RandomPassword -PasswordLength 30 | ConvertTo-SecureString -AsPlainText -Force
$Localadmingroupname = $((Get-LocalGroup -SID "S-1-5-32-544").Name)

#Create local admin account
try {
    $check = Get-LocalUser -Name $localAdminName -ErrorAction SilentlyContinue
    if ($check -and $check.Enabled) {
        Write-Output "Account: $localadminname is found and it's already enabled"
    }
    elseif ($check -and !$check.Enabled) {
        Enable-LocalUser -Name $localAdminName
        Write-Output "Account: $localadminname is now enabled"
    }
    else {
        try {
            New-LocalUser "$localAdminName" -Password $password -FullName "$localAdminName" -Description "Windows LAPS account" -ErrorAction Stop | Out-Null
            Write-Output "Created account: $localadminname"
        }
        catch {
            Write-Error "Encountered Error: $_.Exception.Message"
            exit 1
        }
    }

}
catch {
    Write-Error "Encountered Error: $_.Exception.Message"
    exit 1
}


#Add local admin account to local admin group
$administrators = net localgroup $Localadmingroupname
$member = $administrators[6..($Localadmingroupname.Length - 3)] | Where-Object { $_ -match "$localAdminName" }

if ($member) {
    Write-Output "Account: $localAdminName is already member of group: $Localadmingroupname"
    exit 0
}
else {
    try {
        Add-LocalGroupMember -Group $Localadmingroupname -Member $localAdminName -ErrorAction Stop
        Write-Output "Added accoun:$localadminname to group: $localadmingroupname"
        exit 0
    }
    catch {
        Write-Error "Encountered Error: $_.Exception.Message"
        exit 1
    }
}