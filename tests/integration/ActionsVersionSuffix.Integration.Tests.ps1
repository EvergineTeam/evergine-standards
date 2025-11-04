#Requires -Modules Pester

# Integration tests for composite actions with VersionSuffix parameter

BeforeAll {
    # These are basic smoke tests to ensure the actions accept the new parameter
    # Full integration tests would require actual GitHub Actions environment
}

Describe "Composite Actions VersionSuffix Integration Tests" {
    
    Context "addon-generate-assets action" {
        It "Should have version-suffix input defined" {
            $actionFile = "$PSScriptRoot\..\..\\.github\\actions\\addon-generate-assets\\action.yml"
            Test-Path $actionFile | Should -Be $true
            
            $content = Get-Content $actionFile -Raw
            $content | Should -Match "version-suffix:"
            $content | Should -Match "Version suffix to append to the final version"
        }
        
        It "Should pass version-suffix to script" {
            $actionFile = "$PSScriptRoot\..\..\\.github\\actions\\addon-generate-assets\\action.yml"
            $content = Get-Content $actionFile -Raw
            $content | Should -Match '\$versionSuffix'
            $content | Should -Match 'VersionSuffix.*=.*versionSuffix'
        }
    }
    
    Context "binding-generate-nugets-dotnet action" {
        It "Should have version-suffix input defined" {
            $actionFile = "$PSScriptRoot\..\..\\.github\\actions\\binding-generate-nugets-dotnet\\action.yml"
            Test-Path $actionFile | Should -Be $true
            
            $content = Get-Content $actionFile -Raw
            $content | Should -Match "version-suffix:"
            $content | Should -Match "Version suffix to append to the final version"
        }
        
        It "Should pass version-suffix to script" {
            $actionFile = "$PSScriptRoot\..\..\\.github\\actions\\binding-generate-nugets-dotnet\\action.yml"
            $content = Get-Content $actionFile -Raw
            $content | Should -Match '\$versionSuffix'
            $content | Should -Match 'VersionSuffix.*=.*versionSuffix'
        }
    }
    
    Context "Reusable workflows" {
        It "addon-common-ci.yml should support version-suffix" {
            $workflowFile = "$PSScriptRoot\..\..\\.github\\workflows\\addon-common-ci.yml"
            Test-Path $workflowFile | Should -Be $true
            
            $content = Get-Content $workflowFile -Raw
            $content | Should -Match "version-suffix:"
            $content | Should -Match "version-suffix:.*inputs\.version-suffix"
        }
        
        It "addon-simple-cd.yml should support version-suffix" {
            $workflowFile = "$PSScriptRoot\..\..\\.github\\workflows\\addon-simple-cd.yml"
            Test-Path $workflowFile | Should -Be $true
            
            $content = Get-Content $workflowFile -Raw
            $content | Should -Match "version-suffix:"
            $content | Should -Match "version-suffix:.*inputs\.version-suffix"
        }
        
        It "binding-common-ci.yml should support version-suffix" {
            $workflowFile = "$PSScriptRoot\..\..\\.github\\workflows\\binding-common-ci.yml"
            Test-Path $workflowFile | Should -Be $true
            
            $content = Get-Content $workflowFile -Raw
            $content | Should -Match "version-suffix:"
            $content | Should -Match "version-suffix:.*inputs\.version-suffix"
        }
    }
    
    Context "Template workflows" {
        It "template-cd-nightly.yml should use nightly suffix" {
            $templateFile = "$PSScriptRoot\\..\\..\\workflows\\add-ons\\template-cd-nightly.yml"
            Test-Path $templateFile | Should -Be $true
            
            $content = Get-Content $templateFile -Raw
            $content | Should -Match 'version-suffix:.*"nightly"'
        }
        
        It "template-cd-nightly.yml should document version suffix usage" {
            $templateFile = "$PSScriptRoot\\..\\..\\workflows\\add-ons\\template-cd-nightly.yml"
            $content = Get-Content $templateFile -Raw
            $content | Should -Match "nightly.*suffix"
        }
    }
}