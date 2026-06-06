# MSIntune

A collection of PowerShell scripts and configuration files for managing Microsoft Intune,
Entra ID, and Windows endpoints. Scripts are organized by **feature/topic** so related
content lives together regardless of where it runs (interactive, Azure Automation, or Azure Functions).

## Repository structure

| Folder | Purpose |
|--------|---------|
| [PrimaryUser/](PrimaryUser) | Manage the Intune device primary user (set, update, remove) across hosting models |
| [DeviceConfiguration/](DeviceConfiguration) | Export/import device configuration and Settings Catalog policies |
| [AppLocker/](AppLocker) | Create, update, and remove AppLocker EXE rules via the MDM WMI Bridge |
| [WindowsLAPS/](WindowsLAPS) | Detection and remediation scripts for a custom local admin account |
| [RBAC/](RBAC) | Intune role-based access control (scope tags) |
| [Authentication/](Authentication) | Microsoft Graph authentication examples |
| [Enrollment/](Enrollment) | Intune enrollment configuration (incl. Azure China AVD) |
| [Kiosk/](Kiosk) | Assigned Access / kiosk configuration and auto-logon |
| [SecurityBaseline/](SecurityBaseline) | Exported Intune security baseline definitions |
| [Firewall/](Firewall) | Windows Firewall rule reporting |
| [IntuneNetwork/](IntuneNetwork) | Network connectivity diagnostics for Intune / Windows Autopatch |
| [Reference/](Reference) | Reference data (Windows version-to-build lookup) |

## Scripts

### PrimaryUser
| Script | Description |
|--------|-------------|
| [Invoke-PrimaryUserUpdate-WithModule.ps1](PrimaryUser/AzureAutomation/Invoke-PrimaryUserUpdate-WithModule.ps1) | Azure Automation runbook that updates the primary user based on the last 30 days of sign-in activity, using the Microsoft.Graph.Beta modules |
| [Invoke-PrimaryUserUpdate-WithoutModules.ps1](PrimaryUser/AzureAutomation/Invoke-PrimaryUserUpdate-WithoutModules.ps1) | Same logic using direct Graph REST calls with a Managed Identity token (no modules required) |
| [HttpTrigger-Remove-PrimaryUser.ps1](PrimaryUser/AzureFunction/HttpTrigger-Remove-PrimaryUser.ps1) | HTTP-triggered Azure Function that removes the primary user from devices in specified Entra ID groups |
| [Timer-Remove-PrimaryUser.ps1](PrimaryUser/AzureFunction/Timer-Remove-PrimaryUser.ps1) | Timer-triggered version of the primary-user removal function |
| [Set-PrimaryUser.ps1](PrimaryUser/Interactive/Set-PrimaryUser.ps1) | Interactive/standalone script to set the primary user using MSAL.PS |

### DeviceConfiguration
| Script | Description |
|--------|-------------|
| [DeviceConfigurationADMX_Export.ps1](DeviceConfiguration/DeviceConfigurationADMX_Export.ps1) | Exports Intune ADMX-ingested administrative-template policies via Graph |
| [DeviceConfigurationADMX_Import_FromJSON.ps1](DeviceConfiguration/DeviceConfigurationADMX_Import_FromJSON.ps1) | Imports ADMX administrative-template policies from exported JSON |
| [Get-IntunePolicyWithSettingDefinitions.ps1](DeviceConfiguration/Get-IntunePolicyWithSettingDefinitions.ps1) | Retrieves all Settings Catalog policies with expanded setting definitions and exports them |

### AppLocker
| Script | Description |
|--------|-------------|
| [New-AppLockerEXERule.ps1](AppLocker/New-AppLockerEXERule.ps1) | Creates AppLocker EXE launch-restriction rules via the MDM WMI Bridge |
| [Set-AppLockerEXERule.ps1](AppLocker/Set-AppLockerEXERule.ps1) | Updates existing AppLocker EXE rules |
| [Remove-AppLockerEXERule.ps1](AppLocker/Remove-AppLockerEXERule.ps1) | Deletes AppLocker EXE rules |

### WindowsLAPS
| Script | Description |
|--------|-------------|
| [Detect-LocalAdminLAPS.ps1](WindowsLAPS/Detect-LocalAdminLAPS.ps1) | Detection script: verifies the custom local admin exists, is enabled, and is not a renamed built-in admin |
| [New-LocalAdminLAPS.ps1](WindowsLAPS/New-LocalAdminLAPS.ps1) | Remediation script: creates a local admin account with a randomized password |

### RBAC
| Script | Description |
|--------|-------------|
| [Add-ScopeTag.ps1](RBAC/Add-ScopeTag.ps1) | Assigns an Intune RBAC Role Scope Tag by name |

### Authentication
| Script | Description |
|--------|-------------|
| [Invoke-MicrosoftGraphWithCertificate.ps1](Authentication/Invoke-MicrosoftGraphWithCertificate.ps1) | Authenticates to Microsoft Graph using a certificate-based JWT assertion |

### Enrollment
| Script | Description |
|--------|-------------|
| [Configure-IntuneEnrollment.ps1](Enrollment/ChinaAVD/Configure-IntuneEnrollment.ps1) | Configures Intune enrollment for AVD session hosts in Azure China (21Vianet) |

### Kiosk
| File | Description |
|------|-------------|
| [Autologon.ps1](Kiosk/Autologon.ps1) | Configures Windows auto-logon (LSA secrets) for kiosk scenarios |
| [Kiosk_multiapps.xml](Kiosk/Kiosk_multiapps.xml) | Assigned Access multi-app kiosk configuration |
| [Kiosk_startlayout.xml](Kiosk/Kiosk_startlayout.xml) | Start layout referenced by the kiosk configuration |

### SecurityBaseline
| File | Description |
|------|-------------|
| [MS - Windows 11 24H2 Security Baseline.json](SecurityBaseline/MS%20-%20Windows%2011%2024H2%20Security%20Baseline.json) | Exported Settings Catalog JSON of the Microsoft Windows 11 24H2 Security Baseline |

### Firewall
| Script | Description |
|--------|-------------|
| [Get-FirewallRules.ps1](Firewall/Get-FirewallRules.ps1) | Reports the enabled Windows Firewall rules enforced for the active network profile |

### IntuneNetwork
| Script | Description |
|--------|-------------|
| [Test-AutopatchDiagnosticDataConnectivity.ps1](IntuneNetwork/Test-AutopatchDiagnosticDataConnectivity.ps1) | Diagnoses the Windows Autopatch "diagnostic data connectivity" device readiness failure by validating on-device prerequisites and endpoints (region-aware, with optional TLS-inspection detection, DNS-cache endpoint discovery, real HTTPS POST app-layer testing, and DiagTrack Event ID 29 log analysis). See the [folder README](IntuneNetwork/README.md). |

### Reference
| File | Description |
|------|-------------|
| [WindowsVersion.csv](Reference/WindowsVersion.csv) | Windows release version → OS build lookup (CSV) |
| [WindowsVersion.json](Reference/WindowsVersion.json) | Same lookup in JSON |

## Notes

- Scripts use placeholders such as `<YourTenant>`, `<YourAppId>`, and `<YourAppSecret>`.
  Replace these with your own values, and prefer Azure Automation variables, Key Vault, or a
  managed identity over hardcoding secrets.
- Most scripts require Microsoft Graph permissions. Review the comment-based help at the top
  of each script for module and permission requirements.

## License

Licensed under the MIT license. Please credit the original authors if you find these scripts useful.