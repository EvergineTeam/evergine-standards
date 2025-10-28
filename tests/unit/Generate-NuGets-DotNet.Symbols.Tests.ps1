# Tests for Generate-NuGets-DotNet.ps1 - Symbols Behavior
# These tests verify that symbol packages are generated only when explicitly requested

BeforeAll {
    # Setup
    $scriptPath = "$PSScriptRoot\..\..\scripts\common\Generate-NuGets-DotNet.ps1"
    $tempDir = Join-Path $env:TEMP "NuGetSymbolsTests_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$([Guid]::NewGuid().ToString('N').Substring(0,8))"
    $helpersPath = "$PSScriptRoot\..\..\scripts\common\Helpers.ps1"
    
    # Create test directory
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Create test project file
    $testProject = Join-Path $tempDir "TestProject.csproj"
    $projectContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <PackageId>Evergine.Test.Symbols</PackageId>
    <PackageVersion>1.0.0</PackageVersion>
    <Authors>Evergine Team</Authors>
    <Company>Evergine</Company>
    <Description>Test package for symbols verification</Description>
    <GeneratePackageOnBuild>false</GeneratePackageOnBuild>
  </PropertyGroup>
</Project>
"@
    Set-Content -Path $testProject -Value $projectContent
    
    # Create a simple source file
    $sourceDir = Join-Path $tempDir "src"
    New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
    Set-Content -Path (Join-Path $sourceDir "Class1.cs") -Value "namespace Test { public class Class1 { } }"
}

AfterAll {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Generate-NuGets-DotNet Symbols Tests" {
    
    BeforeEach {
        # Clean output folder before each test
        $outputFolder = Join-Path $tempDir "nupkgs"
        if (Test-Path $outputFolder) {
            Remove-Item -Path $outputFolder -Recurse -Force
        }
    }
    
    Context "Default behavior (no symbols)" {
        It "Should not generate symbol packages by default" {
            # Act
            & $scriptPath -Version "1.0.0-test" -Projects $testProject -OutputFolderBase (Join-Path $tempDir "nupkgs") -HelpersPath $helpersPath
            
            # Assert
            $LASTEXITCODE | Should -Be 0
            
            $outputFolder = Join-Path $tempDir "nupkgs"
            $allFiles = Get-ChildItem -Path $outputFolder
            $nupkgFiles = $allFiles | Where-Object { $_.Name -like "*.nupkg" -and $_.Name -notlike "*.snupkg" -and $_.Name -notlike "*.symbols.nupkg" }
            $snupkgFiles = $allFiles | Where-Object { $_.Name -like "*.snupkg" }
            $symbolsFiles = $allFiles | Where-Object { $_.Name -like "*.symbols.nupkg" }
            
            $nupkgFiles.Count | Should -Be 1
            $snupkgFiles.Count | Should -Be 0
            $symbolsFiles.Count | Should -Be 0
        }
    }
    
    Context "Explicit symbols enabled" {
        It "Should generate snupkg when IncludeSymbols is true" {
            # Act
            & $scriptPath -Version "1.0.1-test" -Projects $testProject -OutputFolderBase (Join-Path $tempDir "nupkgs") -IncludeSymbols $true -HelpersPath $helpersPath
            
            # Assert
            $LASTEXITCODE | Should -Be 0
            
            $outputFolder = Join-Path $tempDir "nupkgs"
            $allFiles = Get-ChildItem -Path $outputFolder
            $nupkgFiles = $allFiles | Where-Object { $_.Name -like "*.nupkg" -and $_.Name -notlike "*.snupkg" -and $_.Name -notlike "*.symbols.nupkg" }
            $snupkgFiles = $allFiles | Where-Object { $_.Name -like "*.snupkg" }
            
            $nupkgFiles.Count | Should -Be 1
            $snupkgFiles.Count | Should -Be 1
            $snupkgFiles[0].Name | Should -Be "Evergine.Test.Symbols.1.0.1-test.snupkg"
        }
        
        It "Should generate legacy symbols.nupkg when requested" {
            # Act
            & $scriptPath -Version "1.0.2-test" -Projects $testProject -OutputFolderBase (Join-Path $tempDir "nupkgs") -IncludeSymbols $true -SymbolsFormat "symbols.nupkg" -HelpersPath $helpersPath
            
            # Assert
            $LASTEXITCODE | Should -Be 0
            
            $outputFolder = Join-Path $tempDir "nupkgs"
            $allFiles = Get-ChildItem -Path $outputFolder
            $nupkgFiles = $allFiles | Where-Object { $_.Name -like "*.nupkg" -and $_.Name -notlike "*.symbols.nupkg" }
            $symbolsFiles = $allFiles | Where-Object { $_.Name -like "*.symbols.nupkg" }
            $snupkgFiles = $allFiles | Where-Object { $_.Name -like "*.snupkg" }
            
            $nupkgFiles.Count | Should -Be 1
            $symbolsFiles.Count | Should -Be 1
            $symbolsFiles[0].Name | Should -Be "Evergine.Test.Symbols.1.0.2-test.symbols.nupkg"
            $snupkgFiles.Count | Should -Be 0
        }
    }
    
    Context "Explicit symbols disabled" {
        It "Should not generate symbols when explicitly disabled" {
            # Act
            & $scriptPath -Version "1.0.3-test" -Projects $testProject -OutputFolderBase (Join-Path $tempDir "nupkgs") -IncludeSymbols $false -HelpersPath $helpersPath
            
            # Assert
            $LASTEXITCODE | Should -Be 0
            
            $outputFolder = Join-Path $tempDir "nupkgs"
            $allFiles = Get-ChildItem -Path $outputFolder
            $nupkgFiles = $allFiles | Where-Object { $_.Name -like "*.nupkg" -and $_.Name -notlike "*.snupkg" -and $_.Name -notlike "*.symbols.nupkg" }
            $snupkgFiles = $allFiles | Where-Object { $_.Name -like "*.snupkg" }
            $symbolsFiles = $allFiles | Where-Object { $_.Name -like "*.symbols.nupkg" }
            
            $nupkgFiles.Count | Should -Be 1
            $snupkgFiles.Count | Should -Be 0
            $symbolsFiles.Count | Should -Be 0
        }
    }
    
    Context "Symbol format validation" {
        It "Should use snupkg format by default when symbols enabled" {
            # Act
            & $scriptPath -Version "1.0.4-test" -Projects $testProject -OutputFolderBase (Join-Path $tempDir "nupkgs") -IncludeSymbols $true -HelpersPath $helpersPath
            
            # Assert
            $LASTEXITCODE | Should -Be 0
            
            $outputFolder = Join-Path $tempDir "nupkgs"
            $allFiles = Get-ChildItem -Path $outputFolder
            $snupkgFiles = $allFiles | Where-Object { $_.Name -like "*.snupkg" }
            $symbolsFiles = $allFiles | Where-Object { $_.Name -like "*.symbols.nupkg" }
            
            $snupkgFiles.Count | Should -Be 1
            $symbolsFiles.Count | Should -Be 0
        }
    }
    
    Context "Multiple projects" {
        It "Should handle symbols consistently across multiple projects" {
            # Create second test project
            $testProject2 = Join-Path $tempDir "TestProject2.csproj"
            $projectContent2 = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <PackageId>Evergine.Test.Symbols2</PackageId>
    <PackageVersion>1.0.0</PackageVersion>
    <Authors>Evergine Team</Authors>
    <Company>Evergine</Company>
    <Description>Second test package for symbols verification</Description>
    <GeneratePackageOnBuild>false</GeneratePackageOnBuild>
  </PropertyGroup>
</Project>
"@
            Set-Content -Path $testProject2 -Value $projectContent2
            
            # Act
            & $scriptPath -Version "1.0.5-test" -Projects @($testProject, $testProject2) -OutputFolderBase (Join-Path $tempDir "nupkgs") -IncludeSymbols $true -HelpersPath $helpersPath
            
            # Assert
            $LASTEXITCODE | Should -Be 0
            
            $outputFolder = Join-Path $tempDir "nupkgs"
            $allFiles = Get-ChildItem -Path $outputFolder
            $nupkgFiles = $allFiles | Where-Object { $_.Name -like "*.nupkg" -and $_.Name -notlike "*.snupkg" -and $_.Name -notlike "*.symbols.nupkg" }
            $snupkgFiles = $allFiles | Where-Object { $_.Name -like "*.snupkg" }
            
            $nupkgFiles.Count | Should -Be 2
            $snupkgFiles.Count | Should -Be 2
            
            $nupkgFiles.Name | Should -Contain "Evergine.Test.Symbols.1.0.5-test.nupkg"
            $nupkgFiles.Name | Should -Contain "Evergine.Test.Symbols2.1.0.5-test.nupkg"
            $snupkgFiles.Name | Should -Contain "Evergine.Test.Symbols.1.0.5-test.snupkg"
            $snupkgFiles.Name | Should -Contain "Evergine.Test.Symbols2.1.0.5-test.snupkg"
        }
    }
}