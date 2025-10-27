# tests/unit/SyncStandards.Tests.ps1
# Unit tests for sync-standards.ps1 script

BeforeAll {
    # Load the actual script using dot sourcing with TestMode to avoid execution
    $ScriptPath = Join-Path $PSScriptRoot "..\..\tools\sync-standards.ps1"
    
    # Dot source the script with TestMode parameter
    . $ScriptPath -TestMode
    
    # Override the script parameters with test values
    $global:Org = "TestOrg"
    $global:Repo = "TestRepo" 
    $global:Ref = "main"
    $global:overwrites = $null
}

Describe "Get-RawUrl Function" {
    It "Should generate correct GitHub raw URL" {
        $result = Get-RawUrl -path "test/file.txt" -Org "TestOrg" -Repo "TestRepo" -Ref "main"
        $result | Should -Be "https://raw.githubusercontent.com/TestOrg/TestRepo/main/test/file.txt"
    }
    
    It "Should handle paths with special characters" {
        $result = Get-RawUrl -path "folder with spaces/file-name.json" -Org "TestOrg" -Repo "TestRepo" -Ref "main"
        $result | Should -Be "https://raw.githubusercontent.com/TestOrg/TestRepo/main/folder with spaces/file-name.json"
    }
    
    It "Should handle root level files" {
        $result = Get-RawUrl -path "LICENSE" -Org "TestOrg" -Repo "TestRepo" -Ref "main"
        $result | Should -Be "https://raw.githubusercontent.com/TestOrg/TestRepo/main/LICENSE"
    }
}

Describe "Resolve-Dst Function" {
    Context "Without override configuration" {
        BeforeEach {
            $global:overwrites = $null
        }
        
        It "Should return original destination when no overrides" {
            $result = Resolve-Dst "src.txt" "dst.txt" "always"
            $result.dst | Should -Be "dst.txt"
            $result.overwrite | Should -Be "always"
        }
    }
    
    Context "With remap configuration - string format" {
        BeforeEach {
            $global:overwrites = [PSCustomObject]@{
                remap = [PSCustomObject]@{
                    "dst.txt" = "new-dst.txt"
                    "src.txt" = "remapped-by-src.txt"
                }
            }
        }
        
        It "Should remap destination when dst matches" {
            $result = Resolve-Dst "src.txt" "dst.txt" "always"
            $result.dst | Should -Be "new-dst.txt"
            $result.overwrite | Should -Be "always"
        }
        
        It "Should remap by source when src matches" {
            $result = Resolve-Dst "src.txt" "other-dst.txt" "always"
            $result.dst | Should -Be "remapped-by-src.txt"
            $result.overwrite | Should -Be "always"
        }
        
        It "Should prefer dst remap over src remap" {
            $result = Resolve-Dst "src.txt" "dst.txt" "always"
            $result.dst | Should -Be "new-dst.txt"
        }
    }
    
    Context "With remap configuration - object format" {
        BeforeEach {
            $global:overwrites = [PSCustomObject]@{
                remap = [PSCustomObject]@{
                    "dst.txt" = [PSCustomObject]@{
                        dst       = "new-dst.txt"
                        overwrite = "ifMissing"
                    }
                }
            }
        }
        
        It "Should remap both destination and overwrite policy" {
            $result = Resolve-Dst "src.txt" "dst.txt" "always"
            $result.dst | Should -Be "new-dst.txt"
            $result.overwrite | Should -Be "ifMissing"
        }
        
        It "Should use default overwrite when not specified in remap" {
            $global:overwrites = [PSCustomObject]@{
                remap = [PSCustomObject]@{
                    "dst.txt" = [PSCustomObject]@{
                        dst = "new-dst.txt"
                    }
                }
            }
            $result = Resolve-Dst "src.txt" "dst.txt" "always"
            $result.dst | Should -Be "new-dst.txt"
            $result.overwrite | Should -Be "always"
        }
    }
}

Describe "Is-Ignored Function" {
    Context "Without ignore configuration" {
        BeforeEach {
            $global:overwrites = $null
        }
        
        It "Should not ignore any files when no ignore rules" {
            $result = Is-Ignored "any/file/path.txt"
            $result | Should -Be $false
        }
    }
    
    Context "With ignore patterns" {
        BeforeEach {
            $global:overwrites = [PSCustomObject]@{
                ignore = @(
                    "*.tmp",
                    "*temp*",
                    "*debug*.log"
                )
            }
        }
        
        It "Should ignore files matching wildcard patterns" {
            Is-Ignored "file.tmp" | Should -Be $true
            Is-Ignored "something-temp-folder" | Should -Be $true
            Is-Ignored "app-debug-output.log" | Should -Be $true
        }
        
        It "Should not ignore files that don't match patterns" {
            Is-Ignored "file.txt" | Should -Be $false
            Is-Ignored "logs/production.txt" | Should -Be $false
            Is-Ignored "release/info.txt" | Should -Be $false
        }
        
        It "Should handle nested paths correctly" {
            Is-Ignored "project/temp/file.txt" | Should -Be $true
            Is-Ignored "project/debug/app.log" | Should -Be $true
        }
    }
}