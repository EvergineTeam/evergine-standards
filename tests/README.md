# Testing Guide for Evergine Standards

This directory contains a comprehensive test suite for the Evergine standards unification project using **Pester 5.7.1+**.

## Project Overview

This project unifies scripts and workflows across multiple Evergine binding repositories, providing:
- **Synchronized script templates** for binding generation and NuGet packaging
- **Centralized standards** managed via `sync-standards.ps1`
- **Automated testing** for all components
- **CI/CD compatibility** with cleanup automation

## Requirements

- **PowerShell 5.1+** or **PowerShell Core 7+**
- **Pester 5.7.1+** (automatically installed if not available)
- **.NET 8.0** for NuGet packaging tests

## Test Structure

```
tests/
├── fixtures/                                 # Test data and mock projects
│   ├── *.csproj                             # Real .NET project files for testing
│   ├── *.json                               # Manifest and override files
│   └── mock-repo/                           # Simulated repository
├── integration/                               # Integration tests  
│   └── SyncStandards.Integration.Tests.ps1   # End-to-end sync tests
├── unit/                                       # Unit tests
│   ├── Generate-Bindings-DotNet.Tests.ps1    # Binding generation script
│   ├── Generate-NuGets-DotNet.*.Tests.ps1    # Specialized NuGet tests
│   ├── Generate-NuGets-DotNet.Tests.ps1      # NuGet packaging script
│   ├── Helpers.Tests.ps1                     # Shared helper functions
│   └── SyncStandards.Tests.ps1               # Sync standards functionality
├── README.md                                # This documentation
└── Run-Tests.ps1                             # Main test execution script
```

## Scripts Under Test

### 1. **Sync Standards** (`scripts/sync-standards.ps1`)
Synchronizes files across Evergine repositories based on manifest configuration.

### 2. **Binding Generation** (`scripts/binding/Generate-Bindings-DotNet.ps1`)
Parameterized template for generating .NET bindings across different repositories.

### 3. **NuGet Packaging** (`scripts/binding/Generate-NuGets-DotNet.ps1`)
Unified script for generating NuGet packages supporting both:
- **Binding style**: Date-based versions with revision numbers
- **Add-on style**: Direct version specification

### 4. **Shared Helpers** (`scripts/common/Helpers.ps1`)
Common utilities for logging, variable display, and file operations.

## Requirements

- **PowerShell 5.1+** or **PowerShell Core 7+**
- **Pester 5.7.1+** (automatically installed if not available)
- **.NET 8.0** for NuGet packaging tests

## Running Tests

### Main Test Script (Recommended)
```powershell
# Run all tests (sync + binding scripts)
.\tests\Run-Tests.ps1

# Only unit tests (98 tests)
.\tests\Run-Tests.ps1 -UnitOnly

# Only integration tests
.\tests\Run-Tests.ps1 -IntegrationOnly

# Filter tests by name pattern
.\tests\Run-Tests.ps1 -TestName "Generate-NuGets"

# Generate XML report
.\tests\Run-Tests.ps1 -OutputFile "test-results.xml" -OutputFormat "NUnitXml"

# Return test results object
$Results = .\tests\Run-Tests.ps1 -PassThru
```

### Individual Test Files
```powershell
# Test sync standards functionality
Invoke-Pester .\tests\unit\SyncStandards.Tests.ps1

# Test binding generation script
Invoke-Pester .\tests\unit\Generate-Bindings-DotNet.Tests.ps1

# Test NuGet packaging script (comprehensive)
Invoke-Pester .\tests\unit\Generate-NuGets-DotNet.Tests.ps1

# Test shared helper functions
Invoke-Pester .\tests\unit\Helpers.Tests.ps1

# Integration tests
Invoke-Pester .\tests\integration\SyncStandards.Integration.Tests.ps1
```

### Automatic Cleanup
All tests include automatic cleanup of build artifacts:
- `bin/` folders from compilation
- `obj/` folders from build cache  
- `nupkgs/` folders from package generation

Cleanup occurs both **per test file** (AfterAll) and **globally** (Run-Tests.ps1).

## Test Coverage

### Sync Standards Tests (24 tests)
- **Get-RawUrl**: GitHub URL generation with explicit parameters
- **Resolve-Dst**: Destination remapping logic  
- **Is-Ignored**: File filtering by glob patterns
- **Integration scenarios**: Local sync, dry-run, overrides, schema validation

### Binding Generation Tests (16 tests)
- **Parameter validation**: Required parameters and combinations
- **Command generation**: dotnet run with proper arguments
- **Path handling**: Relative and absolute project paths
- **Error conditions**: Missing files, invalid parameters
- **Integration scenarios**: Real-world parameter combinations

### NuGet Packaging Tests (23 tests)
- **Version calculation**: Date-based vs direct version modes
- **Project handling**: Single and multiple project scenarios
- **Parameter validation**: Required parameters and error cases
- **File operations**: Project file validation and output folder creation
- **Helpers integration**: LogDebug and ShowVariables function calls

### NuGet Specialized Tests (35 tests)
- **MultiProject.Tests**: Complex scenarios with multiple .csproj files
- **Simple.Tests**: Basic single-project packaging
- **VersionValidation.Tests**: Comprehensive NuGet semantic versioning validation

### Helper Functions Tests (23 tests)
- **LogDebug**: CI/CD compatible logging with ##[debug] prefix
- **ShowVariables**: Hashtable display in both modern and legacy formats
- **CreateOutputFolder**: Directory creation with error handling

### Integration Tests (8 tests)
- **End-to-end sync**: Complete workflow testing
- **Override handling**: Complex remap and ignore scenarios
- **Error handling**: Comprehensive failure mode testing

## Testing Approach

### TestMode Integration (Sync Standards)
The sync-standards script includes a `-TestMode` parameter for loading functions without execution:

```powershell
# Load functions for testing without execution
. .\scripts\sync-standards.ps1 -TestMode

# Test functions directly with explicit parameters  
$url = Get-RawUrl -path "test.txt" -Org "TestOrg" -Repo "TestRepo" -Ref "main"
```

### Real Project Testing (Binding Scripts)
Binding and NuGet scripts are tested with real .csproj files in `tests/fixtures/`:
- `SingleProject.csproj`: Basic single-project scenario
- `BindingProject.csproj`: Binding-specific project structure
- `MultiProject.Runtime.csproj` & `MultiProject.Editor.csproj`: Multi-project scenarios

### Mock Strategy
- **Minimal mocking**: Use real functions where possible
- **Strategic mocks**: Mock external dependencies (dotnet, file system)
- **Path filtering**: Mock Test-Path to allow Helpers.ps1 but reject test projects

This approach ensures:
- **No code duplication** between scripts and tests
- **Real function testing** instead of excessive mocking
- **Automatic synchronization** with script changes
- **Maintainable test suite** with single source of truth

## Test Scenarios

### Sync Standards Scenarios
- Basic file synchronization with schema v2 groups
- Remapping rule application and destination resolution
- Ignore files by glob patterns and override handling
- Different overwrite policies (`always` vs `ifMissing`)
- Automatic directory creation and dry-run validation
- Error handling for malformed manifests and missing files

### Binding Generation Scenarios  
- Parameter validation and command generation
- Project path resolution (relative/absolute)
- Error conditions (missing projects, invalid combinations)
- Real-world parameter combinations with sample binding projects

### NuGet Packaging Scenarios
- **Version modes**: Date-based (`2025.10.28.123`) vs direct (`1.0.0-alpha`)
- **Project types**: Single project vs multi-project packaging
- **Parameter validation**: Empty projects arrays, missing required parameters
- **File operations**: Project existence validation and output folder creation
- **Error handling**: Invalid version formats, missing Helpers.ps1
- **Version validation**: NuGet semantic versioning compliance

### Error Handling Coverage
- Missing or malformed JSON manifests
- Source files not found / invalid project paths
- Schema version incompatibility
- Write permission issues and folder creation failures
- Interactive parameter prompts (resolved for CI/CD compatibility)
- Invalid NuGet version formats preventing dotnet pack failures

## Adding New Tests

### For Sync Standards
1. Edit `tests/unit/SyncStandards.Tests.ps1`
2. Add new `Describe` or `Context` blocks
3. Use dot sourcing with `-TestMode` to load real functions
4. Test functions with explicit parameters

### For Binding Scripts
1. Choose appropriate test file:
   - `Generate-Bindings-DotNet.Tests.ps1` for binding generation
   - `Generate-NuGets-DotNet.Tests.ps1` for NuGet packaging
   - `Helpers.Tests.ps1` for shared utilities
2. Add test scenarios with proper mocking strategy
3. Use existing fixtures or create new .csproj files in `tests/fixtures/`

### For Integration Tests
1. Edit `tests/integration/SyncStandards.Integration.Tests.ps1`
2. Create additional fixtures in `tests/fixtures/` if needed
3. Use temporary workspaces to avoid side effects

### Best Practices
- **Isolation**: Each test should be independent with proper cleanup
- **Descriptive names**: Tests that explain what they verify
- **Mock strategy**: Mock external dependencies, test real logic
- **Fixture reuse**: Use existing .csproj files where possible
- **Error scenarios**: Include both happy path and edge cases
- **Version validation**: Test NuGet semantic versioning edge cases
- **CI/CD compatibility**: Avoid interactive prompts in parameter validation

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