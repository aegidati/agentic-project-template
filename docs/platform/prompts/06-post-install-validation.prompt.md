# Prompt 06 - Post Install Validation

## Context
Run starter-aware checks and confirm bootstrap integrity.

## Prompt To Run In Copilot Chat
Run validation using scripts/run-checks.cmd and scripts/postinstall-checks.ps1. Provide per-check and per-starter PASS/FAIL/SKIP results, classify not-applicable checks as SKIP with reason, and summarize unresolved blockers. If either script is missing, generate and validate an equivalent safe check workflow before reporting results.

## Done Criteria
1. Validation executes from repository root.
2. PASS/FAIL/SKIP results are reported per check and per starter.
3. No unresolved FAIL remains, or blockers are explicitly reported.
