# Prompt 02 - Install Starters

## Context
Install only selected starters using deterministic canonical paths.

Use the official hardened script `scripts/install-starters.ps1` for runtime starter installation.

## Prompt To Run In Copilot Chat
Run the official hardened installer script `scripts/install-starters.ps1` for step 02. Resolve starters from `PROJECT-BOOTSTRAP.yaml` profile-first via `profiles.<profile>.starters`, then apply explicit overrides from `starters.*.repo`. Install only slots where `repo != null`, use only canonical runtime paths `app/backend`, `app/web`, `app/client`, `app/contracts`, `app/infra`, `app/composition`, classify non-empty target collisions as `SKIP` with `collision=yes` without overwrite or delete, use temp cleanup based on `[System.IO.Path]::GetTempPath()` with `Test-Path -LiteralPath` and `Remove-Item -LiteralPath` inside `finally`, keep cleanup non-blocking, and report per-slot results as JSON plus human-readable summary.

## Done Criteria
1. Selected starters are installed only to canonical paths.
2. Collisions are reported with non-destructive `SKIP` handling and `collision=yes`.
3. Resolution order is profile first, then manual overrides.
4. Installation order is fixed: `contracts`, `backend`, `web`, `client`, `infra`, `composition`.
5. Temp cleanup uses `Test-Path -LiteralPath`, `Remove-Item -LiteralPath`, and a `finally` block, and cleanup failures do not flip a successful slot to `FAIL`.
6. A per-slot installation report is produced with `slot`, `repo`, `path`, `result`, `collision`, and `reason`.
7. The final output includes both machine-readable JSON and a human-readable summary.

## Optional Foundation Adoption

### Prompt To Run In Copilot Chat (Foundation)
Adopt agentic-iam as an optional foundation starter using manual copy or subtree-vendor (docs + governance artifacts). Do not install it into runtime canonical paths: app/backend, app/web, app/client, app/contracts, app/infra, app/composition. Report adopted files, collisions, and unresolved decisions.

### Additional Done Criteria
5. If foundation adoption is requested, report explicit confirmation that no runtime canonical app/* path was used.
6. Foundation collisions are reported without destructive overwrite.
