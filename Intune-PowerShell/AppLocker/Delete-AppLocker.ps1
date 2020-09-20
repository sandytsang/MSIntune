<#
.SYNOPSIS
    This function delete AppLocker settings using MDM WMI Bridge

.DESCRIPTION
    This script will delete AppLocker settings for EXE

.NOTES
    File name: Delete-AppLocker.ps1
    VERSION: 2005a
    AUTHOR: Sandy Zeng
    Created:  2020-09-20
    Licensed under the MIT license.
    Please credit me if you fint this script useful and do some cool things with it.

.VERSION HISTORY:
    1.0.0 - (2020-09-20) Script created
    1.0.1 - 
#>

$namespaceName = "root\cimv2\mdm\dmmap" #Do not change this
$className = "MDM_AppLocker_ApplicationLaunchRestrictions01_EXE03" #Do not change this
$GroupName = "AppLocker001" #Your own groupName
$parentID = "./Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/$GroupName"

Get-CimInstance -Namespace $namespaceName -ClassName $className -Filter "ParentID=`'$parentID`' and InstanceID='EXE'"  | Remove-CimInstance