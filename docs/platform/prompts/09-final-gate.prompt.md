# Prompt 09 - Final Gate

## Context
Run final readiness gate before normal feature delivery starts.

## Prompt To Run In Copilot Chat
Run a final gate and declare READY or NOT READY. Validate structure, documentation consistency, canonical starter paths unchanged (app/backend, app/web, app/client, app/contracts, app/infra, app/composition), optional foundation adoption consistency, no foundation starter forced into runtime slots, and post-install validation outcomes.

## Done Criteria
1. Final gate result is declared as READY or NOT READY.
2. Blocking issues are listed if NOT READY.
3. Immediate next action is proposed.
4. If foundation starters are adopted, adoption is documented and runtime canonical app/* slots remain unchanged.
