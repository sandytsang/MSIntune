<#
.SYNOPSIS
    DiagTrack Telemetry Upload Status
    Reads the live registry and converts FILETIME values to readable date/time.

.NOTES
    Author : Sandy Zeng
#>

$diagTrack = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack'
$regional  = "$diagTrack\RegionalSettings"

# Helper: convert a Windows FILETIME (decimal or 0x hex) to UTC + local strings
function Convert-FileTime {
    param([Parameter(Mandatory)][long]$Ticks)
    if ($Ticks -le 0) { return 'Not set / never' }
    $utc = [DateTime]::FromFileTimeUtc($Ticks)
    '{0:yyyy-MM-dd HH:mm:ss} UTC  ({1:yyyy-MM-dd HH:mm:ss} local)' -f $utc, $utc.ToLocalTime()
}

# --- Upload status counters ---
$dt = Get-ItemProperty -Path $diagTrack -ErrorAction SilentlyContinue

Write-Host "`n=== Telemetry Upload Status ===" -ForegroundColor Cyan
[PSCustomObject]@{
    'LastSuccessfulUploadTime'             = Convert-FileTime $dt.LastSuccessfulUploadTime
    'LastSuccessfulNormalUploadTime'       = Convert-FileTime $dt.LastSuccessfulNormalUploadTime
    'LastSuccessfulRealtimeUploadTime'     = Convert-FileTime $dt.LastSuccessfulRealtimeUploadTime
    'LastSuccessfulCostDeferredUploadTime' = Convert-FileTime $dt.LastSuccessfulCostDeferredUploadTime
    'LastInvalidHttpCode'                  = ('0x{0:X8}' -f [int]$dt.LastInvalidHttpCode)
    'VortexHttpAttempts'                   = $dt.VortexHttpAttempts
    'VortexHttpFailures4xx'                = $dt.VortexHttpFailures4xx
    'VortexHttpFailures5xx'                = $dt.VortexHttpFailures5xx
    'SuccessfulConnections'                = $dt.SuccessfulConnections
    'FailedConnections'                    = $dt.FailedConnections
} | Format-List

# --- Cached collector endpoints + when config was last refreshed ---
$rs = Get-ItemProperty -Path $regional -ErrorAction SilentlyContinue

Write-Host "=== Cached Collector Endpoints ===" -ForegroundColor Cyan
[PSCustomObject]@{
    'CollectorFunctionalRegionalUrl'  = $rs.CollectorFunctionalRegionalUrl
    'CollectorDiagnosticRegionalUrl'  = $rs.CollectorDiagnosticRegionalUrl
    'WatsonRegionalServerName'        = $rs.WatsonRegionalServerName
    'LastSettingsUpdateTime (config)' = Convert-FileTime $rs.LastSettingsUpdateTime
} | Format-List