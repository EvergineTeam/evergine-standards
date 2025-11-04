# tests/unit/Helpers.Tests.ps1
# Unit tests for scripts/common/Helpers.ps1

BeforeAll {
    # Load the Helpers script
    $script:HelpersPath = Join-Path $PSScriptRoot "..\..\scripts\common\Helpers.ps1"
    . $script:HelpersPath
    
    # Create a temporary directory for tests
    $script:TestOutputDir = Join-Path $TestDrive "test-output"
}

Describe "LogDebug Function" {
    It "Should execute without errors" {
        { LogDebug "Test message" } | Should -Not -Throw
    }
    
    It "Should handle empty message" {
        { LogDebug "" } | Should -Not -Throw
    }
    
    It "Should handle null message" {
        { LogDebug $null } | Should -Not -Throw
    }
    
    It "Should handle messages with special characters" {
        { LogDebug "Test with special chars: !@#$%^&*()[]{}|" } | Should -Not -Throw
    }
}

Describe "CreateOutputFolder Function" {
    Context "Folder Creation" {
        It "Should create a new folder successfully" {
            $testFolder = Join-Path $TestDrive "new-folder"
            $result = CreateOutputFolder $testFolder
            
            Test-Path $testFolder | Should -Be $true
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should return absolute path" {
            $testFolder = Join-Path $TestDrive "absolute-test"
            $result = CreateOutputFolder $testFolder
            
            [System.IO.Path]::IsPathRooted($result.Path) | Should -Be $true
        }
        
        It "Should handle existing folder without error" {
            $testFolder = Join-Path $TestDrive "existing-folder"
            New-Item -ItemType Directory -Path $testFolder -Force
            
            { $result = CreateOutputFolder $testFolder } | Should -Not -Throw
            Test-Path $testFolder | Should -Be $true
        }
        
        It "Should create nested folders" {
            $testFolder = Join-Path $TestDrive "level1\level2\level3"
            $result = CreateOutputFolder $testFolder
            
            Test-Path $testFolder | Should -Be $true
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle relative paths" {
            Push-Location $TestDrive
            try {
                $result = CreateOutputFolder "relative-folder"
                Test-Path "relative-folder" | Should -Be $true
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
    }
}

Describe "ShowVariables Function" {
    Context "Modern Hashtable Version" {
        It "Should display variables from hashtable without errors" {
            $variables = @{
                "Version"       = "1.0.0"
                "Configuration" = "Release"
                "Verbosity"     = "normal"
            }
            
            { ShowVariables $variables } | Should -Not -Throw
        }
        
        It "Should handle empty hashtable" {
            $variables = @{}
            { ShowVariables $variables } | Should -Not -Throw
        }
        
        It "Should handle null values" {
            $variables = @{
                "Key1" = "Value1"
                "Key2" = $null
                "Key3" = ""
            }
            
            { ShowVariables $variables } | Should -Not -Throw
        }
        
        It "Should handle long key names" {
            $variables = @{
                "VeryLongKeyNameThatExceedsTwentyCharacters" = "Value1"
                "Short"                                      = "Value2"
            }
            
            { ShowVariables $variables } | Should -Not -Throw
        }
        
        It "Should handle various data types" {
            $variables = @{
                "String"  = "test"
                "Number"  = 42
                "Boolean" = $true
                "Array"   = @("item1", "item2")
            }
            
            { ShowVariables $variables } | Should -Not -Throw
        }
    }
}

Describe "ShowVariablesLegacy Function" {
    Context "Legacy Parameter Version" {
        It "Should display variables with legacy parameters without errors" {
            { ShowVariablesLegacy "1.0.0" "Release" "normal" "nupkgs" } | Should -Not -Throw
        }
        
        It "Should handle null parameters" {
            { ShowVariablesLegacy $null $null $null $null } | Should -Not -Throw
        }
        
        It "Should handle empty string parameters" {
            { ShowVariablesLegacy "" "" "" "" } | Should -Not -Throw
        }
        
        It "Should handle mixed parameter types" {
            { ShowVariablesLegacy "1.0.0" 123 $true @("test") } | Should -Not -Throw
        }
    }
}

Describe "Integration Scenarios" {
    Context "Real-world Usage Patterns" {
        It "Should work with typical build script parameters" {
            $buildParams = @{
                "Version"            = "2024.1.1.123"
                "BuildConfiguration" = "Release"
                "BuildVerbosity"     = "minimal"
                "OutputFolder"       = "dist/packages"
                "TargetFramework"    = "net8.0"
            }
            
            { ShowVariables $buildParams } | Should -Not -Throw
            
            $outputPath = CreateOutputFolder (Join-Path $TestDrive "integration-test")
            $outputPath | Should -Not -BeNullOrEmpty
            Test-Path $outputPath | Should -Be $true
        }
        
        It "Should work with NuGet packaging scenario" {
            $nugetParams = @{
                "PackageId"      = "Evergine.Test.Package"
                "Version"        = "1.0.0-preview"
                "Configuration"  = "Debug"
                "IncludeSymbols" = $true
                "OutputPath"     = "nupkgs"
            }
            
            { 
                LogDebug "Starting NuGet packaging process"
                ShowVariables $nugetParams
                $output = CreateOutputFolder (Join-Path $TestDrive $nugetParams.OutputPath)
                LogDebug "Output folder created at: $output"
            } | Should -Not -Throw
        }
        
        It "Should work with binding generation scenario" {
            $bindingParams = @{
                "GeneratorName"     = "TestBinding"
                "GeneratorProject"  = "TestGen.csproj"
                "TargetFramework"   = "net8.0"
                "RuntimeIdentifier" = "win-x64"
            }
            
            { 
                LogDebug "Starting binding generation"
                ShowVariables $bindingParams
                LogDebug "Process completed successfully"
            } | Should -Not -Throw
        }
    }
}

Describe "Error Handling" {
    Context "Edge Cases and Error Conditions" {
        It "Should handle CreateOutputFolder with invalid characters gracefully" {
            # Note: This test might behave differently on different OS
            $invalidPath = Join-Path $TestDrive "test<>folder"
            
            # On Windows, this should throw; on Linux/Mac, it might work
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
                { CreateOutputFolder $invalidPath } | Should -Throw
            }
            else {
                # On non-Windows, test that it either works or throws gracefully
                try {
                    $result = CreateOutputFolder $invalidPath
                    $result | Should -Not -BeNullOrEmpty
                }
                catch {
                    # If it throws, that's also acceptable
                    $true | Should -Be $true
                }
            }
        }
        
        It "Should handle ShowVariables with complex nested objects" {
            $complexParams = @{
                "SimpleValue" = "test"
                "NestedHash"  = @{ "Inner" = "value" }
                "Array"       = @(1, 2, 3)
            }
            
            { ShowVariables $complexParams } | Should -Not -Throw
        }
    }
    
    Context "Version Resolution Functions" {
        Describe "Get-VersionFromRevision" {
            It "Should generate version from revision using current date" {
                $revision = "123"
                $expectedDate = Get-Date -Format "yyyy.M.d"
                $result = Get-VersionFromRevision $revision
                $result | Should -Be "$expectedDate.123"
            }
            
            It "Should throw on null or empty revision" {
                { Get-VersionFromRevision "" } | Should -Throw "*cannot be null or empty*"
                { Get-VersionFromRevision $null } | Should -Throw "*cannot be null or empty*"
            }
        }
        
        Describe "Test-VersionFormat" {
            It "Should validate correct semantic version formats" {
                Test-VersionFormat "1.0.0" | Should -Be $true
                Test-VersionFormat "1.2.3" | Should -Be $true
                Test-VersionFormat "1.0.0-alpha" | Should -Be $true
                Test-VersionFormat "1.0.0-preview" | Should -Be $true
                Test-VersionFormat "1.0.0.123" | Should -Be $true
                Test-VersionFormat "2025.11.3.456" | Should -Be $true
                Test-VersionFormat "1.0.0-alpha.1" | Should -Be $true
            }
            
            It "Should reject invalid version formats" {
                Test-VersionFormat "" | Should -Be $false
                Test-VersionFormat $null | Should -Be $false
                Test-VersionFormat "1" | Should -Be $false
                Test-VersionFormat "1.0" | Should -Be $false
                Test-VersionFormat "1.0.0-" | Should -Be $false
                Test-VersionFormat "1.0.0.0.0" | Should -Be $false
                Test-VersionFormat "v1.0.0" | Should -Be $false
                Test-VersionFormat "1.0.0_alpha" | Should -Be $false
            }
        }
        
        Describe "Resolve-Version" {
            It "Should resolve version from Version parameter" {
                $result = Resolve-Version -version "1.2.3" -revision ""
                $result | Should -Be "1.2.3"
            }
            
            It "Should resolve version from Revision parameter" {
                $expectedDate = Get-Date -Format "yyyy.M.d"
                $result = Resolve-Version -version "" -revision "456"
                $result | Should -Be "$expectedDate.456"
            }
            
            It "Should throw when both Version and Revision are provided" {
                { Resolve-Version -version "1.0.0" -revision "123" } | Should -Throw "*Cannot specify both*"
            }
            
            It "Should throw when neither Version nor Revision are provided" {
                { Resolve-Version -version "" -revision "" } | Should -Throw "*must be provided*"
                { Resolve-Version -version $null -revision $null } | Should -Throw "*must be provided*"
            }
            
            It "Should throw when resolved version has invalid format" {
                { Resolve-Version -version "invalid-version" -revision "" } | Should -Throw "*Invalid version format*"
            }
            
            It "Should validate semantic versioning rules" {
                $result = Resolve-Version -version "2025.1.0.123-preview" -revision ""
                $result | Should -Be "2025.1.0.123-preview"
                
                $expectedDate = Get-Date -Format "yyyy.M.d"
                $result = Resolve-Version -version "" -revision "789"
                $result | Should -Match "^\d{4}\.\d{1,2}\.\d{1,2}\.789$"
            }
        }
    }
}

Describe "Resolve-Version Function - VersionSuffix Support" {
    Context "Version with suffix" {
        It "Should append suffix with dash to version" {
            $result = Resolve-Version -version "1.0.0" -versionSuffix "nightly"
            $result | Should -Be "1.0.0-nightly"
        }
        
        It "Should handle suffix with leading dash" {
            $result = Resolve-Version -version "1.0.0" -versionSuffix "-nightly"
            $result | Should -Be "1.0.0-nightly"
        }
        
        It "Should handle multiple dash separators in suffix" {
            $result = Resolve-Version -version "1.0.0" -versionSuffix "alpha-1"
            $result | Should -Be "1.0.0-alpha-1"
        }
        
        It "Should handle complex pre-release suffix" {
            $result = Resolve-Version -version "2.1.3" -versionSuffix "beta.2"
            $result | Should -Be "2.1.3-beta.2"
        }
        
        It "Should work with four-part version" {
            $result = Resolve-Version -version "1.0.0.123" -versionSuffix "nightly"
            $result | Should -Be "1.0.0.123-nightly"
        }
    }
    
    Context "Revision with suffix" {
        It "Should apply suffix to calculated version from revision" {
            $result = Resolve-Version -revision "123" -versionSuffix "nightly"
            $expectedPattern = "^\d{4}\.\d{1,2}\.\d{1,2}\.123-nightly$"
            $result | Should -Match $expectedPattern
        }
        
        It "Should handle revision with leading dash suffix" {
            $result = Resolve-Version -revision "456" -versionSuffix "-beta"
            $expectedPattern = "^\d{4}\.\d{1,2}\.\d{1,2}\.456-beta$"
            $result | Should -Match $expectedPattern
        }
    }
    
    Context "Empty or null suffix" {
        It "Should work with empty string suffix" {
            $result = Resolve-Version -version "1.0.0" -versionSuffix ""
            $result | Should -Be "1.0.0"
        }
        
        It "Should work with null suffix" {
            $result = Resolve-Version -version "1.0.0" -versionSuffix $null
            $result | Should -Be "1.0.0"
        }
        
        It "Should work with whitespace-only suffix" {
            $result = Resolve-Version -version "1.0.0" -versionSuffix "   "
            $result | Should -Be "1.0.0"
        }
    }
    
    Context "Suffix validation" {
        It "Should preserve valid NuGet pre-release identifiers" {
            $result = Resolve-Version -version "1.0.0" -versionSuffix "alpha1"
            $result | Should -Be "1.0.0-alpha1"
        }
        
        It "Should work with numeric suffix" {
            $result = Resolve-Version -version "1.0.0" -versionSuffix "20241103"
            $result | Should -Be "1.0.0-20241103"
        }
        
        It "Should handle mixed alphanumeric suffix" {
            $result = Resolve-Version -version "1.0.0" -versionSuffix "rc1-build123"
            $result | Should -Be "1.0.0-rc1-build123"
        }
    }
}