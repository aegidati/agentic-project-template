PROJECT BOOTSTRAP – AGNOSTIC AGENTIC TEMPLATE (Architecture-ready)

Context
I am building an "agnostic" repository template for agentic development with GitHub Copilot (Chat, Plan, Agent, custom agents).
This template must NOT impose a specific technical architecture (no framework or stack assumptions), but it MUST be organized so that any derived project can easily add an architecture via "starter packs" and then evolve with ADR-driven governance.

Core goals
- Provide a reusable, stack-agnostic baseline repository template.
- Encode the development process (documentation lifecycle, governance, agents).
- Make the derived project "architecture-ready":
  - A clear place to install an architecture starter pack (files, directories, minimal scaffold).
  - A clear ADR-based mechanism to formalize the chosen architecture.
  - A clean separation between process docs and app code.

Language policy
- Brainstorming/idea input may be in Italian.
- All technical documentation under docs/ must be written in English.
- Domain/entity/class/file names in English.
- Code always in English.

Repository structure requirements (template)
The template repository must contain:

1) Governance & workflow (process)
docs/governance/
  PROJECT-CONSTITUTION.md
  AGENTIC-WORKFLOW.md
  DEFINITION-OF-DONE.md
  CHANGE-MANAGEMENT.md                 # rules for modifying existing features safely
  LANGUAGE-POLICY.md                   # optional but recommended

2) Feature lifecycle (per-feature docs)
docs/features/<FEATURE-NAME>/
  00-REQUEST.md
  01-PLAN.md
  02-TEST-STRATEGY.md
  03-IMPLEMENTATION-LOG.md
  04-LOCK.md

For epics:
docs/features/<EPIC-NAME>/
  <EPIC-NAME>-EPIC-00-REQUEST.md

3) Architecture readiness (this is NEW / important)
docs/architecture/
  ARCHITECTURE-ONBOARDING.md           # how to adopt an architecture in a derived project
  ARCHITECTURE-REQUIREMENTS.md         # non-stack requirements: layering, dependency rules, naming conventions, etc.
  STARTER-PACKS.md                     # how to select/install starter packs
  ARCHITECTURE-SNAPSHOT.md             # current architecture snapshot (high-level)

docs/adr/
  ADR-INDEX.md
  ADR-TEMPLATE.md                      # template for new ADRs
  (no concrete architecture ADRs in the template, only templates/guidelines)

4) Routing & UX (stack-agnostic)
docs/routing/
  ROUTING-MAP.md                       # conceptual routes + guards (agnostic)

docs/ux/
  UX-GUIDELINES.md                     # UX principles and patterns (agnostic)

5) Domain templates (optional but useful)
docs/domain-templates/
  CUSTOMERS/
    DOMAIN-MODEL.md
    FEATURES-CATALOG.md
    ADR-SEEDS.md                       # optional: suggested ADRs for this domain

6) Starter packs integration point (derived project)
The derived project must have a clear place where starter packs are installed.
We will reserve:
starters/                              # metadata / references (NOT the app code itself)
  README.md                            # explains available starter packs and installation method

And a reserved app root folder:
app/                                   # the folder where the chosen architecture starter pack will be installed
                                      # (backend/, frontend/, mobile/ may be added by a starter pack; keep 'app/' as stable anchor)

Notes:
- The template should NOT include actual app code.
- The 'app/' folder can be empty in the template, but must exist as the canonical location for architecture installation.

7) Custom agents (versioned in repo)
.github/agents/
  feature-orchestrator.agent.md
  architecture-guardian.agent.md
  ux-navigator.agent.md
  test-designer.agent.md
  documentation-guardian.agent.md
  (optional) domain-template.agent.md

Custom agents must:
- follow docs/governance/* rules
- treat docs/adr/* as authoritative constraints
- produce/maintain docs/features/* lifecycle artifacts

Starter packs concept
Starter packs are separate repositories (or separate folders in a dedicated starters repo) that provide:
- initial directory structure under app/
- minimal scaffolding (hello world / health check)
- optionally an initial ADR-001 for that architecture (or instructions to generate it)

Installation methods allowed (choose one later):
- Copy/paste (simple)
- git subtree (recommended for updatable starter packs)
- script-based bootstrap (optional)

The template must document how to do this (docs/architecture/STARTER-PACKS.md) but must not require a specific method.

Development workflow expectations (in derived projects)
- Architecture selection happens before implementing real features:
  1) Install starter pack into app/
  2) Create/accept ADR-001-ARCHITECTURE-STRATEGY.md (project-specific)
  3) Update docs/architecture/ARCHITECTURE-SNAPSHOT.md
  4) Only then start building features

Feature work:
- Plan before code:
  REQUEST → PLAN (Plan mode) → TEST STRATEGY → Implementation (Agent mode) → LOCK
- For modifications to existing features, require a "MOD" doc:
  docs/features/<FEATURE>/MOD-XX-<SHORT-TITLE>.md
  and follow a minimal-impact plan.

Session objective (what I want from you)
Guide me step-by-step to build this template repository:
1) Create the folder structure and initial placeholder files.
2) Generate the initial content for core governance docs:
   - PROJECT-CONSTITUTION.md
   - AGENTIC-WORKFLOW.md
   - DEFINITION-OF-DONE.md
   - CHANGE-MANAGEMENT.md
3) Generate architecture-readiness docs:
   - ARCHITECTURE-ONBOARDING.md
   - ARCHITECTURE-REQUIREMENTS.md
   - STARTER-PACKS.md
   - ARCHITECTURE-SNAPSHOT.md (empty template + rules)
4) Define the custom agents set in .github/agents/ with minimal, stable instructions.
5) Ensure everything remains stack-agnostic and ready to receive a chosen architecture in app/.

Important constraints
- Do NOT generate real application code.
- All docs/ content must be in English and copy-ready.
- Prefer minimal, enforceable rules over long prose.
- Keep naming and structure consistent and future-proof.