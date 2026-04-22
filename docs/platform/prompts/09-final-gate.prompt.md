# Prompt 09 - Final Gate

## Context
Run final readiness gate before normal feature delivery starts.

## Prompt To Run In Copilot Chat
@feature-lifecycle-agent Run a final gate and declare READY or NOT READY. Validate structure, documentation consistency, canonical starter paths unchanged (app/backend, app/web, app/client, app/contracts, app/infra, app/composition), optional foundation adoption consistency, no foundation starter forced into runtime slots, and post-install validation outcomes.

If IAM and/or Authentication foundations are in scope, also validate Superadmin baseline coherence: platform-scope baseline documented separately from TenantRole, no foundation text implying implicit tenant-wide ownership, provider-agnostic signal normalization in Authentication guidance, and IAM-owned privileged resolution for platform-scope access.

Also validate ADR index consistency: scan docs/adr/ for concrete ADR-*.md files (excluding ADR-TEMPLATE.md and ADR-INDEX.md itself), then verify that each file is registered in docs/adr/ADR-INDEX.md with matching ID, title, status, date, and link. Report the following checklist:

ADR Index Consistency Checklist:
- [ ] All concrete ADR files are present in the index table
- [ ] No index row has placeholder status (_Template_) for an existing concrete ADR
- [ ] No index row has placeholder date (TBD) for an existing concrete ADR
- [ ] Each index link resolves to an existing file
- [ ] No index row exists without a corresponding file

## Done Criteria
1. Final gate result is declared as READY or NOT READY.
2. Blocking issues are listed if NOT READY.
3. Immediate next action is proposed.
4. If foundation starters are adopted, adoption is documented and runtime canonical app/* slots remain unchanged.
5. ADR index consistency checklist is reported with PASS/FAIL per item.
6. Any FAIL in the ADR checklist is listed as a blocker.
7. If IAM and/or Authentication foundations are in scope, Superadmin baseline coherence is reported as PASS/FAIL with explicit rationale.
8. Any FAIL in Superadmin baseline coherence is listed as a blocker.
