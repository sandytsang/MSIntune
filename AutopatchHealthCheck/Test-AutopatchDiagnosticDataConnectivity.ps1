<#
.SYNOPSIS
    Diagnoses the Windows Autopatch "diagnostic data connectivity" device
    readiness failure by validating the on-device prerequisites and endpoints.
.DESCRIPTION
    Validates the prerequisites Windows Autopatch needs for the
    "diagnostic data connectivity" device readiness check:
      - DiagTrack service state
      - Diagnostic data (AllowTelemetry) level >= Required
      - Diagnostic data processor configuration endpoints (region-aware)
      - Core telemetry / WER / OCA / auth / settings endpoints
      - Autopatch & Intune service endpoints
      - WinHTTP system proxy configuration
      - Optional TLS/SSL inspection detection, reported inline in the TLSInspection
        column (True = intercepted, False = clean) when -CheckTlsInspection is set
      - Optional real HTTPS POST to the ingestion endpoints (-TestHttpsPost) to
        catch app-layer proxy blocks (403/407) and TLS interception a TCP test misses
      - Optional DiagTrack connection-state event-log read (-CheckEventLog),
        surfacing Event ID 29 "some connections have failed"
      - Optional on-device endpoint discovery from the DNS client cache (-DiscoverEndpoints)
    Source references:
      - learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
      - learn.microsoft.com/windows/deployment/windows-autopatch/prepare/windows-autopatch-configure-network
.EXAMPLE
    .\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region US

    Runs the US-region checks (services, policy, and all documented
    diagnostic/telemetry/Autopatch endpoints) and prints a colored results table.
.EXAMPLE
    .\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region EU

    Runs the checks using the EU Data Boundary endpoint profile
    (eu-v10c / eu-watsonc / devicelistenprod.eudb.microsoft.com). Use this for
    tenants whose billing address is in the EU/EFTA, Middle East/Africa, or
    non-EU Europe.
.EXAMPLE
    .\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region US -CheckTlsInspection

    Also checks each reachable HTTPS endpoint for TLS/SSL interception. Results
    appear in the TLSInspection column (True = intercepted -> must be excluded
    from the inspecting proxy, False = clean).
.EXAMPLE
    .\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region US -DiscoverEndpoints

    Additionally reads the local DNS client cache to reveal the concrete
    hostnames behind the documented wildcards (payloadprod*.blob.core.windows.net,
    diagnostic blobs, etc.) and connectivity-tests them as "<Category> (Discovered)".
.EXAMPLE
    .\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region US -TestHttpsPost -CheckEventLog

    Best for an Event ID 29 "connection failed" symptom where the network looks
    fine: sends a real HTTPS POST to the ingestion endpoints (catches 403/407
    proxy blocks and TLS interception) and reads the DiagTrack
    UniversalTelemetryClient/Operational log for recent Event ID 29 events.
.EXAMPLE
    .\Test-AutopatchDiagnosticDataConnectivity.ps1 -Region EU -CheckTlsInspection -DiscoverEndpoints

    Full run: EU endpoint profile, TLS-inspection detection, and DNS-cache
    endpoint discovery combined.
.NOTES
    Author : Sandy Zeng
    Credits: Endpoint coverage and TLS-inspection ideas were informed in part by
             Martin Himken's IntuneNetworkRequirements project
             (github.com/MHimken/IntuneNetworkRequirements).
    Requires Windows PowerShell 5.1+ (no PS7-only syntax used).
#>

[CmdletBinding()]
param(
    # Set to 'EU' for tenants whose billing address is in the EU Data Boundary
    # (also Middle East/Africa and non-EU Europe). Otherwise 'US'. Mandatory.
    [Parameter(Mandatory)]
    [ValidateSet('US', 'EU')]
    [string]$Region,

    # Detect TLS/SSL inspection (HTTPS interception) on certificate-pinned
    # diagnostic/telemetry/Autopatch endpoints. Result is shown in the
    # TLSInspection column (True = intercepted, False = clean) on each reachable
    # HTTPS row. These endpoints MUST be excluded from TLS-inspecting proxies;
    # interception silently breaks telemetry upload.
    [switch]$CheckTlsInspection,

    # Discover the REAL hostnames behind the documented wildcards
    # (payloadprod*.blob.core.windows.net, *.webpubsub.azure.com, diagnostic blobs)
    # by reading the local DNS client cache.
    [switch]$DiscoverEndpoints,

    # Perform a real HTTPS POST to the telemetry ingestion endpoints (not just a
    # TCP test). This exercises the application layer the way DiagTrack does, so
    # it catches proxy 403/407 blocks and TLS interception that a TCP test misses.
    [switch]$TestHttpsPost,

    # Read the Microsoft-Windows-UniversalTelemetryClient/Operational event log
    # and surface DiagTrack's own connection-state events (e.g. Event ID 29 -
    # "some connections have failed"), which pinpoint what the client itself sees.
    [switch]$CheckEventLog
)

$ErrorActionPreference = 'Continue'
Write-Host "=== Windows Autopatch Diagnostic Connectivity Check ===" -ForegroundColor Cyan
Write-Host "Region profile: $Region`n" -ForegroundColor DarkCyan

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [string]$Category,
        [string]$Check,
        [string]$Status,   # PASS / FAIL / WARN / INFO
        [string]$Detail,
        [string]$TLSInspection = 'N/A'   # True (interception) / False (clean) / Error / N/A
    )
    $results.Add([pscustomobject]@{
        Category      = $Category
        Check         = $Check
        Status        = $Status
        TLSInspection = $TLSInspection
        Detail        = $Detail
    })
}

function Get-TlsInspectionState {
    # Opens a real TLS handshake, accepts any server certificate, then inspects
    # the issuer chain. Microsoft diagnostic/telemetry/Autopatch endpoints are
    # served by Microsoft/public CAs. If a corporate proxy is intercepting and
    # re-signing the traffic, the issuer will be the proxy's CA instead.
    # Returns 'True' if interception is detected, 'False' if clean, 'Error' on failure.
    param([string]$HostName, [int]$Port = 443)

    # Issuer markers that indicate legitimate Microsoft / well-known public CAs.
    $trustedIssuerPatterns = @(
        'Microsoft', 'DigiCert', 'Baltimore', 'GlobalSign',
        'Entrust', 'GeoTrust', 'Sectigo', 'USERTrust', 'Amazon'
    )

    $tcp = $null
    $ssl = $null
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect($HostName, $Port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne(5000)) { throw 'TCP connection timed out' }
        $tcp.EndConnect($iar)

        # Accept any cert so we can examine it ourselves rather than failing the handshake.
        $validation = [System.Net.Security.RemoteCertificateValidationCallback] { param($s, $c, $ch, $e) $true }
        $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, $validation)
        $ssl.AuthenticateAsClient($HostName)

        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$ssl.RemoteCertificate
        $issuer = $cert.Issuer

        foreach ($p in $trustedIssuerPatterns) {
            if ($issuer -match $p) { return 'False' }
        }
        return 'True'   # unexpected issuer -> traffic is being intercepted
    }
    catch {
        return 'Error'
    }
    finally {
        if ($ssl) { $ssl.Dispose() }
        if ($tcp) { $tcp.Dispose() }
    }
}

function Test-Endpoint {
    param([string]$Category, [string]$HostName, [int]$Port = 443, [string]$ExtraDetail)

    $suffix = if ($ExtraDetail) { "; $ExtraDetail" } else { '' }

    # Wildcard hosts cannot be resolved directly; flag for manual proxy/firewall review.
    if ($HostName -like '*`**') {
        Add-Result $Category $HostName 'INFO' "Wildcard host - verify proxy/firewall allow rule manually$suffix" 'N/A'
        return
    }

    try {
        $t = Test-NetConnection -ComputerName $HostName -Port $Port -WarningAction SilentlyContinue -ErrorAction Stop
        $status = if ($t.TcpTestSucceeded) { 'PASS' } else { 'FAIL' }
        $resolved = if ($t.RemoteAddress) { $t.RemoteAddress } else { 'no DNS' }

        # Populate the TLSInspection column when -CheckTlsInspection is set and the
        # HTTPS endpoint is reachable. These endpoints MUST bypass TLS inspection.
        $tls = 'N/A'
        if ($CheckTlsInspection -and $Port -eq 443 -and $t.TcpTestSucceeded) {
            $tls = Get-TlsInspectionState $HostName $Port
        }

        Add-Result $Category "$HostName`:$Port" $status "TcpTestSucceeded=$($t.TcpTestSucceeded); Resolved=$resolved$suffix" $tls
    }
    catch {
        Add-Result $Category "$HostName`:$Port" 'FAIL' "$($_.Exception.Message)$suffix" 'N/A'
    }
}

function Test-HttpsPost {
    # Sends a real HTTPS POST to a telemetry ingestion endpoint, exercising the
    # application layer (TLS handshake + HTTP request/response) the way DiagTrack
    # does - rather than only confirming a TCP socket opens. The endpoints accept
    # POSTs to /OneCollector/1.0/; any HTTP response (even 400/411) proves the
    # request traversed the proxy/firewall to the service. A 403/407, a TLS
    # failure, or a connection error indicates an app-layer block or interception.
    param([string]$Category, [string]$HostName)

    $uri = "https://$HostName/OneCollector/1.0/"
    try {
        $resp = Invoke-WebRequest -Uri $uri -Method Post -Body '' -TimeoutSec 15 `
            -UseBasicParsing -ErrorAction Stop
        $code = [int]$resp.StatusCode
        Add-Result $Category "$HostName (POST)" 'PASS' "HTTP $code - request reached the service"
    }
    catch {
        $code = $null
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }

        if ($null -ne $code) {
            # The service answered. 400/404/411 etc. still prove app-layer reachability.
            # 403/407 are proxy/auth blocks that a TCP test would never reveal.
            $status = if ($code -in 403, 407) { 'FAIL' } else { 'PASS' }
            $note = switch ($code) {
                403 { 'HTTP 403 - blocked by proxy/firewall (app-layer)' }
                407 { 'HTTP 407 - proxy authentication required for this context' }
                default { "HTTP $code - request reached the service" }
            }
            Add-Result $Category "$HostName (POST)" $status $note
        }
        else {
            # No HTTP response at all: TLS interception, connection reset, or timeout.
            Add-Result $Category "$HostName (POST)" 'FAIL' "No HTTP response: $($_.Exception.Message)"
        }
    }
}

# ------------------------------------------------------------------
# 1. DiagTrack service (Connected User Experiences and Telemetry)
#    Doc: learn.microsoft.com/windows/deployment/windows-autopatch/prepare/windows-autopatch-configure-network
#         (DiagTrack must be running to upload diagnostic data / telemetry)
# ------------------------------------------------------------------
$svc = Get-Service -Name DiagTrack -ErrorAction SilentlyContinue
if ($svc) {
    $startMode = (Get-CimInstance Win32_Service -Filter "Name='DiagTrack'").StartMode
    $ok = ($svc.Status -eq 'Running') -and ($startMode -in @('Auto', 'Automatic'))
    Add-Result 'Service' 'DiagTrack' $(if ($ok) { 'PASS' } else { 'FAIL' }) "Status=$($svc.Status); StartMode=$startMode"
}
else {
    Add-Result 'Service' 'DiagTrack' 'FAIL' 'Service not found'
}

# ------------------------------------------------------------------
# 2. Diagnostic data level (AllowTelemetry) — needs >= 1 (Required)
#    Doc: learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
#         ("Diagnostic data settings" / "Manage diagnostic data using Group Policy and MDM")
# ------------------------------------------------------------------
$polPath  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
$basePath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
$level = $null
foreach ($p in @($polPath, $basePath)) {
    $v = (Get-ItemProperty -Path $p -Name AllowTelemetry -ErrorAction SilentlyContinue).AllowTelemetry
    if ($null -ne $v) { $level = $v; break }
}
if ($null -ne $level) {
    $status = if ($level -ge 1) { 'PASS' } else { 'FAIL' }
    Add-Result 'Policy' 'AllowTelemetry' $status "Value=$level (0=Off,1=Required,2=Enhanced,3=Optional)"
}
else {
    Add-Result 'Policy' 'AllowTelemetry' 'WARN' 'Not set - edition default applies (Win10 1903+ defaults to Required)'
}

# ------------------------------------------------------------------
# 3. Diagnostic data PROCESSOR CONFIG endpoints (Autopatch prerequisite) — region-aware
#    Doc: learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
#         ("Enable Windows diagnostic data processor configuration" > "Prerequisites")
# ------------------------------------------------------------------
if ($Region -eq 'EU') {
    $processorEndpoints = @(
        'eu-v10c.events.data.microsoft.com'
        'eu-watsonc.events.data.microsoft.com'
        'settings-win.data.microsoft.com'
        '*.blob.core.windows.net'   # wildcard - flagged INFO, verify proxy allow-rule
    )
}
else {
    $processorEndpoints = @(
        'us-v10c.events.data.microsoft.com'
        'watsonc.events.data.microsoft.com'
        'settings-win.data.microsoft.com'
        '*.blob.core.windows.net'   # wildcard - flagged INFO, verify proxy allow-rule
    )
}
foreach ($e in $processorEndpoints) { Test-Endpoint 'ProcessorConfig' $e }

# ------------------------------------------------------------------
# 4. Core Connected User Experiences and Telemetry endpoints
#    Doc: learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
#         ("How Microsoft handles diagnostic data" > "Endpoints" table)
# ------------------------------------------------------------------
$telemetryEndpoints = @(
    'v10.events.data.microsoft.com'
    'v10c.events.data.microsoft.com'
    'v10.vortex-win.data.microsoft.com'
    'self.events.data.microsoft.com'
    'functional.events.data.microsoft.com'
    'telecommand.telemetry.microsoft.com'
    'www.telecommandsvc.microsoft.com'
)
foreach ($e in $telemetryEndpoints) { Test-Endpoint 'Telemetry' $e }

# ------------------------------------------------------------------
# 5. Windows Error Reporting endpoints
#    Doc: learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
#         ("Endpoints" table > "Windows Error Reporting" row)
# ------------------------------------------------------------------
$werEndpoints = @(
    'watson.telemetry.microsoft.com'
    'watson.events.data.microsoft.com'
    'umwatsonc.events.data.microsoft.com'
    'ceuswatcab01.blob.core.windows.net'
    'ceuswatcab02.blob.core.windows.net'
    'eaus2watcab01.blob.core.windows.net'
    'eaus2watcab02.blob.core.windows.net'
    'weus2watcab01.blob.core.windows.net'
    'weus2watcab02.blob.core.windows.net'
)
foreach ($e in $werEndpoints) { Test-Endpoint 'ErrorReporting (WER)' $e }

# ------------------------------------------------------------------
# 6. Online Crash Analysis endpoints
#    Doc: learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
#         ("Endpoints" table > "Online Crash Analysis" row)
# ------------------------------------------------------------------
$ocaEndpoints = @(
    'oca.telemetry.microsoft.com'
    'oca.microsoft.com'
    'kmwatsonc.events.data.microsoft.com'
)
foreach ($e in $ocaEndpoints) { Test-Endpoint 'CrashReporting (OCA)' $e }

# ------------------------------------------------------------------
# 7. Authentication + Settings endpoints
#    Doc: learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
#         ("Endpoints" table > "Authentication" and "Settings" rows)
# ------------------------------------------------------------------
Test-Endpoint 'Auth'     'login.live.com'
Test-Endpoint 'Settings' 'settings-win.data.microsoft.com'

# ------------------------------------------------------------------
# 7b. Diagnostics data upload / Endpoint Analytics (concrete blobs)
#     These are the specific blob endpoints behind *.blob.core.windows.net
#     used for diagnostic data upload. Autopatch readiness relies on
#     Endpoint Analytics, so test them directly rather than via wildcard.
#     Doc: learn.microsoft.com/mem/intune/fundamentals/intune-endpoints
#          ("Endpoint analytics" / "Delivery Optimization and diagnostics data upload")
# ------------------------------------------------------------------
$diagUploadEndpoints = @(
    'lgmsapeweu.blob.core.windows.net'
    'lgmsapewus2.blob.core.windows.net'
    'lgmsapesea.blob.core.windows.net'
    'lgmsapeaus.blob.core.windows.net'
    'lgmsapeind.blob.core.windows.net'
)
foreach ($e in $diagUploadEndpoints) { Test-Endpoint 'DiagnosticUpload' $e }

# ------------------------------------------------------------------
# 8. Autopatch service endpoints — region-aware
#    Doc: learn.microsoft.com/windows/deployment/windows-autopatch/prepare/windows-autopatch-configure-network
#         ("Network endpoints" tables)
# ------------------------------------------------------------------
$deviceListener = if ($Region -eq 'EU') {
    'devicelistenprod.eudb.microsoft.com'
} else {
    'devicelistenerprod.microsoft.com'
}

$autopatchEndpoints = @(
    'mmdcustomer.microsoft.com'
    'mmdls.microsoft.com'
    $deviceListener
    'login.windows.net'
    'device.autopatch.microsoft.com'
    'services.autopatch.microsoft.com'
    'payloadprod*.blob.core.windows.net'   # wildcard - flagged INFO
    '*.webpubsub.azure.com'                # wildcard - flagged INFO
)
foreach ($e in $autopatchEndpoints) { Test-Endpoint 'Autopatch' $e }

# ------------------------------------------------------------------
# 9. WinHTTP system proxy (telemetry uses local-system WinHTTP context)
#    Doc: learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
#         ("Proxy server authentication" > "Device proxy authentication")
# ------------------------------------------------------------------
$winhttp = (netsh winhttp show proxy) -join ' '
Add-Result 'Proxy' 'WinHTTP' 'INFO' $winhttp.Trim()

$deap = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' `
    -Name DisableEnterpriseAuthProxy -ErrorAction SilentlyContinue).DisableEnterpriseAuthProxy
if ($null -ne $deap) {
    Add-Result 'Proxy' 'DisableEnterpriseAuthProxy' 'INFO' "Value=$deap (1=device-context proxy auth; required if using Defender for Endpoint)"
}

# ------------------------------------------------------------------
# 9b. Application-layer HTTPS POST test (opt-in: -TestHttpsPost)
#     A TCP test only proves a socket opens. DiagTrack does a full HTTPS POST,
#     so a proxy can pass TCP yet block the POST (403), demand auth (407), or
#     intercept TLS. This sends a real POST to the ingestion endpoints to catch
#     app-layer failures behind an Event ID 29 "connection failed" symptom.
#     Doc: learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
#          ("Endpoints" - Connected User Experiences and Telemetry)
# ------------------------------------------------------------------
if ($TestHttpsPost) {
    $postEndpoints = @(
        'v10.events.data.microsoft.com'
        'v10c.events.data.microsoft.com'
        'self.events.data.microsoft.com'
    )
    if ($Region -eq 'EU') { $postEndpoints += 'eu-v10c.events.data.microsoft.com' }
    else                  { $postEndpoints += 'us-v10c.events.data.microsoft.com' }

    foreach ($e in ($postEndpoints | Select-Object -Unique)) {
        Test-HttpsPost 'HttpsPost' $e
    }
}

# ------------------------------------------------------------------
# 9c. DiagTrack connection-state event log (opt-in: -CheckEventLog)
#     Reads what the telemetry client ITSELF reports. Event ID 29 = "some
#     connections have failed since the previous period" is the classic symptom
#     where network checks pass but uploads still fail. This surfaces the most
#     recent connection-state events so you can correlate timing and frequency.
#     Log: Microsoft-Windows-UniversalTelemetryClient/Operational
# ------------------------------------------------------------------
if ($CheckEventLog) {
    try {
        $utcEvents = Get-WinEvent -LogName 'Microsoft-Windows-UniversalTelemetryClient/Operational' `
            -MaxEvents 200 -ErrorAction Stop

        # Event ID 29 = connection failure state; 30 = connection restored (build-dependent).
        $failEvents = $utcEvents | Where-Object { $_.Id -eq 29 }
        if ($failEvents) {
            $latest = $failEvents | Sort-Object TimeCreated -Descending | Select-Object -First 1
            $count  = $failEvents.Count
            $msg    = ($latest.Message -split "`r?`n" | Select-Object -First 1).Trim()
            Add-Result 'EventLog' 'UTC-Id29-ConnectionFailed' 'FAIL' `
                "Last=$($latest.TimeCreated); Count(last200)=$count; $msg"
        }
        else {
            Add-Result 'EventLog' 'UTC-Id29-ConnectionFailed' 'PASS' `
                'No Event ID 29 (connection failed) in the last 200 UTC events'
        }

        # Surface the most recent connection-state event (any id) for context.
        $lastState = $utcEvents | Where-Object { $_.Id -in 29, 30 } |
            Sort-Object TimeCreated -Descending | Select-Object -First 1
        if ($lastState) {
            $stateText = if ($lastState.Id -eq 30) { 'connections restored' } else { 'connections failing' }
            Add-Result 'EventLog' 'UTC-LastConnectionState' 'INFO' `
                "Id=$($lastState.Id) ($stateText) at $($lastState.TimeCreated)"
        }
    }
    catch {
        Add-Result 'EventLog' 'UTC-Operational' 'WARN' "Log unavailable: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------------
# 10. Endpoint discovery from the device (opt-in: -DiscoverEndpoints)
#     Surfaces the actual hostnames behind the documented wildcards by
#     reading recently resolved names from the local DNS client cache.
#     Useful to learn the concrete payloadprod*/webpubsub/blob names so
#     they can be verified against proxy/firewall allow rules.
# ------------------------------------------------------------------
if ($DiscoverEndpoints) {
    # Patterns that map back to the wildcard/diagnostic endpoints of interest.
    $discoverPattern = 'blob\.core\.windows\.net|webpubsub\.azure\.com|events\.data\.microsoft\.com|autopatch\.microsoft\.com|telemetry\.microsoft\.com|vortex'

    # Classify a discovered hostname into the service area it belongs to,
    # so discovered endpoints report their actual category instead of a generic label.
    function Get-EndpointCategory {
        param([string]$HostName)
        switch -Regex ($HostName) {
            'watcab\d+\.blob\.core\.windows\.net'   { return 'ErrorReporting (WER)' }
            'watson'                                { return 'ErrorReporting (WER)' }
            'kmwatson|oca\.'                        { return 'CrashReporting (OCA)' }
            'payloadprod.*\.blob\.core\.windows\.net' { return 'AutopatchPayload' }
            'webpubsub\.azure\.com'                 { return 'AutopatchPubSub' }
            'autopatch\.microsoft\.com'             { return 'Autopatch' }
            'lgmsape.*\.blob\.core\.windows\.net'   { return 'DiagnosticUpload' }
            '-v10c\.events\.data\.microsoft\.com'   { return 'ProcessorConfig' }
            'blob\.core\.windows\.net'              { return 'DiagnosticUpload' }
            'vortex|events\.data\.microsoft\.com'   { return 'Telemetry' }
            'telemetry\.microsoft\.com'             { return 'Telemetry' }
            default                                 { return 'Other' }
        }
    }

    # Discover endpoints from the local DNS client cache (recently resolved names).
    # NOTE: the UniversalTelemetryClient/Operational event log is intentionally NOT
    # used - it only records upload success/failure, never the URLs or IPs, so it
    # yields no usable hostnames.
    try {
        $dns = Get-DnsClientCache -ErrorAction Stop |
            Where-Object { $_.Entry -match $discoverPattern } |
            Select-Object -ExpandProperty Entry -Unique | Sort-Object
        if ($dns) {
            foreach ($name in $dns) {
                $cat = Get-EndpointCategory $name
                Test-Endpoint "$cat (Discovered)" $name -ExtraDetail 'Source=DNSCache'
            }
        }
        else {
            Add-Result 'Discovered' 'none(DNSCache)' 'INFO' 'No matching names cached (try after the device has uploaded telemetry)'
        }
    }
    catch {
        Add-Result 'Discovered' 'error(DNSCache)' 'WARN' $_.Exception.Message
    }
}

# ------------------------------------------------------------------
# Output (colored)
# ------------------------------------------------------------------
$sorted = $results | Sort-Object Category, Check

# Column widths
$catW   = ($sorted.Category | Measure-Object -Property Length -Maximum).Maximum
$chkW   = ($sorted.Check    | Measure-Object -Property Length -Maximum).Maximum
$catW   = [Math]::Max($catW, 8)
$chkW   = [Math]::Max($chkW, 5)
$tlsW   = 13   # 'TLSInspection'

# Header
Write-Host ("{0}  {1}  {2}  {3}  {4}" -f `
    'Category'.PadRight($catW), 'Check'.PadRight($chkW), 'Status', 'TLSInspection'.PadRight($tlsW), 'Detail') -ForegroundColor White
Write-Host ("{0}  {1}  {2}  {3}  {4}" -f `
    ('-' * $catW), ('-' * $chkW), '------', ('-' * $tlsW), '------') -ForegroundColor DarkGray

foreach ($r in $sorted) {
    $color = switch ($r.Status) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'WARN' { 'Yellow' }
        default { 'Gray' }   # INFO
    }

    # TLSInspection column: True (interception) is bad, False is good.
    $tlsColor = switch ($r.TLSInspection) {
        'True'  { 'Red' }
        'False' { 'Green' }
        'Error' { 'Yellow' }
        default { 'DarkGray' }   # N/A
    }

    # Print row prefix in default color, status + TLS each in their color, detail in gray
    Write-Host ("{0}  {1}  " -f $r.Category.PadRight($catW), $r.Check.PadRight($chkW)) -NoNewline
    Write-Host ($r.Status.PadRight(6)) -ForegroundColor $color -NoNewline
    Write-Host ("  {0}" -f $r.TLSInspection.PadRight($tlsW)) -ForegroundColor $tlsColor -NoNewline
    Write-Host ("  {0}" -f $r.Detail) -ForegroundColor DarkGray
}