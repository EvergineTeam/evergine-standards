#Requires -Modules Pester

Describe "Generate-NuGets-DotNet Multi-Project Test" {
    BeforeAll {
        $scriptPath = "$PSScriptRoot\..\..\scripts\common\Generate-NuGets-DotNet.ps1"
        $helpersPath = "$PSScriptRoot\..\..\scripts\common\Helpers.ps1"
        $fixturesPath = "$PSScriptRoot\..\fixtures"
        
        $script:multiProjectRuntime = Join-Path $fixturesPath "MultiProject.Runtime.csproj"
        $script:multiProjectEditor = Join-Path $fixturesPath "MultiProject.Editor.csproj"
        $script:bindingProject = Join-Path $fixturesPath "BindingProject.csproj"
        
        # Clean previous outputs
        Remove-Item "nupkgs" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Context "Multi-Project Scenarios" {
        It "Should handle multiple projects (add-on style)" {
            & $scriptPath -Version "2.0.0-test" -Projects @($script:multiProjectRuntime, $script:multiProjectEditor) -HelpersPath $helpersPath
            
            # Verify both packages were created
            $packages = Get-ChildItem "nupkgs" -Filter "*.nupkg" | Where-Object { $_.Name -notlike "*.symbols.*" }
            $packages.Count | Should -Be 2
            $packages.Name | Should -Contain "Evergine.Test.MultiProject.Runtime.2.0.0-test.nupkg"
            $packages.Name | Should -Contain "Evergine.Test.MultiProject.Editor.2.0.0-test.nupkg"
        }
        
        It "Should handle binding style versioning with revision" {
            Remove-Item "nupkgs" -Recurse -Force -ErrorAction SilentlyContinue
            
            & $scriptPath -Revision "456" -Projects $script:bindingProject -HelpersPath $helpersPath
            
            # Verify package was created with date-based version
            $packages = Get-ChildItem "nupkgs" -Filter "*.nupkg" | Where-Object { $_.Name -notlike "*.symbols.*" }
            $packages.Count | Should -Be 1
            $packages[0].Name | Should -Match "Evergine.Bindings.TestBinding\.\d{4}\.\d{1,2}\.\d{1,2}\.456\.nupkg"
        }
    }
    
    AfterAll {
        Remove-Item "nupkgs" -Recurse -Force -ErrorAction SilentlyContinue
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