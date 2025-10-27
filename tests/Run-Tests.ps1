# tests/Run-Tests.ps1
# Script to run all tests for sync-standards.ps1

[CmdletBinding()]
param(
    [switch]$UnitOnly,          # Run only unit tests
    [switch]$IntegrationOnly,   # Run only integration tests
    [switch]$PassThru,          # Return test results object
    [string]$OutputFormat = "NUnitXml",  # Output format: NUnitXml, JUnitXml, None
    [string]$OutputFile,        # Output file path
    [switch]$Show,              # Show test results in console
    [string]$TestName = "*"     # Filter tests by name pattern
)

# Import Pester module
$PesterVersionRequired = "5.7.1"
$PesterModule = Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -ge [version]$PesterVersionRequired } | Sort-Object Version -Descending | Select-Object -First 1

if (-not $PesterModule) {
    Write-Warning "Pester $PesterVersionRequired or higher not found. Installing latest Pester..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser -AllowClobber
        Write-Host "Pester installed successfully." -ForegroundColor Green
        $PesterModule = Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    }
    catch {
        Write-Error "Failed to install Pester: $($_.Exception.Message)"
        exit 1
    }
}

# Remove any older versions and import the latest
Remove-Module Pester -Force -ErrorAction SilentlyContinue
Import-Module Pester -RequiredVersion $PesterModule.Version -Force
Write-Host "Using Pester version: $($PesterModule.Version)" -ForegroundColor Green

# Set up paths
$TestsRoot = $PSScriptRoot
$UnitTestsPath = Join-Path $TestsRoot "unit"
$IntegrationTestsPath = Join-Path $TestsRoot "integration"

# Determine which tests to run
$TestPaths = @()
if ($UnitOnly) {
    $TestPaths += $UnitTestsPath
    Write-Host "Running unit tests only..." -ForegroundColor Cyan
}
elseif ($IntegrationOnly) {
    $TestPaths += $IntegrationTestsPath
    Write-Host "Running integration tests only..." -ForegroundColor Cyan
}
else {
    $TestPaths += $UnitTestsPath
    $TestPaths += $IntegrationTestsPath
    Write-Host "Running all tests (unit + integration)..." -ForegroundColor Cyan
}

# Show filter information if applicable
if ($TestName -ne "*") {
    Write-Host "Filtering tests by pattern: $TestName" -ForegroundColor Yellow
}

# Prepare Pester parameters (v5 syntax)
$PesterParams = @{
    Path     = $TestPaths
    PassThru = $true
}

# Run the tests
Write-Host ""
Write-Host "Starting test execution..." -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Add test name filter if specified (Pester v5 uses different approach)
if ($TestName -ne "*") {
    # In Pester v5, we need to use a configuration object
    $PesterConfiguration = [PesterConfiguration]::Default
    $PesterConfiguration.Run.Path = $TestPaths
    $PesterConfiguration.Run.PassThru = $true
    $PesterConfiguration.Filter.FullName = "*$TestName*"
    
    if ($OutputFile) {
        $PesterConfiguration.TestResult.Enabled = $true
        $PesterConfiguration.TestResult.OutputPath = $OutputFile
        $PesterConfiguration.TestResult.OutputFormat = $OutputFormat
        Write-Host "Test results will be saved to: $OutputFile" -ForegroundColor Yellow
    }
    
    $TestResults = Invoke-Pester -Configuration $PesterConfiguration
}
else {
    # Add output file if specified
    if ($OutputFile) {
        $PesterParams.OutputFile = $OutputFile
        $PesterParams.OutputFormat = $OutputFormat
        Write-Host "Test results will be saved to: $OutputFile" -ForegroundColor Yellow
    }
    
    $TestResults = Invoke-Pester @PesterParams
}

# Display summary
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "Test Execution Summary" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "Total Tests: $($TestResults.TotalCount)" -ForegroundColor White
Write-Host "Passed: $($TestResults.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.FailedCount)" -ForegroundColor $(if ($TestResults.FailedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Skipped: $($TestResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Duration: $($TestResults.Duration)" -ForegroundColor White

if ($TestResults.FailedCount -gt 0) {
    Write-Host ""
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($failedTest in $TestResults.TestResult | Where-Object { $_.Result -eq 'Failed' }) {
        Write-Host "  - $($failedTest.Name)" -ForegroundColor Red
        if ($failedTest.FailureMessage) {
            Write-Host "    $($failedTest.FailureMessage)" -ForegroundColor DarkRed
        }
    }
}

# Return results if requested
if ($PassThru) {
    return $TestResults
}

# Set exit code based on test results
if ($TestResults.FailedCount -gt 0) {
    Write-Host ""
    Write-Host "Some tests failed. Exiting with code 1." -ForegroundColor Red
    exit 1
}
else {
    Write-Host ""
    Write-Host "All tests passed successfully!" -ForegroundColor Green
    exit 0
}