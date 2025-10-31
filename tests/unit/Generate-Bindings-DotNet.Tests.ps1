# tests/unit/Generate-Bindings-DotNet.Tests.ps1
# Unit tests for Generate-Bindings-DotNet.ps1 script

BeforeAll {
    # Dot source the script to load its functions (solo funciones, sin lógica principal)
    $script:BindingScriptPath = Join-Path $PSScriptRoot "..\..\scripts\binding\Generate-Bindings-DotNet.ps1"
    . $script:BindingScriptPath -TestMode
}

Describe "Parameter Validation" {
    Context "Required Parameters" {
        It "Should exit with code 1 when GeneratorProject is empty" {
            $result = & pwsh -Command "& '$script:BindingScriptPath' -GeneratorProject '' -GeneratorName 'Test' 2>&1; exit `$LASTEXITCODE"
            $LASTEXITCODE | Should -Be 1
        }
        
        It "Should exit with code 1 when GeneratorName is empty" {
            $result = & pwsh -Command "& '$script:BindingScriptPath' -GeneratorProject 'Test.csproj' -GeneratorName '' 2>&1; exit `$LASTEXITCODE"
            $LASTEXITCODE | Should -Be 1
        }
        
        It "Should validate parameters contain required values" {
            # Test the validation logic directly
            $emptyProject = ""
            $emptyName = ""
            
            [string]::IsNullOrWhiteSpace($emptyProject) | Should -Be $true
            [string]::IsNullOrWhiteSpace($emptyName) | Should -Be $true
        }
    }
}

Describe "Path Construction Logic" {
    Context "With RuntimeIdentifier" {
        It "Should construct correct path with RuntimeIdentifier (script function)" {
            $generatorDir = "C:\TestProject"
            $buildConfiguration = "Release"
            $targetFramework = "net8.0"
            $runtimeIdentifier = "win-x64"
            $expectedPath = "$generatorDir\bin\$buildConfiguration\$targetFramework\$runtimeIdentifier"
            $actualPath = Get-BuildOutputPath $generatorDir $buildConfiguration $targetFramework $runtimeIdentifier
            $actualPath | Should -Be $expectedPath
        }
    }
    Context "Without RuntimeIdentifier" {
        It "Should construct correct path without RuntimeIdentifier (script function)" {
            $generatorDir = "C:\TestProject"
            $buildConfiguration = "Release"
            $targetFramework = "net8.0"
            $runtimeIdentifier = ""
            $expectedPath = "$generatorDir\bin\$buildConfiguration\$targetFramework"
            $actualPath = Get-BuildOutputPath $generatorDir $buildConfiguration $targetFramework $runtimeIdentifier
            $actualPath | Should -Be $expectedPath
        }
        It "Should handle null RuntimeIdentifier (script function)" {
            $generatorDir = "C:\TestProject"
            $buildConfiguration = "Release"
            $targetFramework = "net8.0"
            $runtimeIdentifier = $null
            $expectedPath = "$generatorDir\bin\$buildConfiguration\$targetFramework"
            $actualPath = Get-BuildOutputPath $generatorDir $buildConfiguration $targetFramework $runtimeIdentifier
            $actualPath | Should -Be $expectedPath
        }
    }
    Context "Different Target Frameworks" {
        It "Should handle different target frameworks (script function)" {
            $generatorDir = "C:\TestProject"
            $buildConfiguration = "Debug"
            $targetFramework = "net9.0"
            $runtimeIdentifier = "linux-x64"
            $expectedPath = "$generatorDir\bin\$buildConfiguration\$targetFramework\$runtimeIdentifier"
            $actualPath = Get-BuildOutputPath $generatorDir $buildConfiguration $targetFramework $runtimeIdentifier
            $actualPath | Should -Be $expectedPath
        }
    }
}

Describe "Project Name Extraction" {
    It "Should extract correct project name from csproj path (script function)" {
        $projectPath = "TestGen\TestGen\TestGen.csproj"
        $expectedName = "TestGen"
        $actualName = Get-ProjectNameFromPath $projectPath
        $actualName | Should -Be $expectedName
    }
    It "Should handle complex project paths (script function)" {
        $projectPath = "C:\Projects\MyLibraryGenerator\src\MyLibraryGenerator.csproj"
        $expectedName = "MyLibraryGenerator"
        $actualName = Get-ProjectNameFromPath $projectPath
        $actualName | Should -Be $expectedName
    }
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
}

Describe "Integration Scenarios" {
    Context "Real-world Parameter Combinations" {
        It "Should work with sample binding parameters (script function)" {
            $params = @{
                GeneratorProject   = "SampleGen\SampleGen\SampleGen.csproj"
                GeneratorName      = "SampleBinding"
                BuildConfiguration = "Release"
                TargetFramework    = "net8.0"
                RuntimeIdentifier  = "win-x64"
            }
            $result = Test-BindingParameters -params $params
            $result | Should -Be $true
        }
        It "Should work with OpenGL-like parameters (no RuntimeIdentifier, script function)" {
            $params = @{
                GeneratorProject   = "OpenGLGen\OpenGLGen\OpenGLGen.csproj"
                GeneratorName      = "OpenGL"
                BuildConfiguration = "Release"
                TargetFramework    = "net8.0"
                RuntimeIdentifier  = ""
            }
            $result = Test-BindingParameters -params $params
            $result | Should -Be $true
        }
        It "Should work with future .NET version (script function)" {
            $params = @{
                GeneratorProject   = "FutureGen\FutureGen\FutureGen.csproj"
                GeneratorName      = "Future"
                BuildConfiguration = "Release"
                TargetFramework    = "net10.0"
                RuntimeIdentifier  = "win-arm64"
            }
            $result = Test-BindingParameters -params $params
            $result | Should -Be $true
            $params.TargetFramework | Should -Match "net\d+\.\d+"
        }
    }
}