<#
.SYNOPSIS
    This function adds header information to a script

.DESCRIPTION
    This script will automatic add header information as example

.PARAMETER

    The following switches are available:
    -parameter1
    -parameter2   
    -parameter3

.NOTES
    File name: Add-Help.ps1
    VERSION: 2005a
    AUTHOR: Sandy Zeng
    Created:  2020-07-23
    Updated: $(Get-Date)
    COPYRIGHT:
    Sandy Zeng / https://www.sandyzeng.com
    Licensed under the MIT license.
    Please credit me if you fint this script useful and do some cool things with it.

.EXAMPLE
    -Example
    -Example

.VERSION HISTORY:
    1.0.0 - (2020-07-23) Script created
    1.0.1 - 
#>


$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_AppLocker_ApplicationLaunchRestrictions01_EXE03"
$GroupName = "AppLocker001"
$parentID = "./Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/$GroupName"


Add-Type -AssemblyName System.Web
$obj = [System.Net.WebUtility]::HtmlEncode(@"
<RuleCollection Type="Exe">
   <FilePublisherRule Id="921cc481-6e17-4653-8f75-050b80acca1f" Name="Default Rule to allow Microsoft publisher" Description="Allows members of the Everyone group to run desktop apps that are signed with Microsoft publisher." UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
         <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="*">
            <BinaryVersionRange LowSection="*" HighSection="*" />
         </FilePublisherCondition>
      </Conditions>
   </FilePublisherRule>
   <FilePathRule Id="fd686d83-a829-4351-8ff4-27c7de5755d2" Name="(Default Rule) All files" Description="Allows members of the local Administrators group to run all applications." UserOrGroupSid="S-1-5-32-544" Action="Allow">
      <Conditions>
         <FilePathCondition Path="*" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="F1DFF345-D832-492A-A1F9-012BA91D6826" Name="C:\WINDOWS\system32\bcdboot.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\bcdboot.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="6E478915-AFF6-4B6E-8E10-7B5FC5D89CF9" Name="C:\WINDOWS\system32\bcdedit.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\bcdedit.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="42D60AB1-33FA-4011-928C-02FD5E63B4AD" Name="C:\WINDOWS\system32\change.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\change.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="D9F10E78-B1D7-4292-B195-2952A9F18C04" Name="C:\WINDOWS\system32\changepk.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\changepk.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="B86AA3A6-2DB4-4937-B44C-DE8555EAFEC8" Name="C:\Program Files\internet explorer\iexplore.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\Program Files\internet explorer\iexplore.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="41E94CD2-CE4F-4D44-812B-E3C81AD40C9C" Name="C:\Program Files (x86)\internet explorer\iexplore.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\Program Files (x86)\internet explorer\iexplore.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="48BEB0FB-F96D-413D-8984-DF1549B6BE7D" Name="C:\WINDOWS\helppane.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\helppane.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="95EA99A8-91FF-407F-9799-A4DC3DA3DF66" Name="C:\WINDOWS\system32\klist.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\klist.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="91446DC3-919C-41DD-9B67-850DE50DA817" Name="C:\WINDOWS\system32\logoff.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\logoff.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="5F3EAC90-C433-4E65-81E9-034D31C5F243" Name="C:\WINDOWS\system32\mdsched.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\mdsched.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="5235BC24-D703-47F3-B6C9-569F27D79012" Name="C:\Program Files\Common Files\Microsoft Shared\Ink\mip.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\Program Files\Common Files\Microsoft Shared\Ink\mip.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="ADC01D5C-6373-43D6-A983-28FC5EF340B2" Name="C:\WINDOWS\system32\msconfig.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\msconfig.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="C74EFF06-35EE-4A36-9AC4-15BF55794CA1" Name="C:\WINDOWS\system32\msinfo.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\msinfo.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="1DEC2BE9-B072-438E-9161-1AC9016CB488" Name="C:\WINDOWS\notepad.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\notepad.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="BC089271-9C71-4D36-81F0-0148B62075AE" Name="C:\WINDOWS\system32\recoverydrive.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\recoverydrive.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="EDDE10BD-4A7E-4203-805F-05B5C1A1724F" Name="C:\WINDOWS\system32\recdisc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\recdisc.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="594BCA1F-58CE-4EE1-A9DE-8CB0879BF8FF" Name="C:\WINDOWS\regedit.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\regedit.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="31D14B03-3262-46EC-AE18-81C8F2E3BF4A" Name="C:\WINDOWS\Speech\Common\sapisvr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\Speech\Common\sapisvr.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="FD44BA4E-836B-416B-A9F6-BB8F9554823D" Name="C:\WINDOWS\system32\snippingtool.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\snippingtool.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="11C76ADA-6426-4756-8E41-AAFDE266E3A7" Name="C:\WINDOWS\system32\wfs.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\wfs.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="376DC7AC-D9DA-483A-AFAE-E51A06672955" Name="C:\WINDOWS\write.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\write.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="79FC564C-55D9-4D00-B64F-E4517178A098" Name="C:\Program Files\Windows Media Player\wmplayer.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\Program Files\Windows Media Player\wmplayer.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="33608575-937E-45BC-9CD9-D959855CB73D" Name="C:\Program Files (x86)\Windows Media Player\wmplayer.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\Program Files (x86)\Windows Media Player\wmplayer.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="B326B03C-5E27-4DB0-A52C-A37AD84520F4" Name="C:\Program Files\Windows NT\Accessories\wordpad.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\Program Files\Windows NT\Accessories\wordpad.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="D36EB53D-A9D1-4C94-82D8-31B8B0EAC581" Name="C:\Program Files (x86)\Windows NT\Accessories\wordpad.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\Program Files (x86)\Windows NT\Accessories\wordpad.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="B9AF8745-48A3-4B8E-82A7-3243B4A8B103" Name="C:\WINDOWS\system32\%ProgramFiles(Arm)%\Windows NT\Accessories\wordpad.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\%ProgramFiles(Arm)%\Windows NT\Accessories\wordpad.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="EAA9FD70-CCD0-4DF0-B1C2-9A510DD0E2BD" Name="C:\WINDOWS\system32\xpsrchvw.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\system32\xpsrchvw.exe" />
      </Conditions>
   </FilePathRule>
   <FilePathRule Id="43EE434C-B1AB-47DC-A3C5-40244B13BB47" Name="C:\WINDOWS\winsxs\*\bcdboot.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\bcdboot.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="669E75BE-5545-4635-9FDB-3A1E99287948" Name="C:\WINDOWS\winsxs\*\bcdedit.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\bcdedit.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="FFC3346D-323E-47D4-8A0F-4C885B9D18C8" Name="C:\WINDOWS\*\cacls.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\cacls.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="0F0B2D65-8E6F-426C-861E-9DBE8FA1C80C" Name="C:\WINDOWS\winsxs\*\cacls.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\cacls.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="95047412-E25A-42B8-A485-D73BEBCCE328" Name="C:\WINDOWS\*\calc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\calc.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="FF806E56-6AD9-468E-BD26-43C5336163D6" Name="C:\WINDOWS\winsxs\*\calc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\calc.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="00F6F3F2-B071-4E66-83FA-37D40A35B3DB" Name="C:\WINDOWS\winsxs\*\change.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\change.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="3C594ACA-5F78-4875-9D61-D6889E3206B3" Name="C:\WINDOWS\winsxs\*\changepk.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\changepk.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="CA5164B4-4D7D-4E17-B366-99C0914AFEE2" Name="C:\WINDOWS\*\charmap.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\charmap.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="C421DE77-55A1-44EB-8034-91DDFDCAF9EA" Name="C:\WINDOWS\winsxs\*\charmap.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\charmap.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="0FA08EB9-09DA-402F-96A8-60C7789E7777" Name="C:\WINDOWS\*\chkdsk.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\chkdsk.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="0D33F197-0DFC-428B-ACDF-8BD2C6018E24" Name="C:\WINDOWS\winsxs\*\chkdsk.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\chkdsk.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="052AF55D-D5D2-49D7-8F38-A89BF431402F" Name="C:\WINDOWS\*\cleanmgr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\cleanmgr.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="02BD11B7-393C-4C7C-9B0D-1928A9D60D1A" Name="C:\WINDOWS\winsxs\*\cleanmgr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\cleanmgr.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="F8AA28BB-E3BA-4F5A-81DC-CC98946867CF" Name="C:\WINDOWS\*\cmd.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\cmd.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="BD4E2E20-7E4B-41B3-9139-DA2289DC3C9C" Name="C:\WINDOWS\winsxs\*\cmd.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\cmd.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="BB787963-9209-4701-8C2E-CDA7543204CA" Name="C:\WINDOWS\*\cmdkey.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\cmdkey.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="DD5A762B-7417-43DA-9619-D9705C4B14F6" Name="C:\WINDOWS\winsxs\*\cmdkey.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\cmdkey.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="ED485B0C-466D-4775-9273-6ECD74D80C7D" Name="C:\WINDOWS\*\control.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\control.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="2685DCC5-3575-4CAA-B27A-3008EA6EB6B1" Name="C:\WINDOWS\winsxs\*\control.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\control.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="5E5019CB-4076-4070-BEFB-938108E5CAF4" Name="C:\WINDOWS\*\cscript.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\cscript.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="474605DF-9FF3-45F8-B6FF-5FAC9141CBDE" Name="C:\WINDOWS\winsxs\*\cscript.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\cscript.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="BC8EB1A8-B50F-46AA-9054-6BA2DAD8CF31" Name="C:\WINDOWS\*\dialer.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\dialer.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="16992AB4-DA72-444D-A68F-70BC2803084B" Name="C:\WINDOWS\winsxs\*\dialer.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\dialer.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="EECE76AF-45EE-4CB6-B8D0-1788CDD0D562" Name="C:\WINDOWS\*\doskey.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\doskey.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="F7C29E69-CA7B-4E87-978B-ECFBD3554973" Name="C:\WINDOWS\winsxs\*\doskey.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\doskey.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="EB65BA38-28C0-481C-B43D-72827306F59F" Name="C:\WINDOWS\*\dfrgui.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\dfrgui.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="C66E26B9-1784-4DD1-AA7F-8ABC4688D8F5" Name="C:\WINDOWS\winsxs\*\dfrgui.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\dfrgui.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="664E1F7C-3408-413E-90F1-9CCD3B39BE53" Name="C:\WINDOWS\*\icacls.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\icacls.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="176DB1C9-5A1D-4A7A-AD71-D29D14D01FF0" Name="C:\WINDOWS\winsxs\*\icacls.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\icacls.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="DEB7B6D7-3477-43C5-8E8D-97207EEE878E" Name="C:\WINDOWS\winsxs\*\iexplore.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\iexplore.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="F7889146-C8F2-431F-95C3-AFB29BE5B27A" Name="C:\WINDOWS\*\iscsicpl.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\iscsicpl.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="37A4A5D1-BC67-4625-AF37-B8D64636A92F" Name="C:\WINDOWS\winsxs\*\iscsicpl.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\iscsicpl.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="468FB754-A762-4A90-9C1E-3DB9B167AF63" Name="C:\WINDOWS\*\fc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\fc.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="39C8C075-ECE8-41CB-9DCC-89496320A4A6" Name="C:\WINDOWS\winsxs\*\fc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\fc.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="AD77401F-CB50-4CE3-B953-BC313C46DC9D" Name="C:\WINDOWS\*\find.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\find.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="9B8DB72D-2335-4472-8637-BA8D010C83E5" Name="C:\WINDOWS\winsxs\*\find.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\find.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="D947E0B3-3312-417F-BEB3-53C5F3357EAC" Name="C:\WINDOWS\*\findstr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\findstr.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="1F29FD20-98BB-48AD-9017-3797768AFD3E" Name="C:\WINDOWS\winsxs\*\findstr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\findstr.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="A6A0AF7B-D1D7-4DDE-8FEC-CE83802D2C9E" Name="C:\WINDOWS\winsxs\*\helppane.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\helppane.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="7AAD4810-3080-42BD-8349-7675425C7401" Name="C:\WINDOWS\winsxs\*\klist.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\klist.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="CBA4B4D2-236D-4569-808E-B0D7B7B3CFBF" Name="C:\WINDOWS\winsxs\*\logoff.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\logoff.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="B0FA13E6-2953-406C-B297-AEB43734FE4B" Name="C:\WINDOWS\winsxs\*\mdsched.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\mdsched.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="34BF25DD-03EB-490A-A6C7-652B64EA339E" Name="C:\WINDOWS\winsxs\*\mip.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\mip.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="DCAA368B-9630-45D0-817F-E7ABFB324948" Name="C:\WINDOWS\*\mmc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\mmc.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="02D5161D-5CB6-48A0-B5A6-03F7C46D31FA" Name="C:\WINDOWS\winsxs\*\mmc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\mmc.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="F487A372-E84A-4965-971B-51FF6644497D" Name="C:\WINDOWS\winsxs\*\msconfig.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\msconfig.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="00A00C67-12C5-4AC6-89EB-E397E1C30747" Name="C:\WINDOWS\*\mspaint.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\mspaint.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="9D497F89-2B60-4CEB-8B09-106D245BA5BD" Name="C:\WINDOWS\winsxs\*\mspaint.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\mspaint.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="FE9A5F9C-ABD3-4186-95AD-51F0D39EFF78" Name="C:\WINDOWS\*\mstsc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\mstsc.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="964E009A-09A3-4ABB-9923-07D476AAC0A5" Name="C:\WINDOWS\winsxs\*\mstsc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\mstsc.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="81887C32-5B3C-4B69-A691-40139F78DFBA" Name="C:\WINDOWS\*\net.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\net.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="5E68EBE2-C5E3-44D5-9B9E-BB4C71A7BE2A" Name="C:\WINDOWS\winsxs\*\net.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\net.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="2FA4720F-B615-43F0-852D-A5A9F5C9B1AE" Name="C:\WINDOWS\*\net1.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\net1.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="B427F73B-1FD3-4FF2-BBD3-273E3B8E92E9" Name="C:\WINDOWS\winsxs\*\net1.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\net1.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="0EF13514-0235-4066-BD07-A67411E75ACC" Name="C:\WINDOWS\*\notepad.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\notepad.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="EBB6A583-1C99-4420-822E-DD0AD452F58C" Name="C:\WINDOWS\winsxs\*\notepad.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\notepad.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="09A3D0BE-CC74-4502-9273-34EDF77F6BE2" Name="C:\WINDOWS\*\odbcad32.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\odbcad32.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="0DF1FDFA-0ABA-4F06-BE55-581EB45D1959" Name="C:\WINDOWS\winsxs\*\odbcad32.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\odbcad32.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="4FE4B109-DE6D-4F8B-921C-2635F3662150" Name="C:\WINDOWS\*\windowspowershell\v1.0\powershell*.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\windowspowershell\v1.0\powershell*.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="41D77378-06DD-4DE2-AAEF-415B10BEDD37" Name="C:\WINDOWS\winsxs\*\powershell*.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\powershell*.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="FE9DC5CA-D7F9-4B74-A735-DEEC5D66CEC6" Name="C:\WINDOWS\*\perfmon.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\perfmon.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="0178A10D-A8C1-45DC-9DA6-4EA248E7CCDE" Name="C:\WINDOWS\winsxs\*\perfmon.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\perfmon.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="973AF1CB-22E4-4675-A7C0-40573A5BDF51" Name="C:\WINDOWS\*\psr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\psr.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="10EDEEFF-C81D-4F9D-80B6-2F63A9106466" Name="C:\WINDOWS\winsxs\*\psr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\psr.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="55D41961-500F-4FB1-9B0E-3D163B1DAB97" Name="C:\WINDOWS\*\quickassist.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\quickassist.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="6EFB71C1-B670-4DE0-A1A4-7BA90BEDC3D0" Name="C:\WINDOWS\winsxs\*\quickassist.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\quickassist.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="CAF03070-C865-4EF4-954F-E6E349BE9DA3" Name="C:\WINDOWS\winsxs\*\recoverydrive.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\recoverydrive.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="4E3F5818-0326-4ED7-B386-F2E316D18A7C" Name="C:\WINDOWS\winsxs\*\recdisc.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\recdisc.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="96A82904-BDDF-460C-84E9-56C0863CD1AD" Name="C:\WINDOWS\*\reg.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\reg.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="A0CC8179-90A3-463D-B427-013945AC5B87" Name="C:\WINDOWS\winsxs\*\reg.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\reg.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="AEB888F9-F730-46DD-AD2C-EE50BC6E39F8" Name="C:\WINDOWS\*\regedit.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\regedit.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="61F4F6EB-564C-48C5-A3A2-59D968D2F6C2" Name="C:\WINDOWS\winsxs\*\regedit.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\regedit.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="6D527F92-7ECC-47C5-86E2-38FC546DF6AF" Name="C:\WINDOWS\winsxs\*\sapisvr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\sapisvr.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="82DE55A3-F27F-4C7C-B47B-1635CB4E206B" Name="C:\WINDOWS\*\shutdown.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\shutdown.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="E3F09C5B-3462-4C56-A36D-0CEDB3222CC2" Name="C:\WINDOWS\winsxs\*\shutdown.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\shutdown.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="EAFD5F12-DF93-4743-AC10-1F8A1BAA6271" Name="C:\WINDOWS\winsxs\*\snippingtool.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\snippingtool.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="98708526-7D07-47FD-8720-9582ABAA60E0" Name="C:\WINDOWS\*\takeown.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\takeown.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="0CAC6CAC-3F79-4D5E-B858-948491F9DFF6" Name="C:\WINDOWS\winsxs\*\takeown.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\takeown.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="B2A3B27C-23BD-4B56-83BA-C755E3AAF646" Name="C:\WINDOWS\*\taskkill.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\taskkill.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="161DE942-CC8C-402A-AB80-52ECC35CC397" Name="C:\WINDOWS\winsxs\*\taskkill.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\taskkill.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="0E13651B-0977-4630-8E69-D92A36556148" Name="C:\WINDOWS\*\tasklist.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\tasklist.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="98E575DF-AD8F-4CF3-B20B-E8FF30DBE2F0" Name="C:\WINDOWS\winsxs\*\tasklist.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\tasklist.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="C5D6F05E-372D-4020-A408-E9939EF4F9B8" Name="C:\WINDOWS\*\taskmgr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\taskmgr.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="1F9E64BF-C8BA-4D7A-BAC6-9B7EF06E2875" Name="C:\WINDOWS\winsxs\*\taskmgr.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\taskmgr.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="E94884F0-A69B-45C3-902F-918625DCCDFB" Name="C:\WINDOWS\winsxs\*\wfs.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\wfs.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="FD6799DA-F7D2-4928-9176-779F70620B18" Name="C:\WINDOWS\*\where.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\where.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="8C4289D5-78AA-4FD9-9E06-6D2FC1155BD1" Name="C:\WINDOWS\winsxs\*\where.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\where.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="AFC29320-2F8A-49F0-B4A7-366DFD2A028D" Name="C:\WINDOWS\*\write.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\write.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="6FE10AEF-0FFD-4BA8-88DC-93A8FD5DC80F" Name="C:\WINDOWS\winsxs\*\write.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\write.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="4F55FCC9-6949-4486-9774-FAD349E0DAE6" Name="C:\WINDOWS\winsxs\*\wmplayer.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\wmplayer.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="2EE222AC-72D0-45A6-B605-BBD25825B4AA" Name="C:\WINDOWS\winsxs\*\wordpad.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\wordpad.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="25A296E5-5DFA-41BB-9D76-1F55D9B353EF" Name="C:\WINDOWS\*\xcopy.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\*\xcopy.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
   <FilePathRule Id="8CBF8CC6-F7CF-45DC-8AEB-798E8211963C" Name="C:\WINDOWS\winsxs\*\xcopy.exe, by AssignedAccess" Description="" UserOrGroupSid="S-1-5-21-2494591029-3240434678-4058992479-1007" Action="Deny">
      <Conditions>
         <FilePathCondition Path="C:\WINDOWS\winsxs\*\xcopy.exe" />
      </Conditions>
      <Exceptions />
   </FilePathRule>
</RuleCollection>
"@)

New-CimInstance -Namespace $namespaceName -ClassName $className -Property @{ParentID=$parentID;InstanceID="EXE";Policy=$obj}
