# AutopatchHealthCheck

Network connectivity diagnostics for Microsoft Intune / Windows Autopatch.

## Test-AutopatchDiagnosticDataConnectivity.ps1

Diagnoses the Windows Autopatch **"diagnostic data connectivity"** device
readiness failure by validating, on the device itself, the prerequisites and
network endpoints that Autopatch requires for diagnostic data upload.

Use it when a device shows as **Not ready** for the *diagnostic data
connectivity* readiness check in the Autopatch portal, to pinpoint whether the
problem is a stopped service, a telemetry policy, a blocked endpoint, or a
TLS-inspecting proxy.

### What it checks

| # | Category | What it validates |
|---|----------|-------------------|
| 1 | `Service` | The **DiagTrack** (Connected User Experiences and Telemetry) service is running and set to start automatically |
| 2 | `Policy` | **AllowTelemetry** diagnostic data level is **Required (1)** or higher |
| 3 | `ProcessorConfig` | Diagnostic data **processor configuration** endpoints (region-aware) |
| 4 | `Telemetry` | Core Connected User Experiences and Telemetry endpoints |
| 5 | `ErrorReporting (WER)` | Windows Error Reporting endpoints |
| 6 | `CrashReporting (OCA)` | Online Crash Analysis endpoints |
| 7 | `Auth` / `Settings` | Device authentication and settings endpoints |
| 7b | `DiagnosticUpload` | Concrete diagnostic-data-upload blob endpoints (Endpoint Analytics) |
| 8 | `Autopatch` | Windows Autopatch service endpoints (region-aware) |
| 9 | `Proxy` | WinHTTP system proxy and `DisableEnterpriseAuthProxy` configuration |
| 9b | `HttpsPost` | *(opt-in `-TestHttpsPost`)* Real HTTPS POST to the ingestion endpoints to catch app-layer proxy blocks (`403`/`407`) and TLS interception |
| 9c | `EventLog` | *(opt-in `-CheckEventLog`)* DiagTrack's own connection-state events, including **Event ID 29** ("some connections have failed") |

Every endpoint section header in the script cites the exact Microsoft Learn page
and section it was sourced from.

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-Region` | **Yes** | `US` or `EU`. Selects the regional endpoint profile. Use `EU` for tenants whose billing address is in the EU Data Boundary (also Middle East/Africa and non-EU Europe). |
| `-CheckTlsInspection` | No | Opens a real TLS handshake to each reachable HTTPS endpoint and inspects the certificate issuer. Result appears in the **TLSInspection** column (`True` = intercepted, `False` = clean). These endpoints are certificate-pinned and **must** bypass TLS inspection. |
| `-DiscoverEndpoints` | No | Reads the local DNS client cache to reveal the concrete hostnames behind the documented wildcards (e.g. `payloadprod*.blob.core.windows.net`, diagnostic blobs) and connectivity-tests them as `<Category> (Discovered)`. |
| `-TestHttpsPost` | No | Sends a real HTTPS POST to the telemetry ingestion endpoints (not just a TCP test). Catches application-layer failures a socket test misses: proxy `403`/`407` blocks and TLS interception. |
| `-CheckEventLog` | No | Reads `Microsoft-Windows-UniversalTelemetryClient/Operational` and surfaces DiagTrack's own connection-state events, including **Event ID 29** ("some connections have failed"). |

### Output

Results print as a colored table with these columns:

- **Category** – the service area (see table above)
- **Check** – the endpoint or setting tested
- **Status** – `PASS` / `FAIL` / `WARN` / `INFO`
- **TLSInspection** – `True` (interception detected), `False` (clean), or `N/A`
- **Detail** – resolved IP, value, or other context

### Examples

```powershell
# Basic US-region run
.\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region US

# EU Data Boundary endpoint profile
.\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region EU

# Add TLS/SSL interception detection
.\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region US -CheckTlsInspection

# Reveal the real hostnames behind the wildcards from the DNS cache
.\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region US -DiscoverEndpoints

# Event ID 29 "connection failed" but network looks fine: app-layer POST + event-log read
.\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region US -TestHttpsPost -CheckEventLog

# Full run: EU profile + TLS detection + endpoint discovery
.\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region EU -CheckTlsInspection -DiscoverEndpoints
```

### Requirements

- Windows PowerShell 5.1+ (no PowerShell 7-only syntax)
- Run on the affected device; run elevated for the most complete results

### Documentation references

- [Configure Windows diagnostic data in your organization](https://learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization)
- [Windows Autopatch – Configure your network](https://learn.microsoft.com/windows/deployment/windows-autopatch/prepare/windows-autopatch-configure-network)
- [Intune network endpoints](https://learn.microsoft.com/mem/intune/fundamentals/intune-endpoints)

### Credits

- **Author:** Sandy Zeng
- Endpoint coverage and TLS-inspection ideas were informed in part by Martin
  Himken's [IntuneNetworkRequirements](https://github.com/MHimken/IntuneNetworkRequirements)
  project.

## Get-TelemetryUploadStatus.ps1

Reads the live **DiagTrack** registry on the device and reports the telemetry
upload status and the cached collector endpoints, converting Windows FILETIME
values to readable UTC and local date/time.

Use it as a quick health check after running
`Test-AutopatchDiagnosticDataConnectivity.ps1`: it shows whether diagnostic data
is actually uploading successfully, when the last successful upload happened, how
many connections are failing, and which regional collector endpoints the device
has cached.

### What it reports

**Telemetry Upload Status** (from `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack`):

| Value | Meaning |
|-------|---------|
| `LastSuccessfulUploadTime` | Most recent successful upload of any kind |
| `LastSuccessfulNormalUploadTime` | Last successful normal-priority upload |
| `LastSuccessfulRealtimeUploadTime` | Last successful realtime upload |
| `LastSuccessfulCostDeferredUploadTime` | Last successful cost-deferred upload |
| `LastInvalidHttpCode` | Most recent invalid HTTP response code (shown as hex) |
| `VortexHttpAttempts` | Total upload attempts to the Vortex ingestion service |
| `VortexHttpFailures4xx` | Client-side (4xx) upload failures — often proxy/auth blocks |
| `VortexHttpFailures5xx` | Server-side (5xx) upload failures |
| `SuccessfulConnections` | Count of successful connections |
| `FailedConnections` | Count of failed connections |

**Cached Collector Endpoints** (from the `RegionalSettings` subkey):

| Value | Meaning |
|-------|---------|
| `CollectorFunctionalRegionalUrl` | Regional functional-data collector URL |
| `CollectorDiagnosticRegionalUrl` | Regional diagnostic-data collector URL |
| `WatsonRegionalServerName` | Regional Windows Error Reporting (Watson) server |
| `LastSettingsUpdateTime (config)` | When the device last refreshed its telemetry configuration |

### Example

```powershell
.\Get-TelemetryUploadStatus.ps1
```

### Requirements

- Windows PowerShell 5.1+
- Run on the affected device; run elevated for the most complete results

### Credits

- **Author:** Sandy Zeng
