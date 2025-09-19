# AGENTS.md

This file provides guidance to AI coding assistants (WARP, Claude Code, etc.) when working with code in this repository.

## Repository Overview

OpenMetadata-Worker is a GitHub Actions automation repository that manages the continuous integration and deployment pipeline for OpenMetadata containers and infrastructure. This is not a traditional software application but rather a CI/CD orchestration system that mirrors, modifies, builds, and scans OpenMetadata releases.

## Core Architecture

### Repository Structure
- `.github/workflows/` - Main orchestration workflows numbered sequentially
- `src/` - Contains templates, modification scripts, and additional workflow definitions
- `reports/` - Generated security scan reports (gitignored)

### Workflow Pipeline Architecture
The repository operates as a sequential pipeline with clearly numbered steps:

1. **Step 0** (`00-update-om-version.yml`) - Version tracking and variable updates
2. **Step 1** (`01-mirror-repo-pull.yml`) - Mirror upstream OpenMetadata to local repository
3. **Step 2** (`02-copy-repo.yml`) - Copy mirror to working repository
4. **Step 3** (`03-modify-repo-matrix.yml`) - Matrix-based repository modifications for dev/prod environments
5. **Step 4** - Multi-stage build and scan processes:
   - `04-00-scan-containers.yml` - Security scanning with Mend
   - `04-01-scan-containers4_1.yml` - Enhanced container scanning
   - `04-02-01` through `04-02-04` - Docker container builds for Docker Hub
   - `04-03-01` through `04-03-04` - GitHub Container Registry builds

### Key Components

#### Repository Mirroring
- Mirrors `open-metadata/OpenMetadata` to `Jason-Clark-FG/OpenMetadata-Mirror`
- Copies mirror to working repo `Jason-Clark-FG/OpenMetadata-FG` 
- Uses custom mirror-action for SSH-based git operations

#### Docker Compose Modification Engine
- Located in `src/openmetadata-modify-compose.sh`
- Uses `yq` for comprehensive YAML manipulation of `docker-compose.yml`
- Extensive Docker Compose modifications in `03-modify-repo-matrix.yml`:
  - MySQL configuration with custom passwords, healthchecks, and init scripts
  - Elasticsearch security settings and version management
  - Ingestion service (Airflow) configuration with admin credentials
  - OpenMetadata server healthcheck adjustments
  - Service restart policies and dependency management

#### Security Scanning Integration
- Mend.io (formerly WhiteSource) for vulnerability scanning
- Docker Scout for container image analysis
- SARIF report generation and GitHub Security integration
- Retry logic for scan resilience

#### Matrix-Based Environment Management
- Dynamic matrix generation for DEV/PROD environments
- Branch-based configuration using repository variables
- Separate Elasticsearch version tracking per environment

## Common Development Commands

### Triggering Workflows Manually
```bash
# Trigger the full pipeline from step 0
gh workflow run "00-update-om-version.yml"

# Trigger individual steps for testing
gh workflow run "01-mirror-repo-pull.yml"
gh workflow run "02-copy-repo.yml" 
gh workflow run "03-modify-repo-matrix.yml"

# Trigger container builds
gh workflow run "04-02-01-build-container1.yml"  # MySQL container
gh workflow run "04-02-02-build-container2.yml"  # Ingestion container
gh workflow run "04-02-03-build-container3.yml"  # Server container
```

### Repository Variables
Key variables that control the pipeline:
- `OM_LATEST_RELEASE` - Latest OpenMetadata release version
- `DEV_RELEASE_BRANCH`/`PROD_RELEASE_BRANCH` - Target branches
- `DEV_ES_RELEASE_BRANCH`/`PROD_ES_RELEASE_BRANCH` - Elasticsearch versions
- `FG_COMPOSE_TARGET` - Target docker-compose file path
- `BRANCH_SUFFIX` - Suffix for working branches

```bash
# View current repository variables
gh variable list
```

### Local Testing
```bash
# Test compose modification script locally
cd src/
chmod +x openmetadata-modify-compose.sh
./openmetadata-modify-compose.sh

# Manual yq operations for testing compose changes
yq '.services | keys' docker-compose.yml
yq '.services.mysql.environment' docker-compose.yml
```

### Monitoring Pipeline Status
```bash
# Check workflow run status
gh run list --workflow="00-update-om-version.yml"
gh run list --workflow="03-modify-repo-matrix.yml"

# View logs for failed runs
gh run view <run-id> --log
```

## Environment Configuration

### Required Repository Secrets
- `DOCKER_USER` / `DOCKER_PAT` - Docker Hub credentials
- `GIT_SSH_PRIVATE_KEY` / `GIT_SSH_PUBLIC_KEY` - SSH keys for repository access
- `MEND_EMAIL` / `MEND_USER_KEY` - Mend.io scanning credentials
- `REPO_TOKEN` - GitHub token for API operations

### Repository Variables Pattern
Variables follow a clear naming convention:
- `*_RELEASE_BRANCH` - Git branch names
- `*_RELEASE_NAME` - Human-readable release names  
- `FG_*` - FG-specific configuration
- `DEV_*` / `PROD_*` - Environment-specific settings

## Development Patterns

### Adding New Container Builds
1. Copy existing build workflow (e.g., `04-02-01-build-container1.yml`)
2. Update `IMAGE_BASENAME`, `IMAGE_FILE`, and container-specific settings
3. Add corresponding GHCR workflow in `04-03-*` series
4. Update build matrix if needed

### Modifying Docker Compose Transformations
1. Edit yq commands in `03-modify-repo-matrix.yml`
2. Test modifications in `src/openmetadata-modify-compose.sh` first
3. Consider both DEV and PROD environment variations
4. Ensure healthcheck and dependency modifications are compatible

### Security Scan Configuration
Security scanning is handled through multiple workflows with Mend.io integration and Docker Scout analysis. Update image lists in scan workflows and ensure SARIF output is properly configured for GitHub Security integration.

## Troubleshooting Common Issues

### Workflow Dependencies
- Workflows are strictly sequential and depend on `workflow_run` success
- Manual `workflow_dispatch` bypasses dependency checks
- Check for race conditions in matrix builds

### Git Operations
- SSH key configuration is critical for mirror operations  
- Repository permissions must allow force pushes to working branches
- Branch protection rules may interfere with automated commits

### Container Builds
- Docker buildx cache issues can cause build failures
- Registry permissions must allow both push and pull operations
- Multi-architecture builds may timeout on resource constraints

## Important Notes

- Workflows depend strictly on `workflow_run` success and are sequential
- Manual `workflow_dispatch` bypasses dependency checks
- SSH key configuration is critical for mirror operations
- Repository permissions must allow force pushes to working branches
- All Docker Compose modifications use `yq` for YAML processing
- The system handles multi-architecture builds and registry operations