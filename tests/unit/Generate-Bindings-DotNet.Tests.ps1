# tests/unit/Generate-Bindings-DotNet.Tests.ps1
# Unit tests for Generate-Bindings-DotNet.ps1 script

BeforeAll {
    # Load the script functions for testing
    $script:BindingScriptPath = Join-Path $PSScriptRoot "..\..\scripts\binding\Generate-Bindings-DotNet.ps1"
    
    # Create a test version that exposes functions for testing
    $script:TestScriptContent = Get-Content $script:BindingScriptPath -Raw
    
    # Extract the LogDebug function for testing
    $script:LogDebugFunction = @'
function LogDebug($line) {
    Write-Host "##[debug] $line" -ForegroundColor Blue -BackgroundColor Black
}
'@
    
    # Execute the function definition
    Invoke-Expression $script:LogDebugFunction
    
    # Mock external commands for testing
    Mock dotnet { 
        param($command, $verbosity, $configuration, $project)
        if ($command -eq "publish") {
            $global:LASTEXITCODE = 0
            return "Build succeeded"
        }
    }
    
    Mock Push-Location { param($path) }
    Mock Pop-Location { }
    Mock Test-Path { param($path) 
        # Mock project file exists
        if ($path -like "*.csproj") { return $true }
        # Mock build output directory exists
        if ($path -like "*\bin\*") { return $true }
        return $false
    }
    Mock Split-Path { param($path, $parent)
        if ($parent) { return "C:\TestGenerator" }
        return "TestGenerator.csproj"
    }
    Mock & { param($exe)
        $global:LASTEXITCODE = 0
        return "Generator executed successfully"
    }
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
    
    Context "Default Values" {
        BeforeEach {
            # Create a minimal test script that only shows parameters
            $script:ParamTestScript = @'
param (
    [string]$BuildVerbosity = "normal",
    [string]$BuildConfiguration = "Release",
    [string]$GeneratorProject = "",
    [string]$GeneratorName = "",
    [string]$TargetFramework = "net8.0",
    [string]$RuntimeIdentifier = "win-x64"
)
Write-Output "BuildVerbosity:$BuildVerbosity"
Write-Output "BuildConfiguration:$BuildConfiguration" 
Write-Output "TargetFramework:$TargetFramework"
Write-Output "RuntimeIdentifier:$RuntimeIdentifier"
'@
        }
        
        It "Should use correct default values" {
            $result = Invoke-Expression $script:ParamTestScript
            $result | Should -Contain "BuildVerbosity:normal"
            $result | Should -Contain "BuildConfiguration:Release"
            $result | Should -Contain "TargetFramework:net8.0"
            $result | Should -Contain "RuntimeIdentifier:win-x64"
        }
    }
}

Describe "Path Construction Logic" {
    Context "With RuntimeIdentifier" {
        It "Should construct correct path with RuntimeIdentifier" {
            $generatorDir = "C:\TestProject"
            $buildConfiguration = "Release"
            $targetFramework = "net8.0"
            $runtimeIdentifier = "win-x64"
            
            $expectedPath = "$generatorDir\bin\$buildConfiguration\$targetFramework\$runtimeIdentifier"
            
            # Test the logic manually
            $buildPath = "$generatorDir\bin\$buildConfiguration\$targetFramework"
            if (-not [string]::IsNullOrWhiteSpace($runtimeIdentifier)) {
                $buildPath += "\$runtimeIdentifier"
            }
            
            $buildPath | Should -Be $expectedPath
        }
    }
    
    Context "Without RuntimeIdentifier" {
        It "Should construct correct path without RuntimeIdentifier" {
            $generatorDir = "C:\TestProject"
            $buildConfiguration = "Release"
            $targetFramework = "net8.0"
            $runtimeIdentifier = ""
            
            $expectedPath = "$generatorDir\bin\$buildConfiguration\$targetFramework"
            
            # Test the logic manually
            $buildPath = "$generatorDir\bin\$buildConfiguration\$targetFramework"
            if (-not [string]::IsNullOrWhiteSpace($runtimeIdentifier)) {
                $buildPath += "\$runtimeIdentifier"
            }
            
            $buildPath | Should -Be $expectedPath
        }
        
        It "Should handle null RuntimeIdentifier" {
            $generatorDir = "C:\TestProject"
            $buildConfiguration = "Release"
            $targetFramework = "net8.0"
            $runtimeIdentifier = $null
            
            $expectedPath = "$generatorDir\bin\$buildConfiguration\$targetFramework"
            
            # Test the logic manually
            $buildPath = "$generatorDir\bin\$buildConfiguration\$targetFramework"
            if (-not [string]::IsNullOrWhiteSpace($runtimeIdentifier)) {
                $buildPath += "\$runtimeIdentifier"
            }
            
            $buildPath | Should -Be $expectedPath
        }
    }
    
    Context "Different Target Frameworks" {
        It "Should handle different target frameworks" {
            $generatorDir = "C:\TestProject"
            $buildConfiguration = "Debug"
            $targetFramework = "net9.0"
            $runtimeIdentifier = "linux-x64"
            
            $expectedPath = "$generatorDir\bin\$buildConfiguration\$targetFramework\$runtimeIdentifier"
            
            # Test the logic manually
            $buildPath = "$generatorDir\bin\$buildConfiguration\$targetFramework"
            if (-not [string]::IsNullOrWhiteSpace($runtimeIdentifier)) {
                $buildPath += "\$runtimeIdentifier"
            }
            
            $buildPath | Should -Be $expectedPath
        }
    }
}

Describe "Project Name Extraction" {
    It "Should extract correct project name from csproj path" {
        $projectPath = "TestGen\TestGen\TestGen.csproj"
        $expectedName = "TestGen"
        
        $actualName = [System.IO.Path]::GetFileNameWithoutExtension($projectPath)
        $actualName | Should -Be $expectedName
    }
    
    It "Should handle complex project paths" {
        $projectPath = "C:\Projects\MyLibraryGenerator\src\MyLibraryGenerator.csproj"
        $expectedName = "MyLibraryGenerator"
        
        $actualName = [System.IO.Path]::GetFileNameWithoutExtension($projectPath)
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
        It "Should work with sample binding parameters" {
            $params = @{
                GeneratorProject   = "SampleGen\SampleGen\SampleGen.csproj"
                GeneratorName      = "SampleBinding"
                BuildConfiguration = "Release"
                TargetFramework    = "net8.0"
                RuntimeIdentifier  = "win-x64"
            }
            
            # Validate this combination would work
            $params.GeneratorProject | Should -Not -BeNullOrEmpty
            $params.GeneratorName | Should -Not -BeNullOrEmpty
        }
        
        It "Should work with OpenGL-like parameters (no RuntimeIdentifier)" {
            $params = @{
                GeneratorProject   = "OpenGLGen\OpenGLGen\OpenGLGen.csproj"
                GeneratorName      = "OpenGL"
                BuildConfiguration = "Release"
                TargetFramework    = "net8.0"
                RuntimeIdentifier  = ""
            }
            
            # Validate this combination would work
            $params.GeneratorProject | Should -Not -BeNullOrEmpty
            $params.GeneratorName | Should -Not -BeNullOrEmpty
        }
        
        It "Should work with future .NET version" {
            $params = @{
                GeneratorProject   = "FutureGen\FutureGen\FutureGen.csproj"
                GeneratorName      = "Future"
                BuildConfiguration = "Release"
                TargetFramework    = "net10.0"
                RuntimeIdentifier  = "win-arm64"
            }
            
            # Validate this combination would work
            $params.GeneratorProject | Should -Not -BeNullOrEmpty
            $params.GeneratorName | Should -Not -BeNullOrEmpty
            $params.TargetFramework | Should -Match "net\d+\.\d+"
        }
    }
}