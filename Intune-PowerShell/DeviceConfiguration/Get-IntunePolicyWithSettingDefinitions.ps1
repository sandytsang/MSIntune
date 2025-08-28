<#
.SYNOPSIS
   This script retrieves all Settings Catalog policies from Intune. for each policy to get settings with expanded setting definitions
.DESCRIPTION
    This script is detecting if need to format the data disk on the device.
.NOTES
    Requires Microsoft.Graph.DeviceManagement module
    Requires Microsoft.Graph.Authentication module

    Author: Sandy Zeng
    Version: 1.0

    Version histroy: 
    1.0.0 - 27.08.2025 Initial release
    1.0.1 - 28.08.2025 Move summary file to root folder
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\SettingsCatalogPolicies",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeTimestamp,
    
    [Parameter(Mandatory = $false)]
    [int]$JsonDepth = 50
)

# Import required modules
try {
    Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "Required modules imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to import required modules. Please install Microsoft.Graph.DeviceManagement module." -ForegroundColor Red
    Write-Host "Run: Install-Module Microsoft.Graph.DeviceManagement -Force" -ForegroundColor Yellow
    exit 1
}

# Function to sanitize filename
function Get-SafeFileName {
    param([string]$FileName)
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    foreach ($char in $invalidChars) {
        $FileName = $FileName.Replace($char, '_')
    }
    return $FileName
}

# Function to create output directory
function New-OutputDirectory {
    param([string]$Path)
    
    if ($IncludeTimestamp) {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $Path = Join-Path $Path "Export_$timestamp"
    }
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "Created output directory: $Path" -ForegroundColor Green
    }
    
    return $Path
}

# Main execution
try {
    Write-Host "Starting Settings Catalog Policy Export..." -ForegroundColor Cyan
    
    # Check if already connected to Microsoft Graph
    $context = Get-MgContext
    if (-not $context) {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
        Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All" -NoWelcome
        Write-Host "Connected to Microsoft Graph" -ForegroundColor Green
    } else {
        Write-Host "Already connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
    }
    
    # Create output directory
    $outputDir = New-OutputDirectory -Path $OutputPath
    
    # First, get all Settings Catalog policies (basic info only)
    Write-Host "Retrieving Settings Catalog policies list..." -ForegroundColor Yellow
    
    $listUri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies"
    $policies = @()
    $nextLink = $listUri
    
    do {
        try {
            $response = Invoke-MgGraphRequest -Uri $nextLink -Method GET
            $policies += $response.value
            $nextLink = $response.'@odata.nextLink'
            
            Write-Host "Retrieved $($policies.Count) policies so far..." -ForegroundColor Gray
        }
        catch {
            Write-Host "Error retrieving policies list: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    } while ($nextLink)
    
    Write-Host "Retrieved $($policies.Count) Settings Catalog policies" -ForegroundColor Green
    
    # Process each policy with individual API calls
    $exportedCount = 0
    $errorCount = 0
    
    Write-Host "Making individual API calls for each policy..." -ForegroundColor Yellow
    
    foreach ($policy in $policies) {
        try {
            Write-Host "Processing policy: $($policy.name)" -ForegroundColor Cyan
            
            # Make individual API call for this policy's settings with expanded definitions
            $policyDetailUri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($policy.id)/settings?`$expand=settingDefinitions"
            
            $rawPolicyResponse = Invoke-MgGraphRequest -Uri $policyDetailUri -Method GET
            
            # Create safe filename
            $policyName = if ($policy.name) { $policy.name } else { "Policy_$($policy.id)" }
            $safeFileName = Get-SafeFileName -FileName $policyName
            $fileName = "$safeFileName.json"
            $filePath = Join-Path $outputDir $fileName
            
            # Handle duplicate filenames
            $counter = 1
            while (Test-Path $filePath) {
                $fileName = "$safeFileName`_$counter.json"
                $filePath = Join-Path $outputDir $fileName
                $counter++
            }
            
            # Export raw response to JSON
            try {
                $jsonContent = $rawPolicyResponse | ConvertTo-Json -Depth $JsonDepth -WarningAction SilentlyContinue
                $jsonContent | Out-File -FilePath $filePath -Encoding UTF8
                
                # Check if the JSON content contains truncation warning
                if ($jsonContent -match "serialization has exceeded the set depth") {
                    Write-Host "Warning: Policy '$($policy.name)' may have truncated data due to complex nesting" -ForegroundColor Yellow
                }
            }
            catch {
                # Fallback: try with maximum PowerShell depth (100)
                Write-Host "Retrying export with maximum depth for policy: $($policy.name)" -ForegroundColor Yellow
                $rawPolicyResponse | ConvertTo-Json -Depth 100 -WarningAction SilentlyContinue | Out-File -FilePath $filePath -Encoding UTF8
            }
            
            Write-Host "Exported: $($policy.name) -> $fileName" -ForegroundColor Green
            $exportedCount++
        }
        catch {
            Write-Host "Failed to export policy '$($policy.name)': $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }
    
    # Summary
    Write-Host "" -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Export Summary:" -ForegroundColor Cyan
    Write-Host "  Total policies found: $($policies.Count)" -ForegroundColor White
    Write-Host "  Successfully exported: $exportedCount" -ForegroundColor Green
    Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
    Write-Host "  Output directory: $outputDir" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    
    if ($exportedCount -gt 0) {
        Write-Host "Settings Catalog policies exported successfully!" -ForegroundColor Green
        
        # Create summary file
        $summary = @{
            ExportDate = Get-Date
            TotalPolicies = $policies.Count
            ExportedPolicies = $exportedCount
            Errors = $errorCount
            OutputDirectory = $outputDir
            Policies = $policies | Select-Object id, name, description, platforms, technologies, templateReference
        }
        
        $summaryPath = Join-Path (Get-Location) "SettingsCatalogPolicies_ExportSummary.json"
        $summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryPath -Encoding UTF8
        Write-Host "Export summary saved to: ExportSummary.json" -ForegroundColor Green
    }
}
catch {
    Write-Host "Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    Write-Host "" -ForegroundColor White
    Write-Host "Script execution completed." -ForegroundColor Cyan
}
