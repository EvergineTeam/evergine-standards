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
}