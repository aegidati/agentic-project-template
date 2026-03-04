# Agentic Workflow

## Overview
This document defines the development workflow using agentic assistance (GitHub Copilot agents, custom agents, and planning modes).

## Feature Development Lifecycle

### Phase 1: REQUEST
**Owner**: Product / Feature Lead  
**Artifact**: `docs/features/<FEATURE-NAME>/00-REQUEST.md`

- Describe the user story, acceptance criteria, and constraints.
- No technical decisions yet.

### Phase 2: PLAN
**Owner**: Architect / Tech Lead (with Agent: Plan Mode)  
**Artifact**: `docs/features/<FEATURE-NAME>/01-PLAN.md`

- Define technical approach, dependencies, and design decisions.
- Identify ADR implications.
- Create implementation task breakdown.

### Phase 3: TEST STRATEGY
**Owner**: QA / Developer (with Agent: Test Designer)  
**Artifact**: `docs/features/<FEATURE-NAME>/02-TEST-STRATEGY.md`

- Define test scope, test cases, and coverage targets.
- Identify edge cases and failure modes.

### Phase 4: IMPLEMENTATION
**Owner**: Developer (with Agent: Feature Orchestrator)  
**Artifact**: `docs/features/<FEATURE-NAME>/03-IMPLEMENTATION-LOG.md`

- Execute development according to plan.
- Log key decisions and blockers.
- Maintain alignment with test strategy.

### Phase 5: LOCK
**Owner**: Tech Lead  
**Artifact**: `docs/features/<FEATURE-NAME>/04-LOCK.md`

- Sign-off when feature meets Definition of Done.
- Document lessons learned and deviations from plan.

## Modification Workflow

For changes to existing features:  
**Artifact**: `docs/features/<FEATURE-NAME>/MOD-XX-<SHORT-TITLE>.md`

- Document change scope and impact analysis.
- Ensure minimal ripple effects.
- Follow CHANGE-MANAGEMENT rules.

## Agent Roles

| Agent | Primary Responsibility |
|-------|------------------------|
| **feature-orchestrator** | Coordinate feature execution, enforce lifecycle discipline |
| **architecture-guardian** | Validate architectural decisions, guard ADRs |
| **test-designer** | Define and validate test strategies |
| **ux-navigator** | Ensure UX consistency and design adherence |
| **documentation-guardian** | Maintain docs quality and completeness |

## Process Guardrails

- **No implementation without REQUEST + PLAN**.
- **No code review without TEST-STRATEGY**.
- **No modification without MOD document**.
- **ADRs are constraints**: All technical decisions must respect existing ADRs.

## Language Requirements

- All process and technical documentation: **English**.
- Code: **English**.
- See [LANGUAGE-POLICY.md](./LANGUAGE-POLICY.md) for details.
