# Testing Guide for sync-standards.ps1

This directory contains a comprehensive test suite for the `sync-standards.ps1` script using **Pester 5.7.1+**.

## Requirements

- **PowerShell 5.1+** or **PowerShell Core 7+**
- **Pester 5.7.1+** (automatically installed if not available)

## Test Structure

```
tests/
├── unit/                           # Unit tests
│   └── SyncStandards.Tests.ps1    # Individual function tests
├── integration/                    # Integration tests  
│   └── SyncStandards.Integration.Tests.ps1  # End-to-end tests
├── fixtures/                      # Test data
│   ├── manifest-basic.json        # Basic manifest
│   ├── manifest-with-overwrite.json  # Manifest with overwrite policies
│   ├── override-basic.json        # Example override file
│   └── mock-repo/                 # Simulated repository
├── Run-Tests.ps1                  # Main test execution script
└── README.md                      # This documentation
```

## Running Tests

### Main Test Script (Recommended)
```powershell
# Run all tests
.\tests\Run-Tests.ps1

# Only unit tests
.\tests\Run-Tests.ps1 -UnitOnly

# Only integration tests
.\tests\Run-Tests.ps1 -IntegrationOnly

# Filter tests by name pattern
.\tests\Run-Tests.ps1 -TestName "Get-RawUrl"

# Generate XML report
.\tests\Run-Tests.ps1 -OutputFile "test-results.xml" -OutputFormat "NUnitXml"

# Return test results object
$Results = .\tests\Run-Tests.ps1 -PassThru
```

### Direct Pester Execution
```powershell
# Install Pester if not available
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run specific test files
Invoke-Pester .\tests\unit\SyncStandards.Tests.ps1
Invoke-Pester .\tests\integration\SyncStandards.Integration.Tests.ps1
```

## Test Coverage

### Unit Tests
- **Get-RawUrl**: GitHub URL generation with explicit parameters
- **Resolve-Dst**: Destination remapping logic  
- **Is-Ignored**: File filtering by glob patterns

### Integration Tests  
- **Local synchronization**: Copy from local repository
- **Dry-run mode**: Verification without modifications
- **Override files**: Application of remap and ignore rules
- **Overwrite policies**: `always` vs `ifMissing`
- **Error handling**: Invalid manifests, missing files
- **Directory creation**: Nested folder structures
- **Schema validation**: Compatibility between manifest and override

## Testing Approach

### TestMode Integration
The script includes a `-TestMode` parameter that allows loading functions without executing the main logic:

```powershell
# Load functions for testing without execution
. .\scripts\sync-standards.ps1 -TestMode

# Test functions directly with explicit parameters  
$url = Get-RawUrl -path "test.txt" -Org "TestOrg" -Repo "TestRepo" -Ref "main"
```

This approach ensures:
- **No code duplication** between script and tests
- **Real function testing** instead of mocking
- **Automatic synchronization** with script changes
- **Maintainable test suite** with single source of truth

## Test Scenarios

### Successful Scenarios
- Basic file synchronization
- Remapping rule application
- Ignore files by glob patterns
- Different overwrite policies
- Automatic directory creation
- Dry-run mode validation

### Error Handling
- Missing or malformed JSON manifests
- Source files not found
- Schema version incompatibility
- Write permission issues
- Empty or corrupted files

### Override Configurations
- Simple remap (string format)
- Advanced remap (object with dst and overwrite)
- Combined remap by src and dst
- Multiple ignore patterns
- Schema validation

## Adding New Tests

### For Unit Tests
1. Edit `tests/unit/SyncStandards.Tests.ps1`
2. Add new `Describe` or `Context` blocks
3. Use dot sourcing with `-TestMode` to load real functions
4. Test functions with explicit parameters

### For Integration Tests
1. Edit `tests/integration/SyncStandards.Integration.Tests.ps1`
2. Create additional fixtures in `tests/fixtures/` if needed
3. Use temporary workspaces to avoid side effects

### Best Practices
- **Isolation**: Each test should be independent
- **Cleanup**: Clean temporary files in `finally` blocks  
- **Descriptive names**: Tests that explain what they verify
- **Reusable fixtures**: Keep test data organized
- **Complete coverage**: Include happy path and edge cases
- **Real function testing**: Use `-TestMode` instead of duplicating code

## CI/CD Integration

The project includes automated testing via GitHub Actions with a modular workflow architecture:

### Workflow Structure
```
.github/workflows/
├── ci.yml                        # Main CI workflow
├── _test-sync-standards.yml      # Reusable test template
└── test-examples.yml             # Usage examples
```

### Main CI Workflow (ci.yml)
```yaml
name: CI
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    uses: ./.github/workflows/_test-sync-standards.yml
```

### Reusable Test Template
The `_test-sync-standards.yml` template provides flexible test execution:

```yaml
# Basic usage - all tests
uses: ./.github/workflows/_test-sync-standards.yml

# Unit tests only  
uses: ./.github/workflows/_test-sync-standards.yml
with:
  unit-only: true

# Integration tests only
uses: ./.github/workflows/_test-sync-standards.yml  
with:
  integration-only: true

# Filtered tests
uses: ./.github/workflows/_test-sync-standards.yml
with:
  test-filter: "Get-RawUrl"
```

### Features
- **Automatic Pester 5.7.1+ installation**
- **Test result reporting** in PRs and commits
- **XML artifact upload** for detailed analysis
- **Cross-platform execution** (Ubuntu/PowerShell Core)
- **Modular architecture** for reusability

### Local CI Testing
```powershell
# Simulate CI environment locally
.\tests\Run-Tests.ps1 -OutputFile "test-results.xml" -OutputFormat "NUnitXml"
```

## Troubleshooting

### Error: "Pester module not found" or incompatible version
```powershell
# Scripts automatically install Pester 5.7.1+, but if issues persist:
Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser -AllowClobber
Remove-Module Pester -Force
Import-Module Pester -RequiredVersion 5.7.1 -Force
```

### Error: "Execution policy restricted"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Tests fail due to permissions
- Verify write permissions in temporary directories
- Run PowerShell as administrator if necessary

### TestMode not working
- Ensure the script has the `-TestMode` parameter
- Verify functions are defined outside the `if (-not $TestMode)` block
- Check dot sourcing syntax: `. .\scripts\sync-standards.ps1 -TestMode`

### Mock repo not found
- Verify that `tests/fixtures/mock-repo/` exists
- Regenerate fixtures by running initial setup

## Test Metrics

Run with reporting to get detailed metrics:
```powershell
$Results = .\tests\Run-Tests.ps1 -PassThru
Write-Host "Coverage: $($Results.PassedCount)/$($Results.TotalCount) tests passed"
Write-Host "Duration: $($Results.Duration)"
```

## Architecture Benefits

The current testing architecture provides:

1. **No Code Duplication**: Tests use real script functions via `-TestMode`
2. **Automatic Synchronization**: Changes in the main script automatically reflect in tests
3. **Modular CI/CD**: Reusable workflow templates for different scenarios
4. **Comprehensive Coverage**: tests covering unit and integration scenarios
5. **Easy Maintenance**: Single source of truth for function logic