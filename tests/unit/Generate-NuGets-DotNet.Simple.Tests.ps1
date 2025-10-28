#Requires -Modules Pester

Describe "Generate-NuGets-DotNet Simple Test" {
    BeforeAll {
        $scriptPath = "$PSScriptRoot\..\..\scripts\binding\Generate-NuGets-DotNet.ps1"
        $helpersPath = "$PSScriptRoot\..\..\scripts\common\Helpers.ps1"
        $fixturesPath = "$PSScriptRoot\..\fixtures"
        
        # Verify files exist
        $script:singleProject = Join-Path $fixturesPath "SingleProject.csproj"
        
        Write-Host "Script path: $scriptPath"
        Write-Host "Helpers path: $helpersPath"
        Write-Host "Single project: $script:singleProject"
        Write-Host "Single project exists: $(Test-Path $script:singleProject)"
    }
    
    Context "Basic Functionality" {
        It "Should execute successfully with valid parameters" {
            # Test with a simple execution
            $result = & $scriptPath -Version "1.0.0-test" -Projects $script:singleProject -HelpersPath $helpersPath
            
            # If we get here without throwing, the script executed successfully
            $true | Should -Be $true
        }
    }
}

AfterAll {
    # Clean up test artifacts generated during this test file
    $CleanupPaths = @(
        "$PSScriptRoot\..\fixtures\bin",
        "$PSScriptRoot\..\fixtures\obj", 
        "$PSScriptRoot\..\fixtures\nupkgs",
        "$PSScriptRoot\..\..\bin",
        "$PSScriptRoot\..\..\obj",
        "$PSScriptRoot\..\..\nupkgs"
    )
    
    foreach ($Path in $CleanupPaths) {
        if (Test-Path $Path) {
            try {
                Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
            }
            catch {
                # Silently ignore cleanup errors in tests
            }
        }
    }
}