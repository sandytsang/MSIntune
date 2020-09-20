<#
.SYNOPSIS
    This function create new AppLocker settings using MDM WMI Bridge

.DESCRIPTION
    This script will create AppLocker settings for EXE

.NOTES
    File name: Create-AppLockerEXE.ps1
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
$GroupName = "AppLocker001" #You can use your own Groupname, don't use special charaters or with space
$parentID = "./Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/$GroupName"

Add-Type -AssemblyName System.Web

#This is example Rule Collection for EXE, you should change this to your own settings
$obj = [System.Net.WebUtility]::HtmlEncode(@"
<RuleCollection Type="Exe" EnforcementMode="Enabled">
<FilePathRule Id="420088cd-47f6-420d-b47a-12a650198eff" Name="%OSDRIVE%\ProgramData\Microsoft\Windows Defender\Platform\*" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
  <Conditions>
    <FilePathCondition Path="%OSDRIVE%\ProgramData\Microsoft\Windows Defender\Platform\*" />
  </Conditions>
</FilePathRule>
<FilePathRule Id="603686fd-13a1-48c1-b66c-edd3de9170a6" Name="%OSDRIVE%\USERS\*\APPDATA\LOCAL\MICROSOFT\ONEDRIVE\OneDriveStandaloneUpdater.exe" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
  <Conditions>
    <FilePathCondition Path="%OSDRIVE%\USERS\*\APPDATA\LOCAL\MICROSOFT\ONEDRIVE\*" />
  </Conditions>
</FilePathRule>
<FilePathRule Id="921cc481-6e17-4653-8f75-050b80acca20" Name="(Default Rule) All files located in the Program Files folder" Description="Allows members of the Everyone group to run applications that are located in the Program Files folder." UserOrGroupSid="S-1-1-0" Action="Allow">
  <Conditions>
    <FilePathCondition Path="%PROGRAMFILES%\*" />
  </Conditions>
  <Exceptions>
    <FilePathCondition Path="C:\Program Files\internet explorer\iexplore.exe" />
    <FilePathCondition Path="C:\Program Files (x86)\internet explorer\iexplore.exe" />
    <FilePathCondition Path="%PROGRAMFILES%\internet explorer\iexplore.exe" />			
  </Exceptions>	  
</FilePathRule>
<FilePathRule Id="fd686d83-a829-4351-8ff4-27c7de5755d2" Name="(Default Rule) All files" Description="Allows members of the local Administrators group to run all applications." UserOrGroupSid="S-1-5-32-544" Action="Allow">
  <Conditions>
    <FilePathCondition Path="*" />
  </Conditions>
</FilePathRule>
<FilePathRule Id="b844227a-fcf4-40ec-af94-1581e6b0191c" Name="All files located in the Windows folder" Description="Allows members of the Everyone group to run applications that are located in the Windows folder." UserOrGroupSid="S-1-1-0" Action="Allow">
  <Conditions>
    <FilePathCondition Path="%WINDIR%\*" />
  </Conditions>
  <Exceptions>
    <FilePathCondition Path="%SYSTEM32%\cmd.exe" />	
    <FilePathCondition Path="%SYSTEM32%\com\dmp\*" />
    <FilePathCondition Path="%SYSTEM32%\FxsTmp\*" />
    <FilePathCondition Path="%SYSTEM32%\microsoft\crypto\rsa\machinekeys\*" />
    <FilePathCondition Path="%SYSTEM32%\mmc.exe" />
    <FilePathCondition Path="%SYSTEM32%\Tasks\*" />
    <FilePathCondition Path="%SYSTEM32%\WindowsPowerShell\v1.0\powershell.exe" />
    <FilePathCondition Path="%SYSTEM32%\WindowsPowerShell\v1.0\PowerShell_ISE.exe" />
    <FilePathCondition Path="%WINDIR%\regedit.exe" />
    <FilePathCondition Path="%WINDIR%\registration\crmlog\*" />
    <FilePathCondition Path="%WINDIR%\servicing\packages\*" />
    <FilePathCondition Path="%WINDIR%\servicing\sessions\*" />
    <FilePathCondition Path="%WINDIR%\syswow64\cmd.exe" />
    <FilePathCondition Path="%WINDIR%\syswow64\mmc.exe" />
    <FilePathCondition Path="%WINDIR%\syswow64\WindowsPowerShell\v1.0\powershell.exe" />
    <FilePathCondition Path="%WINDIR%\syswow64\WindowsPowerShell\v1.0\PowerShell_ISE.exe" />
    <FilePathCondition Path="%WINDIR%\tasks\*" />
    <FilePathCondition Path="%WINDIR%\temp\*" />
    <FilePathCondition Path="%WINDIR%\tracing\*" />
    <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="INTERNET EXPLORER" BinaryName="MSHTA.EXE">
      <BinaryVersionRange LowSection="*" HighSection="*" />
    </FilePublisherCondition>
    <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFT(R) CONNECTION MANAGER" BinaryName="CMSTP.EXE">
      <BinaryVersionRange LowSection="*" HighSection="*" />
    </FilePublisherCondition>
    <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFT� .NET FRAMEWORK" BinaryName="INSTALLUTIL.EXE">
      <BinaryVersionRange LowSection="*" HighSection="*" />
    </FilePublisherCondition>
    <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFT� .NET FRAMEWORK" BinaryName="MSBUILD.EXE">
      <BinaryVersionRange LowSection="*" HighSection="*" />
    </FilePublisherCondition>
    <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFT� .NET FRAMEWORK" BinaryName="REGASM.EXE">
      <BinaryVersionRange LowSection="*" HighSection="*" />
    </FilePublisherCondition>
    <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFT� .NET FRAMEWORK" BinaryName="REGSVCS.EXE">
      <BinaryVersionRange LowSection="*" HighSection="*" />
    </FilePublisherCondition>
    <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFT� WINDOWS� OPERATING SYSTEM" BinaryName="CIPHER.EXE">
      <BinaryVersionRange LowSection="*" HighSection="*" />
    </FilePublisherCondition>
    <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFT� WINDOWS� OPERATING SYSTEM" BinaryName="PRESENTATIONHOST.EXE">
      <BinaryVersionRange LowSection="*" HighSection="*" />
    </FilePublisherCondition>
    <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="MICROSOFT� WINDOWS� OPERATING SYSTEM" BinaryName="WMIC.EXE">
      <BinaryVersionRange LowSection="*" HighSection="*" />
    </FilePublisherCondition>
  </Exceptions>
</FilePathRule>
</RuleCollection>
"@)

New-CimInstance -Namespace $namespaceName -ClassName $className -Property @{ParentID=$parentID;InstanceID="EXE";Policy=$obj}
