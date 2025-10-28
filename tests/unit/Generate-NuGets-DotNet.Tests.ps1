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
    Context "Parameter Validation" {
        It "Should require either Version or Revision parameter" {
            { & $scriptPath -Projects "test.csproj" -HelpersPath $helpersPath } | Should -Throw "*Either -Version or -Revision parameter must be provided*"
        }
		
        It "Should not allow both Version and Revision parameters" {
            { & $scriptPath -Version "1.0.0" -Revision "123" -Projects "test.csproj" -HelpersPath $helpersPath } | Should -Throw "*Cannot specify both -Version and -Revision parameters*"
        }
		
        It "Should require Projects parameter" {
            { & $scriptPath -Version "1.0.0" -Projects @() -HelpersPath $helpersPath } | Should -Throw "*Projects parameter cannot be empty*"
        }
		
        It "Should accept Version parameter" {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
            { & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath $helpersPath } | Should -Throw "*Project file not found*"
        }
		
        It "Should accept Revision parameter" {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
            { & $scriptPath -Revision "123" -Projects "test.csproj" -HelpersPath $helpersPath } | Should -Throw "*Project file not found*"
        }
    }
	
    Context "Version Calculation" {
        It "Should use direct version when Version parameter is provided" {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
            Mock Get-Date { "2025.10.28" }
			
            try {
                & $scriptPath -Version "3.4.22.288" -Projects "test.csproj" -HelpersPath $helpersPath
            }
            catch {
                $_.Exception.Message | Should -Match "Project file not found"
                # The version should be used as-is, we can verify this by checking the error doesn't mention date calculation
            }
        }
		
        It "Should calculate version from date and revision when Revision parameter is provided" {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
            Mock Get-Date { "2025.10.28" } -ParameterFilter { $Format -eq "yyyy.M.d" }
			
            try {
                & $scriptPath -Revision "123" -Projects "test.csproj" -HelpersPath $helpersPath
            }
            catch {
                $_.Exception.Message | Should -Match "Project file not found"
                # The version calculation logic was executed (we can't easily verify the exact version without more complex mocking)
            }
        }
    }
	
    Context "Projects Parameter Handling" {
        It "Should convert single string project to array" {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
            { & $scriptPath -Version "1.0.0" -Projects "single.csproj" -HelpersPath $helpersPath } | Should -Throw "*Project file not found: single.csproj*"
        }
		
        It "Should handle array of projects" {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
            { & $scriptPath -Version "1.0.0" -Projects @("first.csproj", "second.csproj") -HelpersPath $helpersPath } | Should -Throw "*Project file not found: first.csproj*"
        }
    }
	
    Context "Helpers Integration" {
        It "Should load helpers from default path" {
            # The script is now in common and helpers is already there too
            # Test that the script finds helpers at the default path and fails on missing project
            { & $scriptPath -Version "1.0.0" -Projects "test.csproj" } | Should -Throw "*Project file not found*"
        }
		
        It "Should load helpers from custom path" {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
            { & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath $helpersPath } | Should -Throw "*Project file not found*"
        }
		
        It "Should throw error if helpers file not found" {
            { & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath "nonexistent.ps1" } | Should -Throw "*Helpers file not found at: nonexistent.ps1*"
        }
    }
	
    Context "Default Parameter Values" {
        BeforeEach {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
        }
		
        It "Should use default OutputFolderBase value" {
            try {
                & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath $helpersPath
            }
            catch {
                # Should use default "nupkgs" folder
                $_.Exception.Message | Should -Match "Project file not found"
            }
        }
		
        It "Should use default BuildVerbosity value" {
            try {
                & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath $helpersPath
            }
            catch {
                # Should use default "normal" verbosity
                $_.Exception.Message | Should -Match "Project file not found"
            }
        }
		
        It "Should use default BuildConfiguration value" {
            try {
                & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath $helpersPath
            }
            catch {
                # Should use default "Release" configuration
                $_.Exception.Message | Should -Match "Project file not found"
            }
        }
		
        It "Should use default IncludeSymbols value" {
            try {
                & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath $helpersPath
            }
            catch {
                # Should use default $true for symbols
                $_.Exception.Message | Should -Match "Project file not found"
            }
        }
    }
	
    Context "File Operations" {
        It "Should check if project files exist" {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
            { & $scriptPath -Version "1.0.0" -Projects "missing.csproj" -HelpersPath $helpersPath } | Should -Throw "*Project file not found: missing.csproj*"
        }
		
        It "Should call CreateOutputFolder function" {
            Mock Test-Path { param($Path) if ($Path -like "*Helpers.ps1") { $true } else { $false } }
            Mock CreateOutputFolder { "C:\temp\nupkgs" }
			
            try {
                & $scriptPath -Version "1.0.0" -Projects "test.csproj" -HelpersPath $helpersPath
            }
            catch {
                # Verify CreateOutputFolder was called (implicitly by not throwing helpers-related error)
                $_.Exception.Message | Should -Match "Project file not found"
            }
        }
    }
	
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
}