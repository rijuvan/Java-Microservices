# Java Compile & POM Dependency Fix Agent

A Claude-powered GitHub Actions agent that automatically detects and fixes:

- **Java compile-time errors** — `javax→jakarta` migration, removed Spring Boot 3.x APIs, missing imports, type mismatches
- **POM dependency issues** — missing dependencies, version conflicts, unused declarations, deprecated artifact coordinates

## Workflow file

`.github/workflows/java-compile-pom-fix.yml`

## Triggers

| Trigger | When |
|---------|------|
| Manual (`workflow_dispatch`) | Run on demand from GitHub Actions UI |
| Push to `master` | Any change to `pom.xml` or Java source files |
| Pull Request | Same file paths as push |

## Manual inputs

| Input | Options | Default | Description |
|-------|---------|---------|-------------|
| `service` | `all`, `fares`, `search`, `book`, `checkin`, `website` | `all` | Which service to fix |
| `fix_type` | `both`, `compile-errors`, `pom-dependencies` | `both` | Scope of fixes |

## How it works

1. **detect-build-errors** job — runs `mvn clean compile` across all services, records which ones fail
2. **fix-compile-and-pom** job — Claude agent reads source + POM files, applies targeted fixes, re-verifies with `mvn clean compile`, then opens a PR

## Required secret

`CLAUDE_CODE_OAUTH_TOKEN` — set in **Settings → Secrets → Actions** on GitHub.

## What the agent will NOT change

- Spring Boot parent version
- Hardcoded `localhost:808x` service URLs (intentional, no service discovery)
- H2 in-memory database setup
- `.github/` workflow files themselves
