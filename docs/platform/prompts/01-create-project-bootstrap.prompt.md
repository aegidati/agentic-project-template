# Prompt 01 - Create Project Bootstrap

## Context
Create the project bootstrap manifest from template defaults.

## Prompt To Run In Copilot Chat
Create PROJECT-BOOTSTRAP.yaml from PROJECT-BOOTSTRAP.example.yaml. Keep schema and keys unchanged. Use `project.profile` as the recommended default starter selection mechanism, and use `starters:` only for explicit manual overrides. Keep unselected manual overrides as `repo: null`. Do not add business-specific fields.

## Done Criteria
1. PROJECT-BOOTSTRAP.yaml exists at repository root.
2. Manifest schema matches template format.
3. `project.profile` is set when using profile-first bootstrap.
4. `starters:` is used only for explicit overrides; unselected overrides remain `repo: null`.
