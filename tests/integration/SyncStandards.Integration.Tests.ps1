# tests/integration/SyncStandards.Simple.Integration.Tests.ps1
# Simple integration tests for sync-standards.ps1 script compatible with Pester v3

Describe "Sync Standards Simple Integration Tests" {
    
    It "Should execute sync script with dry-run successfully" {
        $ScriptPath = Join-Path $PSScriptRoot "..\..\tools\sync-standards.ps1"
        $MockRepoPath = Join-Path $PSScriptRoot "..\fixtures\mock-repo"
        $TestWorkspace = Join-Path ([System.IO.Path]::GetTempPath()) "sync-test-$(Get-Random)"
        
        try {
            New-Item -ItemType Directory -Path $TestWorkspace -Force | Out-Null
            
            # Run with dry-run to avoid making changes
            $ErrorBefore = $Error.Count
            & $ScriptPath -SourcePath $MockRepoPath -Root $TestWorkspace -Manifest "sync-manifest.json" -DryRun
            $ErrorAfter = $Error.Count
            
            # Should not generate new errors (indicating successful execution)
            ($ErrorAfter - $ErrorBefore) | Should -Eq 0
            
        } finally {
            if (Test-Path $TestWorkspace) {
                Remove-Item -Path $TestWorkspace -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    It "Should create test workspace successfully" {
        $TestWorkspace = Join-Path ([System.IO.Path]::GetTempPath()) "workspace-test-$(Get-Random)"
        
        try {
            New-Item -ItemType Directory -Path $TestWorkspace -Force | Out-Null
            Test-Path $TestWorkspace | Should -Eq $true
            
        } finally {
            if (Test-Path $TestWorkspace) {
                Remove-Item -Path $TestWorkspace -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    It "Should read mock manifest file" {
        $ManifestPath = Join-Path $PSScriptRoot "..\fixtures\mock-repo\sync-manifest.json"
        
        Test-Path $ManifestPath | Should -Eq $true
        
        $Content = Get-Content $ManifestPath -Raw
        $Manifest = $Content | ConvertFrom-Json
        
        $Manifest.schema | Should -Eq "1"
        $Manifest.files.Count | Should -Eq 3
    }
    
    It "Should verify fixtures exist" {
        $FixturesPath = Join-Path $PSScriptRoot "..\fixtures"
        $MockRepoPath = Join-Path $FixturesPath "mock-repo"
        
        Test-Path $MockRepoPath | Should -Eq $true
        Test-Path (Join-Path $MockRepoPath "LICENSE") | Should -Eq $true
        Test-Path (Join-Path $MockRepoPath "README.md") | Should -Eq $true
        Test-Path (Join-Path $MockRepoPath "sync-manifest.json") | Should -Eq $true
    }
}