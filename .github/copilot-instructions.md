# Agentic Platform Repository Instructions

This repository follows a modular AI-native platform structure based on:

- AGENTIC-TEMPLATE
- official architecture starters
- documentation-first development
- deterministic project assembly

## Official project structure

app/
  backend/
  web/
  client/
  infra/
  contracts/
  composition/

docs/
.github/

## Platform rules

- Starters must be installed only into their official target paths.
- Do not invent alternative paths.
- Preserve clear ownership boundaries between modules.
- Prefer minimal changes over broad refactoring.
- Keep starter installation deterministic and reversible when possible.
- Do not add business-specific functionality during starter installation.

## Starter IDs and target paths

- agentic-clean-backend -> app/backend
- agentic-react-spa -> app/web
- agentic-flutter-client -> app/client
- agentic-api-contracts-api -> app/contracts
- agentic-postgres-dev -> app/infra
- agentic-fullstack-composition -> app/composition

## Documentation-first behavior

Before changing the project structure:
1. inspect existing project layout
2. inspect starter manifest and audit files
3. explain intended target paths
4. perform minimal safe changes
5. summarize post-install validation

## Change policy

When installing or updating starters:
- avoid destructive overwrites
- report collisions explicitly
- preserve existing project conventions if compatible with the platform
- prefer transparent file operations
