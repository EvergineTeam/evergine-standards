#Requires -Modules Pester

BeforeAll {
    # Import the script to test
    $scriptPath = "$PSScriptRoot\..\..\scripts\common\Generate-NuGets-DotNet.ps1"
    $helpersPath = Resolve-Path "$PSScriptRoot\..\..\scripts\common\Helpers.ps1"
    $fixturesPath = Resolve-Path "$PSScriptRoot\..\fixtures"
	
    # Load helpers first
    . $helpersPath
	
    # Define fixture project paths
    $script:singleProject = Join-Path $fixturesPath "SingleProject.csproj"
    $script:bindingProject = Join-Path $fixturesPath "BindingProject.csproj"
    $script:multiProjectRuntime = Join-Path $fixturesPath "MultiProject.Runtime.csproj"
    $script:multiProjectEditor = Join-Path $fixturesPath "MultiProject.Editor.csproj"
}

Describe "Generate-NuGets-DotNet Script Tests" {
	
    Context "Build Process Simulation" {
        BeforeEach {
            # Clean up any previous test outputs
            Remove-Item "nupkgs" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        AfterEach {
            Remove-Item "nupkgs" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Should process existing project file and attempt dotnet pack" {
            Mock CreateOutputFolder { "nupkgs" }
            
            # Use fixture project - this should succeed since our fixture projects are valid
            & $scriptPath -Version "1.0.0-test" -Projects $script:singleProject -HelpersPath $helpersPath
            
            # Verify output folder was created
            Test-Path "nupkgs" | Should -Be $true
        }
        
        It "Should process multiple project files" {
            Mock CreateOutputFolder { "nupkgs" }
            
            # Use multiple fixture projects
            & $scriptPath -Version "1.0.0-test" -Projects @($script:multiProjectRuntime, $script:multiProjectEditor) -HelpersPath $helpersPath
            
            # Verify output folder was created
            Test-Path "nupkgs" | Should -Be $true
        }
        
        It "Should handle binding project scenario" {
            Mock CreateOutputFolder { "nupkgs" }
            
            # Use revision for binding-style versioning
            & $scriptPath -Revision "123" -Projects $script:bindingProject -HelpersPath $helpersPath
            
            # Verify output folder was created
            Test-Path "nupkgs" | Should -Be $true
        }
    }
}
	
Context "Integration with Helpers Functions" {
    It "Should call LogDebug function" {
        Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
        Mock LogDebug { }
			
        try {
            & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath $helpersPath
        }
        catch {
            # LogDebug should have been called for various messages
        }
        
        Should -Invoke LogDebug -Times 10
    }
		
    It "Should call ShowVariables function" {
        Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
        Mock ShowVariables { }
			
        try {
            & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath $helpersPath
        }
        catch {
            # ShowVariables should have been called
        }
        
        Should -Invoke ShowVariables -Exactly 1
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
    
    Context "VersionSuffix Parameter Tests" {
        BeforeEach {
            # Mock dotnet command to avoid actual builds
            Mock -CommandName "dotnet" -MockWith {
                param($ArgumentList)
                Write-Host "Mocked dotnet called with: $ArgumentList"
                return $true
            }
        }
        
        It "Should accept VersionSuffix parameter" {
            # Test with a simple version and suffix
            { & $scriptPath -ProjectPath $script:singleProject -Version "1.0.0" -VersionSuffix "nightly" -BuildConfiguration "Release" -BuildVerbosity "minimal" -OutputFolderBase "nupkgs" } | Should -Not -Throw
        }
        
        It "Should process VersionSuffix with revision" {
            # Test with revision and suffix
            { & $scriptPath -ProjectPath $script:singleProject -Revision "123" -VersionSuffix "beta" -BuildConfiguration "Release" -BuildVerbosity "minimal" -OutputFolderBase "nupkgs" } | Should -Not -Throw
        }
        
        It "Should handle VersionSuffix with leading dash" {
            # Test that leading dash is handled correctly
            { & $scriptPath -ProjectPath $script:singleProject -Version "1.0.0" -VersionSuffix "-alpha" -BuildConfiguration "Release" -BuildVerbosity "minimal" -OutputFolderBase "nupkgs" } | Should -Not -Throw
        }
        
        It "Should work without VersionSuffix" {
            # Test that the script still works when suffix is not provided
            { & $scriptPath -ProjectPath $script:singleProject -Version "1.0.0" -BuildConfiguration "Release" -BuildVerbosity "minimal" -OutputFolderBase "nupkgs" } | Should -Not -Throw
        }
        
        It "Should pass VersionSuffix to dotnet pack command" {
            # Execute script with version suffix
            & $scriptPath -ProjectPath $script:singleProject -Version "1.0.0" -VersionSuffix "nightly" -BuildConfiguration "Release" -BuildVerbosity "minimal" -OutputFolderBase "nupkgs"
            
            # Verify dotnet was called with version suffix
            Should -Invoke dotnet -ParameterFilter {
                $ArgumentList -contains "/p:PackageVersion=1.0.0-nightly"
            }
        }
        
        It "Should handle complex VersionSuffix values" {
            # Test with complex suffix
            { & $scriptPath -ProjectPath $script:singleProject -Version "2.1.0" -VersionSuffix "rc1-build123" -BuildConfiguration "Release" -BuildVerbosity "minimal" -OutputFolderBase "nupkgs" } | Should -Not -Throw
        }
        
        AfterEach {
            try {
                Remove-Item "nupkgs" -Recurse -Force -ErrorAction SilentlyContinue
            }
            catch {
                # Silently ignore cleanup errors in tests
            }
        }
    }
}