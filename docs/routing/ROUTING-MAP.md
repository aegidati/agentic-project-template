# Agent Routing

This document defines how requests should be routed across the AI agents of the Agentic development platform.

The goal is to ensure that each request is handled by the most appropriate agent, while preserving architecture integrity, documentation quality, testing discipline, and UX consistency.

---

# 1. Routing Principles

Requests must be routed to the agent that owns the primary responsibility for the problem.

If the request affects multiple areas, one agent becomes the primary agent and may consult supporting agents.

Agents must not override responsibilities owned by another agent.

---

# 2. Primary Routing Table

## Starter installation and project assembly

Primary agent:

- starter-installer

Use when:

- installing one or more official starters
- assembling a new project from the template
- checking starter path conflicts
- validating project structure after starter installation

Supporting agents:

- architecture-guardian
- documentation-guardian

---

## Feature planning and lifecycle coordination

Primary agent:

- feature-orchestrator

Use when:

- starting a new feature
- converting a request into a plan
- coordinating feature lifecycle phases
- checking whether workflow phases are missing

Supporting agents:

- architecture-guardian
- test-designer
- documentation-guardian
- ux-navigator
- domain-template

---

## Architecture validation and ADR decisions

Primary agent:

- architecture-guardian

Use when:

- evaluating architecture impact
- deciding whether an ADR is needed
- checking architecture consistency
- reviewing structural changes
- validating module boundaries

Supporting agents:

- feature-orchestrator
- starter-installer
- domain-template

---

## Documentation review and completeness

Primary agent:

- documentation-guardian

Use when:

- reviewing documentation quality
- checking documentation completeness
- validating feature docs
- checking change documentation
- reviewing release readiness from a documentation perspective

Supporting agents:

- feature-orchestrator
- architecture-guardian
- test-designer

---

## Test strategy and coverage planning

Primary agent:

- test-designer

Use when:

- defining test strategy
- proposing test cases
- checking whether acceptance criteria are testable
- validating Definition of Done from a testing perspective

Supporting agents:

- feature-orchestrator
- architecture-guardian
- ux-navigator

---

## UX review and navigation consistency

Primary agent:

- ux-navigator

Use when:

- reviewing user flows
- checking navigation consistency
- validating UI/UX decisions
- identifying UX regressions

Supporting agents:

- feature-orchestrator
- documentation-guardian

---

## Domain modeling and bounded context templates

Primary agent:

- domain-template

Use when:

- defining a new domain module
- creating a bounded context structure
- proposing domain entities and aggregates
- extending domain templates

Supporting agents:

- architecture-guardian
- feature-orchestrator

---

# 3. Escalation Rules

Escalate to architecture-guardian when:

- a request changes system structure
- a request introduces a new module or boundary
- a request may require an ADR

Escalate to documentation-guardian when:

- a request changes project rules
- a request modifies workflow or architecture decisions
- a request introduces new feature behavior that must be documented

Escalate to test-designer when:

- acceptance criteria are unclear
- testability is uncertain
- Definition of Done validation is required

Escalate to ux-navigator when:

- UI flows change
- navigation changes
- user-facing interactions are affected

Escalate to domain-template when:

- new domain concepts are introduced
- a new bounded context is needed
- domain language becomes inconsistent

---

# 4. Routing by Request Pattern

Use starter-installer for requests like:

- install agentic-clean-backend
- add react starter
- assemble backend + web + infra + composition
- verify starter compatibility
- detect starter conflicts

Use feature-orchestrator for requests like:

- plan this feature
- create the implementation workflow
- generate a feature plan
- check missing lifecycle steps

Use architecture-guardian for requests like:

- do we need an ADR?
- validate architecture impact
- review this structural change
- check if this violates architecture rules

Use documentation-guardian for requests like:

- review documentation completeness
- check which docs are missing
- validate feature documentation
- prepare docs for release

Use test-designer for requests like:

- define test strategy
- propose test cases
- validate acceptance criteria
- check Definition of Done from a testing perspective

Use ux-navigator for requests like:

- review navigation flow
- validate UX consistency
- check user journey coherence
- inspect UX regressions

Use domain-template for requests like:

- propose a domain model
- create a bounded context template
- design domain structure for a new module

---

# 5. Authority Rules

If multiple agents are relevant, the following authority rules apply.

Project structure authority:

- starter-installer

Feature lifecycle authority:

- feature-orchestrator

Architecture authority:

- architecture-guardian

Documentation authority:

- documentation-guardian

Testing authority:

- test-designer

UX authority:

- ux-navigator

Domain modeling authority:

- domain-template

No agent should override the authority of another agent in its own responsibility area.

---

# 6. Default Multi-Agent Workflow

For a typical feature request, use this sequence:

1. feature-orchestrator
2. architecture-guardian
3. domain-template if domain changes are needed
4. test-designer
5. ux-navigator if user-facing changes are involved
6. documentation-guardian

For a new project assembly request, use this sequence:

1. starter-installer
2. architecture-guardian
3. documentation-guardian

---

# 7. Routing Constraints

- Do not use governance agents for starter installation.
- Do not use starter-installer for feature planning.
- Do not use documentation-guardian as architecture authority.
- Do not use ux-navigator for backend-only changes unless there is a user-facing impact.
- Do not use domain-template for implementation details outside domain modeling.