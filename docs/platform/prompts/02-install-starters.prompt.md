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

## Optional Foundation Adoption

### Prompt To Run In Copilot Chat (Foundation)
Adopt agentic-iam as an optional foundation starter using manual copy or subtree-vendor (docs + governance artifacts). Do not install it into runtime canonical paths: app/backend, app/web, app/client, app/contracts, app/infra, app/composition. Report adopted files, collisions, and unresolved decisions.

### Additional Done Criteria
5. If foundation adoption is requested, report explicit confirmation that no runtime canonical app/* path was used.
6. Foundation collisions are reported without destructive overwrite.
