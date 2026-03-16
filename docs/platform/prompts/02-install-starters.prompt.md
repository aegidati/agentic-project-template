# Prompt 02 - Install Starters

## Context
Install only selected starters using deterministic canonical paths.

## Prompt To Run In Copilot Chat
Install starters from PROJECT-BOOTSTRAP.yaml using profile-first resolution: resolve from `project.profile` via `profiles.<profile>.starters`, then apply explicit overrides from `starters.*.repo`. Install only starters where `repo != null`, using canonical target paths: app/backend, app/web, app/client, app/contracts, app/infra, app/composition. Report collisions without overwriting blindly and provide per-starter install status.

## Done Criteria
1. Selected starters are installed only to canonical paths.
2. Collisions are reported with non-destructive handling.
3. Resolution order is profile first, then manual overrides.
4. A per-starter installation status summary is produced.
