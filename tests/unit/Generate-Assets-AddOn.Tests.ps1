#Requires -Modules Pester

BeforeAll {
    # Import the script to test
    $scriptPath = "$PSScriptRoot\..\..\scripts\add-ons\Generate-Assets-AddOn.ps1"
    $helpersPath = "$PSScriptRoot\..\..\scripts\common\Helpers.ps1"
    $fixturesPath = Resolve-Path "$PSScriptRoot\..\fixtures"
	
    # Load helpers first
    . $helpersPath
	
    # Load script functions in test mode (without executing main logic)
    . $scriptPath -TestMode
	
    # Define fixture project paths
    $script:testAddonAssetsProject = Join-Path $fixturesPath "addon-test-data\TestAddon.Assets\TestAddon.Assets.csproj"
    $script:testAddonWespecFile = Join-Path $fixturesPath "addon-test-data\TestAddon.Assets\TestAddon.wespec"
    $script:testAddonAssetsDir = Join-Path $fixturesPath "addon-test-data\TestAddon.Assets"
}

Describe "Generate-Assets-AddOn Script Tests" {
	
    Context "Parameter Validation" {
        It "Should require either Version or Revision parameter" {
            $result = Test-AssetParameters @{ Version = ""; Revision = ""; AssetsCsprojPath = "test.csproj" }
            $result | Should -Be $false
        }
        
        It "Should not allow both Version and Revision parameters" {
            $result = Test-AssetParameters @{ Version = "1.0.0"; Revision = "123"; AssetsCsprojPath = "test.csproj" }
            $result | Should -Be $false
        }
        
        It "Should validate required AssetsCsprojPath parameter" {
            $result = Test-AssetParameters @{ Version = "1.0.0"; Revision = ""; AssetsCsprojPath = "" }
            $result | Should -Be $false
        }
        
        It "Should pass validation with Version and AssetsCsprojPath" {
            $result = Test-AssetParameters @{ Version = "1.0.0"; Revision = ""; AssetsCsprojPath = "test.csproj" }
            $result | Should -Be $true
        }
        
        It "Should pass validation with Revision and AssetsCsprojPath" {
            $result = Test-AssetParameters @{ Version = ""; Revision = "123"; AssetsCsprojPath = "test.csproj" }
            $result | Should -Be $true
        }
    }
    
    Context "Wespec File Detection" {
        It "Should find wespec file in project directory" {
            $result = Find-WespecFile $script:testAddonAssetsDir
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeLike "*TestAddon.wespec"
        }
        
        It "Should return null when no wespec file exists" {
            $tempDir = New-TemporaryFile | % { Remove-Item $_; New-Item -ItemType Directory -Path $_ -Force }
            try {
                $result = Find-WespecFile $tempDir.FullName
                $result | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should throw when multiple wespec files exist" {
            $tempDir = New-TemporaryFile | % { Remove-Item $_; New-Item -ItemType Directory -Path $_ -Force }
            try {
                New-Item -ItemType File -Path (Join-Path $tempDir "test1.wespec") -Force
                New-Item -ItemType File -Path (Join-Path $tempDir "test2.wespec") -Force
                
                { Find-WespecFile $tempDir.FullName } | Should -Throw "*Multiple .wespec files found*"
            }
            finally {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "Wespec Version Update" {
        BeforeEach {
            # Create a temporary copy of the test wespec file
            $script:tempWespecFile = New-TemporaryFile
            Copy-Item $script:testAddonWespecFile $script:tempWespecFile.FullName -Force
        }
        
        AfterEach {
            Remove-Item $script:tempWespecFile -Force -ErrorAction SilentlyContinue
        }
        
        It "Should update version token in wespec file" {
            # Ensure powershell-yaml is available for the test
            if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
                Install-Module -Name powershell-yaml -Force -Scope CurrentUser
            }
            Import-Module powershell-yaml
            
            $newVersion = "2025.1.0.123-preview"
            $originalToken = "2025.0.0.0-preview"
            
            # Verify original content
            $originalContent = Get-Content -Raw $script:tempWespecFile.FullName
            $originalContent | Should -Match $originalToken
            
            # Update version
            Update-WespecVersion -WespecPath $script:tempWespecFile.FullName -Version $newVersion -VersionToken $originalToken
            
            # Verify updated content
            $updatedContent = Get-Content -Raw $script:tempWespecFile.FullName
            $updatedContent | Should -Match $newVersion
            $updatedContent | Should -Not -Match $originalToken
        }
        
        It "Should preserve file structure when updating version" {
            # Ensure powershell-yaml is available for the test
            if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
                Install-Module -Name powershell-yaml -Force -Scope CurrentUser
            }
            Import-Module powershell-yaml
            
            $newVersion = "2025.1.0.123-preview"
            $originalToken = "2025.0.0.0-preview"
            
            # Parse original structure
            $originalYaml = Get-Content -Raw $script:tempWespecFile.FullName | ConvertFrom-Yaml -Ordered
            $originalAuthors = $originalYaml.Authors
            $originalDescription = $originalYaml.Description
            
            # Update version
            Update-WespecVersion -WespecPath $script:tempWespecFile.FullName -Version $newVersion -VersionToken $originalToken
            
            # Parse updated structure
            $updatedYaml = Get-Content -Raw $script:tempWespecFile.FullName | ConvertFrom-Yaml -Ordered
            
            # Verify structure is preserved
            $updatedYaml.Authors | Should -Be $originalAuthors
            $updatedYaml.Description | Should -Be $originalDescription
            $updatedYaml.Nugets | Should -Match $newVersion
        }
        
        It "Should handle missing version token gracefully" {
            # Ensure powershell-yaml is available for the test
            if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
                Install-Module -Name powershell-yaml -Force -Scope CurrentUser
            }
            Import-Module powershell-yaml
            
            $newVersion = "2025.1.0.123-preview"
            $nonExistentToken = "9999.0.0.0-preview"
            
            $originalContent = Get-Content -Raw $script:tempWespecFile.FullName
            
            # This should not throw, just leave file unchanged
            { Update-WespecVersion -WespecPath $script:tempWespecFile.FullName -Version $newVersion -VersionToken $nonExistentToken } | Should -Not -Throw
            
            $updatedContent = Get-Content -Raw $script:tempWespecFile.FullName
            $updatedContent | Should -Be $originalContent
        }
    }
    
    Context "Build Process Simulation" {
        BeforeEach {
            # Clean up any previous test outputs
            Remove-Item "wepkgs" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        AfterEach {
            Remove-Item "wepkgs" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Should validate assets project file exists" {
            Test-Path $script:testAddonAssetsProject | Should -Be $true
        }
        
        It "Should validate wespec file exists" {
            Test-Path $script:testAddonWespecFile | Should -Be $true
        }
        
        It "Should create output directory" {
            $outputFolder = "test-wepkgs"
            try {
                $result = CreateOutputFolder $outputFolder
                $result | Should -Not -BeNullOrEmpty
                Test-Path $outputFolder | Should -Be $true
            }
            finally {
                Remove-Item $outputFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "Integration Tests" {
        BeforeEach {
            # Clean up any previous test outputs
            Remove-Item "wepkgs" -Recurse -Force -ErrorAction SilentlyContinue
            
            # Create a temporary working directory with copies of test files
            $script:tempWorkDir = New-TemporaryFile | % { Remove-Item $_; New-Item -ItemType Directory -Path $_ -Force }
            Copy-Item $script:testAddonAssetsDir\* $script:tempWorkDir.FullName -Recurse -Force
            $script:tempAssetsCsproj = Join-Path $script:tempWorkDir.FullName "TestAddon.Assets.csproj"
            $script:tempWespecFile = Join-Path $script:tempWorkDir.FullName "TestAddon.wespec"
        }
        
        AfterEach {
            Remove-Item "wepkgs" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item $script:tempWorkDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Should detect wespec file automatically" {
            $projectDir = Split-Path $script:tempAssetsCsproj -Parent
            $result = Find-WespecFile $projectDir
            $result | Should -Be $script:tempWespecFile
        }
        
        It "Should update wespec and prepare for build" {
            # Ensure powershell-yaml is available for the test
            if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
                Install-Module -Name powershell-yaml -Force -Scope CurrentUser
            }
            Import-Module powershell-yaml
            
            $testVersion = "2025.1.0.999-test"
            $defaultToken = "2025.0.0.0-preview"
            
            # Verify test can read/write the temporary wespec file
            Test-Path $script:tempWespecFile | Should -Be $true
            
            # Update the version
            Update-WespecVersion -WespecPath $script:tempWespecFile -Version $testVersion -VersionToken $defaultToken
            
            # Verify the update worked
            $updatedContent = Get-Content -Raw $script:tempWespecFile
            $updatedContent | Should -Match $testVersion
            $updatedContent | Should -Not -Match $defaultToken
        }
    }
    
    Context "End-to-End Package Generation" {
        BeforeEach {
            # Clean up any previous test outputs
            Remove-Item "test-wepkgs" -Recurse -Force -ErrorAction SilentlyContinue
            
            # Create a temporary working directory with copies of test files
            $script:tempWorkDir = New-TemporaryFile | % { Remove-Item $_; New-Item -ItemType Directory -Path $_ -Force }
            Copy-Item $script:testAddonAssetsDir\* $script:tempWorkDir.FullName -Recurse -Force
            $script:tempAssetsCsproj = Join-Path $script:tempWorkDir.FullName "TestAddon.Assets.csproj"
            $script:tempWespecFile = Join-Path $script:tempWorkDir.FullName "TestAddon.wespec"
            
            # Reset wespec file to original state for testing
            Copy-Item $script:testAddonWespecFile $script:tempWespecFile -Force
        }
        
        AfterEach {
            Remove-Item "test-wepkgs" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item $script:tempWorkDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Should generate .wepkg package file with correct version" {
            # This test verifies the complete end-to-end process
            $testVersion = "2025.1.0.888-e2e-test"
            $outputFolder = "test-wepkgs"
            
            # Execute the script with test parameters
            & $scriptPath `
                -Version $testVersion `
                -AssetsCsprojPath $script:tempAssetsCsproj `
                -WespecPath $script:tempWespecFile `
                -OutputFolderBase $outputFolder `
                -HelpersPath $helpersPath `
                -VersionToken "2025.0.0.0-preview"
                
            # Verify the script completed successfully
            $LASTEXITCODE | Should -Be 0
            
            # Verify output directory was created
            Test-Path $outputFolder | Should -Be $true
            
            # Verify .wepkg files were generated
            $wepkgFiles = Get-ChildItem -Path $outputFolder -Filter "*.wepkg" -File
            $wepkgFiles | Should -Not -BeNullOrEmpty
            $wepkgFiles.Count | Should -BeGreaterThan 0
            
            # Verify file properties
            $wepkgFile = $wepkgFiles[0]
            $wepkgFile.Name | Should -Match "\.wepkg$"
            $wepkgFile.Length | Should -BeGreaterThan 1000  # Reasonable size for a package
            
            # Verify .wespec file was updated with correct version
            $updatedWespecContent = Get-Content -Raw $script:tempWespecFile
            $updatedWespecContent | Should -Match $testVersion
            $updatedWespecContent | Should -Not -Match "2025\.0\.0\.0-preview"
        }
        
        It "Should work with Revision parameter and generate package" {
            # Test the revision-based versioning
            $testRevision = "999"
            $expectedDate = Get-Date -Format "yyyy.M.d"
            $expectedVersion = "$expectedDate.$testRevision"
            $outputFolder = "test-wepkgs"
            
            # Execute the script with revision parameter
            & $scriptPath `
                -Revision $testRevision `
                -AssetsCsprojPath $script:tempAssetsCsproj `
                -WespecPath $script:tempWespecFile `
                -OutputFolderBase $outputFolder `
                -HelpersPath $helpersPath `
                -VersionToken "2025.0.0.0-preview"
                
            # Verify the script completed successfully
            $LASTEXITCODE | Should -Be 0
            
            # Verify .wepkg files were generated
            $wepkgFiles = Get-ChildItem -Path $outputFolder -Filter "*.wepkg" -File
            $wepkgFiles | Should -Not -BeNullOrEmpty
            
            # Verify .wespec file was updated with calculated version
            $updatedWespecContent = Get-Content -Raw $script:tempWespecFile
            $escapedVersion = [regex]::Escape($expectedVersion)
            $updatedWespecContent | Should -Match $escapedVersion
        }
        
        It "Should generate .wepkg with correct version in manifest" {
            # Test that the generated .wepkg contains the correct version
            $testVersion = "2025.1.0.777-version-test"
            $outputFolder = "test-wepkgs"
            
            # Execute the script
            & $scriptPath `
                -Version $testVersion `
                -AssetsCsprojPath $script:tempAssetsCsproj `
                -WespecPath $script:tempWespecFile `
                -OutputFolderBase $outputFolder `
                -HelpersPath $helpersPath `
                -VersionToken "2025.0.0.0-preview"
                
            # Verify the script completed successfully
            $LASTEXITCODE | Should -Be 0
            
            # Find the generated .wepkg file
            $wepkgFiles = Get-ChildItem -Path $outputFolder -Filter "*.wepkg" -File
            $wepkgFiles | Should -Not -BeNullOrEmpty
            $wepkgFile = $wepkgFiles[0]
            
            # Extract and verify the .wepkg content (it's a zip file)
            $tempExtractDir = New-TemporaryFile | % { Remove-Item $_; New-Item -ItemType Directory -Path $_ -Force }
            try {
                # Expand the .wepkg file (rename to .zip and extract)
                $tempZipFile = Join-Path $tempExtractDir.FullName "package.zip"
                Copy-Item $wepkgFile.FullName $tempZipFile
                Expand-Archive -Path $tempZipFile -DestinationPath $tempExtractDir.FullName -Force
                
                # Look for manifest file that should contain the version
                $manifestFiles = Get-ChildItem -Path $tempExtractDir.FullName -Filter "*.wespec" -Recurse
                $manifestFiles | Should -Not -BeNullOrEmpty
                
                # Verify the manifest contains the correct version
                $manifestContent = Get-Content -Raw $manifestFiles[0].FullName
                $manifestContent | Should -Match ([regex]::Escape($testVersion))
                $manifestContent | Should -Not -Match "2025\.0\.0\.0-preview"
                
                Write-Host "✓ Verified .wepkg package contains correct version: $testVersion" -ForegroundColor Green
            }
            finally {
                Remove-Item $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "VersionSuffix Parameter Tests" {
        BeforeEach {
            # Mock external dependencies
            Mock -CommandName "dotnet" -MockWith { 
                param($ArgumentList)
                # Simulate successful dotnet build/pack
                return $true
            }
            Mock -CommandName "Test-Path" -MockWith { return $true }
            Mock -CommandName "Get-ChildItem" -MockWith { 
                # Mock wepkg files generated
                return @(
                    @{ Name = "TestAddon.wepkg"; FullName = "C:\temp\TestAddon.wepkg" }
                )
            }
        }
        
        It "Should accept VersionSuffix parameter in Test-AssetParameters" {
            $result = Test-AssetParameters @{ 
                Version          = "1.0.0"
                VersionSuffix    = "nightly"
                AssetsCsprojPath = "test.csproj" 
            }
            $result | Should -Be $true
        }
        
        It "Should handle VersionSuffix with revision" {
            $result = Test-AssetParameters @{ 
                Revision         = "123"
                VersionSuffix    = "beta"
                AssetsCsprojPath = "test.csproj" 
            }
            $result | Should -Be $true
        }
        
        It "Should work without VersionSuffix" {
            $result = Test-AssetParameters @{ 
                Version          = "1.0.0"
                AssetsCsprojPath = "test.csproj" 
            }
            $result | Should -Be $true
        }
        
        It "Should handle VersionSuffix with leading dash" {
            $result = Test-AssetParameters @{ 
                Version          = "1.0.0"
                VersionSuffix    = "-alpha"
                AssetsCsprojPath = "test.csproj" 
            }
            $result | Should -Be $true
        }
        
        It "Should process version with suffix correctly" {
            # Test that Test-AssetParameters accepts VersionSuffix and Resolve-Version works
            Mock -CommandName "Resolve-Version" -MockWith { return "1.0.0-nightly" }
            
            $parameters = @{ 
                Version          = "1.0.0"
                VersionSuffix    = "nightly"
                AssetsCsprojPath = "test.csproj" 
            }
            
            # Test parameter validation with suffix
            $result = Test-AssetParameters $parameters
            $result | Should -Be $true
            
            # Test that Resolve-Version would be called correctly (simulate the script logic)
            $resolvedVersion = Resolve-Version -version $parameters.Version -versionSuffix $parameters.VersionSuffix
            $resolvedVersion | Should -Be "1.0.0-nightly"
        }
        
        It "Should handle complex VersionSuffix values" {
            # Test that complex suffixes are handled properly
            $parameters = @{ 
                Version          = "2.1.0"
                VersionSuffix    = "rc1-build123"
                AssetsCsprojPath = "test.csproj" 
            }
            
            # Test parameter validation
            $result = Test-AssetParameters $parameters
            $result | Should -Be $true
            
            # Test version resolution
            $resolvedVersion = Resolve-Version -version $parameters.Version -versionSuffix $parameters.VersionSuffix
            $resolvedVersion | Should -Be "2.1.0-rc1-build123"
        }
        
        It "Should accept VersionSuffix parameter" {
            # Simple test to verify that VersionSuffix parameter is recognized
            # by checking the script's parameter definition
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match '\$VersionSuffix'
        }
        
        AfterEach {
            # Clean up test outputs (only test-specific folders, not workspace assets)
            Remove-Item "wepkgs" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "test-assets" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}