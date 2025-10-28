#Requires -Modules Pester

Describe "Generate-NuGets-DotNet Version Validation Tests" {
    BeforeAll {
        $scriptPath = "$PSScriptRoot\..\..\scripts\common\Generate-NuGets-DotNet.ps1"
        $helpersPath = "$PSScriptRoot\..\..\scripts\common\Helpers.ps1"
        $fixturesPath = "$PSScriptRoot\..\fixtures"
        $singleProject = Join-Path $fixturesPath "SingleProject.csproj"
    }
	
    Context "Valid Version Formats" {
        It "Should accept basic semantic version" {
            { & $scriptPath -Version "1.0.0" -Projects $singleProject -HelpersPath $helpersPath } | Should -Not -Throw
        }
		
        It "Should accept four-part version" {
            { & $scriptPath -Version "1.0.0.123" -Projects $singleProject -HelpersPath $helpersPath } | Should -Not -Throw
        }
		
        It "Should accept pre-release version" {
            { & $scriptPath -Version "1.0.0-alpha" -Projects $singleProject -HelpersPath $helpersPath } | Should -Not -Throw
        }
		
        It "Should accept pre-release with dots" {
            { & $scriptPath -Version "1.0.0-alpha.1" -Projects $singleProject -HelpersPath $helpersPath } | Should -Not -Throw
        }
		
        It "Should accept pre-release with numbers" {
            { & $scriptPath -Version "1.0.0-beta1" -Projects $singleProject -HelpersPath $helpersPath } | Should -Not -Throw
        }
		
        It "Should accept complex pre-release" {
            { & $scriptPath -Version "1.0.0-rc.1.2" -Projects $singleProject -HelpersPath $helpersPath } | Should -Not -Throw
        }
		
        It "Should accept calculated version from revision" {
            { & $scriptPath -Revision "123" -Projects $singleProject -HelpersPath $helpersPath } | Should -Not -Throw
        }
    }
	
    Context "Invalid Version Formats" {
        It "Should reject version starting with letter" {
            { & $scriptPath -Version "v1.0.0" -Projects $singleProject -HelpersPath $helpersPath } | Should -Throw "*Invalid version format*"
        }
		
        It "Should reject version with invalid prefix" {
            { & $scriptPath -Version "TEST-1.0.0" -Projects $singleProject -HelpersPath $helpersPath } | Should -Throw "*Invalid version format*"
        }
		
        It "Should reject version with spaces" {
            { & $scriptPath -Version "1.0.0 alpha" -Projects $singleProject -HelpersPath $helpersPath } | Should -Throw "*Invalid version format*"
        }
		
        It "Should reject version with special characters" {
            { & $scriptPath -Version "1.0.0@test" -Projects $singleProject -HelpersPath $helpersPath } | Should -Throw "*Invalid version format*"
        }
		
        It "Should reject incomplete version" {
            { & $scriptPath -Version "1.0" -Projects $singleProject -HelpersPath $helpersPath } | Should -Throw "*Invalid version format*"
        }
		
        It "Should reject empty version" {
            { & $scriptPath -Version "" -Projects $singleProject -HelpersPath $helpersPath } | Should -Throw "*Either -Version or -Revision parameter must be provided*"
        }
		
        It "Should reject version with leading zeros" {
            { & $scriptPath -Version "01.0.0" -Projects $singleProject -HelpersPath $helpersPath } | Should -Throw "*Invalid version format*"
        }
    }
	
    Context "Version Error Messages" {
        It "Should provide helpful error message with invalid version" {
            try {
                & $scriptPath -Version "INVALID-VERSION" -Projects $singleProject -HelpersPath $helpersPath
            }
            catch {
                $_.Exception.Message | Should -Match "Invalid version format: 'INVALID-VERSION'"
                $_.Exception.Message | Should -Match "semantic versioning"
                $_.Exception.Message | Should -Match "1\.0\.0"
            }
        }
		
        It "Should show examples in error message" {
            try {
                & $scriptPath -Version "bad.version" -Projects $singleProject -HelpersPath $helpersPath
            }
            catch {
                $_.Exception.Message | Should -Match "1\.0\.0-alpha"
                $_.Exception.Message | Should -Match "1\.0\.0\.123"
            }
        }
    }
	
    AfterEach {
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