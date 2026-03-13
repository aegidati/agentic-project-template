# Prompt 02 - Install Starters

## Context
Install only selected starters using deterministic canonical paths.

## Prompt To Run In Copilot Chat
Install only the starters selected in PROJECT-BOOTSTRAP.yaml, using canonical target paths: app/backend, app/web, app/client, app/contracts, app/infra, app/composition. Report collisions without overwriting blindly and provide per-starter install status.

## Done Criteria
1. Selected starters are installed only to canonical paths.
2. Collisions are reported with non-destructive handling.
3. A per-starter installation status summary is produced.
