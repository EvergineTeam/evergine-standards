# Evergine standards

[![CI](https://github.com/EvergineTeam/evergine-standards/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/EvergineTeam/evergine-standards/actions/workflows/ci.yml)

Shared standards and static assets for Evergine repositories — including the NuGet package icon, license file, and synchronization tools for keeping all repositories aligned.

---

## Overview

This repository centralizes **build standards** shared across all Evergine repositories.  
Its purpose is to ensure consistency and reduce maintenance overhead caused by duplicated scripts, templates, and configuration files.

Typical consumers include:
- Core libraries published as NuGet packages.
- Satellite tools and prefabs distributed in separate repositories.
- Future repositories that should automatically stay aligned with global standards.

---

## Repository structure

```
/
├─ LICENSE                       # Canonical license file
├─ assets/
│  └─ nuget-icon.png             # Official NuGet package icon (512x512)
├─ tools/
│  └─ sync-standards.ps1         # Synchronization script (PowerShell 7+)
├─ workflows/
│  ├─ sync-wrapper.yml           # Template workflow for consumer repos
│  └─ _sync-standards-reusable.yml # Reusable GitHub Actions workflow
└─ sync-manifest.json            # Manifest defining which files to sync
```

---

## Synchronization workflow

Evergine repositories can automatically stay up to date with shared files using the provided **GitHub Actions** workflow.

### 1. Reusable workflow (centralized)

The reusable workflow is defined here:

```
.github/workflows/_sync-standards-reusable.yml
```

It handles the synchronization logic:
- Downloads and applies the manifest (`sync-manifest.json`).
- Uses the PowerShell script `tools/sync-standards.ps1`.
- Detects changes.
- Commits or opens a Pull Request (depending on protection rules).

Repositories consume it using:

```yaml
uses: EvergineTeam/evergine-standards/.github/workflows/_sync-standards-reusable.yml@main
```

> The reusable workflow executes **in the context of the target repository**, not in `evergine-standards`.

---

### 2. Wrapper workflow (per repository)

Each repository includes a lightweight wrapper (synchronized via the manifest):

```yaml
name: Sync standards

on:
  workflow_dispatch:
  schedule:
    - cron: "0 2 1 * *"  # First day of the month at 02:00 UTC

jobs:
  sync:
    uses: EvergineTeam/evergine-standards/.github/workflows/_sync-standards-reusable.yml@main
    with:
      org:  "EvergineTeam"
      repo: "evergine-standards"
      ref:  "main"
      target_branch: "main"
      commit_message: "auto: sync standard files [skip ci]"
      mode: "auto"
    secrets: inherit
```

This wrapper can be customized (e.g., cron schedule or target branch).  
If you customize it, you can prevent future overwrites using a `.standards.override.json` file.

### Parameters for the reusable workflow

The reusable workflow accepts the following parameters in the `with` section:

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `org` | Source GitHub organization | `EvergineTeam` | No |
| `repo` | Source repository name | `evergine-standards` | No |
| `ref` | Git reference (branch, tag, or SHA) | `main` | No |
| `target_branch` | Branch to apply changes to | `main` | No |
| `commit_message` | Custom commit message for changes | Uses `STANDARDS_COMMIT_MESSAGE` variable or default fallback | No |
| `mode` | Commit strategy: `auto` (push then PR if needed) or `pr` (always PR) | `auto` | No |

> **Note:** For `commit_message`, the workflow uses a priority fallback system:
> 1. Explicit `commit_message` parameter (if provided)
> 2. `STANDARDS_COMMIT_MESSAGE` organization/repository variable (if defined)
> 3. Default: `"auto: sync standard files [skip ci]"`
> 
> The `STANDARDS_COMMIT_MESSAGE` variable can be defined at organization level and overridden per repository in Settings → Secrets and variables → Actions → Variables tab.

---

## Synchronization script (`tools/sync-standards.ps1`)

The PowerShell script performs the actual synchronization.

### Usage
```bash
pwsh ./tools/sync-standards.ps1 [-Org EvergineTeam] [-Repo evergine-standards] [-Ref main]
```

Optional parameters:
| Parameter | Description |
|------------|-------------|
| `-Org` | Source GitHub organization (default: `EvergineTeam`) |
| `-Repo` | Source repository (default: `evergine-standards`) |
| `-Ref` | Git reference (branch, tag, or SHA; default: `main`) |
| `-SourcePath` | Local folder instead of remote source (for local testing) |
| `-DryRun` | Prints actions without writing files |

The script:
1. Loads the `sync-manifest.json`.
2. Applies optional per-repository overrides.
3. Downloads and writes the corresponding files.
4. Reports updated and ignored items.

> The script never commits or pushes.  
> Commits are performed by the GitHub Actions workflow.

---

## Manifest format (`sync-manifest.json`)

The manifest defines which files are distributed to all repositories:

```json
{
  "schema": "1",
  "files": [
    { "src": "LICENSE", "dst": "LICENSE" },
    { "src": "assets/nuget-icon.png", "dst": "assets/nuget-icon.png" },
    { "src": "tools/sync-standards.ps1", "dst": "tools/sync-standards.ps1" },
    { "src": "workflows/sync-wrapper.yml", "dst": ".github/workflows/sync-standards.yml", "overwrite": "ifMissing" }
  ]
}
```

- `src`: Path in this repository.  
- `dst`: Destination path in the target repository.  
- `overwrite`:  
  - `"always"` → Replace existing files (default).  
  - `"ifMissing"` → Create only if the file does not exist (used for local customization).

---

## Overrides (`.standards.override.json`)

Each repository can define exceptions and remappings:

```json
{
  "schema": "1",
  "remap": {
    ".github/workflows/sync-standards.yml": {
      "dst": ".github/workflows/sync-standards-custom.yml",
      "overwrite": "ifMissing"
    },
    "assets/nuget-icon.png": "src/Branding/nuget-icon.png"
  },
  "ignore": [
    "LICENSE"
  ]
}
```

- **`remap`**  
  - Key = `src` or `dst` (from manifest).  
  - Value = new destination (string) or object `{ dst, overwrite }`.
- **`ignore`**  
  - Exact list of paths to skip (no wildcards).

---

## Local testing

You can test the sync locally without CI:

```bash
pwsh ./tools/sync-standards.ps1 -SourcePath "../evergine-standards" -DryRun
```

This simulates the synchronization using your local checkout instead of downloading from GitHub.

---

## Summary

| Component | Role |
|------------|------|
| `sync-manifest.json` | Defines which files are synchronized |
| `tools/sync-standards.ps1` | Performs synchronization (PowerShell) |
| `_sync-standards-reusable.yml` | Core reusable workflow |
| `sync-wrapper.yml` | Template workflow copied to each repo |
| `.standards.override.json` | Per-repo customization |

---

> **Maintainers:**  
> This repository should remain minimal and versioned carefully — avoid including secrets, credentials, or environment-specific files.
