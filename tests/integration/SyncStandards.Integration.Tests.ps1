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
            
        }
        finally {
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
            
        }
        finally {
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
        
        $Manifest.schema | Should -Eq "2"
        $Manifest.defaultGroups.Count | Should -Eq 1
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

Describe "Schema v2 Groups Integration Tests" {
    
    It "Should execute script with schema v2 manifest successfully" {
        $ScriptPath = Join-Path $PSScriptRoot "..\..\tools\sync-standards.ps1"
        $MockRepoPath = Join-Path $PSScriptRoot "..\fixtures\mock-repo"
        $TestWorkspace = Join-Path ([System.IO.Path]::GetTempPath()) "sync-v2-test-$(Get-Random)"
        $ManifestPath = Join-Path $PSScriptRoot "..\fixtures\manifest-basic.json"
        
        try {
            New-Item -ItemType Directory -Path $TestWorkspace -Force | Out-Null
            
            # Copy schema v2 manifest to mock repo temporarily
            $MockManifestPath = Join-Path $MockRepoPath "sync-manifest.json"
            $OriginalManifest = Get-Content $MockManifestPath -Raw
            Copy-Item $ManifestPath $MockManifestPath -Force
            
            # Run with dry-run to test schema v2 processing
            $ErrorBefore = $Error.Count
            & $ScriptPath -SourcePath $MockRepoPath -Root $TestWorkspace -Manifest "sync-manifest.json" -DryRun
            $ErrorAfter = $Error.Count
            
            # Should not generate new errors
            ($ErrorAfter - $ErrorBefore) | Should -Eq 0
            
        }
        finally {
            # Restore original manifest
            if ($OriginalManifest) {
                Set-Content -Path $MockManifestPath -Value $OriginalManifest -NoNewline
            }
            if (Test-Path $TestWorkspace) {
                Remove-Item -Path $TestWorkspace -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    It "Should execute script with schema v2 override file successfully" {
        $ScriptPath = Join-Path $PSScriptRoot "..\..\tools\sync-standards.ps1"
        $MockRepoPath = Join-Path $PSScriptRoot "..\fixtures\mock-repo"
        $TestWorkspace = Join-Path ([System.IO.Path]::GetTempPath()) "sync-v2-override-test-$(Get-Random)"
        $ManifestPath = Join-Path $PSScriptRoot "..\fixtures\manifest-with-overwrite.json"
        $OverridePath = Join-Path $PSScriptRoot "..\fixtures\override-groups-only.json"
        
        try {
            New-Item -ItemType Directory -Path $TestWorkspace -Force | Out-Null
            
            # Copy schema v2 manifest to mock repo temporarily
            $MockManifestPath = Join-Path $MockRepoPath "sync-manifest.json"
            $OriginalManifest = Get-Content $MockManifestPath -Raw
            Copy-Item $ManifestPath $MockManifestPath -Force
            
            # Copy override file to test workspace
            $TestOverridePath = Join-Path $TestWorkspace ".standards.override.json"
            Copy-Item $OverridePath $TestOverridePath -Force
            
            # Run with dry-run to test schema v2 with group selection
            $ErrorBefore = $Error.Count
            & $ScriptPath -SourcePath $MockRepoPath -Root $TestWorkspace -Manifest "sync-manifest.json" -DryRun
            $ErrorAfter = $Error.Count
            
            # Should not generate new errors
            ($ErrorAfter - $ErrorBefore) | Should -Eq 0
            
        }
        finally {
            # Restore original manifest
            if ($OriginalManifest) {
                Set-Content -Path $MockManifestPath -Value $OriginalManifest -NoNewline
            }
            if (Test-Path $TestWorkspace) {
                Remove-Item -Path $TestWorkspace -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    It "Should read schema v2 manifest files correctly" {
        $ManifestV2Path = Join-Path $PSScriptRoot "..\fixtures\manifest-basic.json"
        
        Test-Path $ManifestV2Path | Should -Eq $true
        
        $Content = Get-Content $ManifestV2Path -Raw
        $Manifest = $Content | ConvertFrom-Json
        
        $Manifest.schema | Should -Eq "2"
        $Manifest.defaultGroups.Count | Should -Eq 1
        $Manifest.defaultGroups[0] | Should -Eq "core"
        $Manifest.groups.core.Count | Should -Eq 3
        $Manifest.groups.docs.Count | Should -Eq 2
    }
    
    It "Should use defaultGroups when override file exists without groups property" {
        $ScriptPath = Join-Path $PSScriptRoot "..\..\tools\sync-standards.ps1"
        $MockRepoPath = Join-Path $PSScriptRoot "..\fixtures\mock-repo"
        $TestWorkspace = Join-Path ([System.IO.Path]::GetTempPath()) "sync-no-groups-test-$(Get-Random)"
        $ManifestPath = Join-Path $PSScriptRoot "..\fixtures\manifest-basic.json"
        $OverridePath = Join-Path $PSScriptRoot "..\fixtures\override-without-groups.json"
        
        try {
            New-Item -ItemType Directory -Path $TestWorkspace -Force | Out-Null
            
            # Copy manifest to mock repo temporarily
            $MockManifestPath = Join-Path $MockRepoPath "sync-manifest.json"
            $OriginalManifest = Get-Content $MockManifestPath -Raw
            Copy-Item $ManifestPath $MockManifestPath -Force
            
            # Copy override file WITHOUT groups to test workspace
            $TestOverridePath = Join-Path $TestWorkspace ".standards.override.json"
            Copy-Item $OverridePath $TestOverridePath -Force
            
            # Run with dry-run to test defaultGroups fallback
            $ErrorBefore = $Error.Count
            & $ScriptPath -SourcePath $MockRepoPath -Root $TestWorkspace -Manifest "sync-manifest.json" -DryRun
            $ErrorAfter = $Error.Count
            
            # Should not generate new errors
            ($ErrorAfter - $ErrorBefore) | Should -Eq 0
            
        }
        finally {
            # Restore original manifest
            if ($OriginalManifest) {
                Set-Content -Path $MockManifestPath -Value $OriginalManifest -NoNewline
            }
            if (Test-Path $TestWorkspace) {
                Remove-Item -Path $TestWorkspace -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}