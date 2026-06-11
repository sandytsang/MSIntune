<#
.SYNOPSIS
    DiagTrack Telemetry Upload Status
    Reads the live registry and converts FILETIME values to readable date/time.

.NOTES
    Author : Sandy Zeng
#>

$diagTrack = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack'
$regional  = "$diagTrack\RegionalSettings"
$aria      = "$diagTrack\HeartBeats\Aria"
$seville   = "$diagTrack\SevilleEventlogManager"

function Convert-FileTime {
    param([Parameter(Mandatory)][long]$Ticks)
    if ($Ticks -le 0) { return 'Not set / never' }
    $utc = [DateTime]::FromFileTimeUtc($Ticks)
    '{0:yyyy-MM-dd HH:mm:ss} UTC  ({1:yyyy-MM-dd HH:mm:ss} local)' -f $utc, $utc.ToLocalTime()
}

$dt = Get-ItemProperty -Path $diagTrack -ErrorAction SilentlyContinue
$ar = Get-ItemProperty -Path $aria      -ErrorAction SilentlyContinue
$sv = Get-ItemProperty -Path $seville   -ErrorAction SilentlyContinue

Write-Host "`n=== Telemetry Upload Status ===" -ForegroundColor Cyan
[PSCustomObject]@{
    'LastSuccessfulUploadTime'             = Convert-FileTime $dt.LastSuccessfulUploadTime
    'LastSuccessfulNormalUploadTime'       = Convert-FileTime $dt.LastSuccessfulNormalUploadTime
    'LastSuccessfulRealtimeUploadTime'     = Convert-FileTime $dt.LastSuccessfulRealtimeUploadTime
    'LastSuccessfulCostDeferredUploadTime' = Convert-FileTime $dt.LastSuccessfulCostDeferredUploadTime
    'LastInvalidHttpCode' = ('0x{0:X8}' -f [uint32]$ar.LastInvalidHttpCode)
    'VortexHttpAttempts'                   = $ar.VortexHttpAttempts
    'VortexHttpFailures4xx'                = $ar.VortexHttpFailures4xx
    'VortexHttpFailures5xx'                = $ar.VortexHttpFailures5xx
    'SuccessfulConnections'                = $sv.SuccessfulConnections
    'FailedConnections'                    = $sv.FailedConnections
} | Format-List

$rs = Get-ItemProperty -Path $regional -ErrorAction SilentlyContinue
Write-Host "=== Cached Collector Endpoints ===" -ForegroundColor Cyan
[PSCustomObject]@{
    'CollectorFunctionalRegionalUrl'  = $rs.CollectorFunctionalRegionalUrl
    'CollectorDiagnosticRegionalUrl'  = $rs.CollectorDiagnosticRegionalUrl
    'WatsonRegionalServerName'        = $rs.WatsonRegionalServerName
    'LastSettingsUpdateTime (config)' = Convert-FileTime $rs.LastSettingsUpdateTime
} | Format-List