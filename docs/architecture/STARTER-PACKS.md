# Starter Packs

## What is a Starter Pack?

A **starter pack** is a pre-configured template that provides:
- A specific **technology stack** (language, framework, databases)
- **Initial directory structure** under `app/`
- **Minimal working example** (health check endpoint, hello world)
- **Suggested ADR-001** for architecture strategy
- **Build & run instructions**

## Available Starter Packs

> This section will be populated as starter packs are created.

| Starter Pack | Stack | Status | Repository |
|---|---|---|---|
| (To be added) | (To be added) | (To be added) | (To be added) |

**Examples of potential starter packs**:
- `.NET 8 Clean Architecture API`
- `Python FastAPI with AsyncIO`
- `Node.js Express with TypeScript`
- `Java Spring Boot Microservice`
- `React + Node.js Full Stack`

## How to Install a Starter Pack

### Option 1: Git Subtree (Recommended)

Provides easy updates if the starter pack evolves.

```bash
# Add starter pack to app/ folder
git subtree add --prefix app/ <STARTER-PACK-URL> <BRANCH>

# Example:
git subtree add --prefix app/ https://github.com/your-org/starter-dotnet main
```

After installation:
1. Verify `app/` contains the starter pack contents.
2. Update `docs/adr/ADR-001-ARCHITECTURE-STRATEGY.md` (see [ARCHITECTURE-ONBOARDING.md](./ARCHITECTURE-ONBOARDING.md)).
3. Commit the changes.

### Option 2: Copy/Paste

Simple manual approach for smaller projects.

```bash
# Download starter pack
git clone <STARTER-PACK-URL> temp-starter

# Copy contents to app/
cp -r temp-starter/* app/

# Clean up
rm -rf temp-starter

# Commit
git add app/
git commit -m "Install <STARTER-PACK-NAME>"
```

### Option 3: Script-Based Bootstrap

Some starter packs may provide a bootstrap script:

```bash
./scripts/bootstrap.sh --starter-pack <STARTER-NAME>
```

Consult the starter pack documentation for details.

## Creating Your Own Starter Pack

To create a starter pack for your team:

1. **Create a new repository**: `starter-<STACK-NAME>`
2. **Populate with**:
   - Minimal working project structure
   - `README.md` with setup instructions
   - `docs/ADR-001-ARCHITECTURE-STRATEGY.md` (template)
   - `.gitignore` for your stack
   - Optional: `scripts/bootstrap.sh` for automation
3. **Document**:
   - Technology choices and versions
   - How to update it when dependencies upgrade
   - Known limitations or choices
4. **Test**: Install it using one of the three methods above on a test repository.
5. **Add to registry**: Update this file with the new starter pack link.

## Example Starter Pack Structure

```
starter-dotnet/
├── README.md                          # Setup instructions
├── .gitignore                         # .NET-specific
├── src/
│   ├── Domain/                        # Business logic (framework-agnostic)
│   ├── Application/                   # Use cases
│   ├── Infrastructure/                # Database, external services
│   └── Api/                           # Controllers, HTTP layer
├── tests/
│   ├── Domain.Tests/
│   ├── Application.Tests/
│   └── Integration.Tests/
├── docs/
│   └── ADR-001-ARCHITECTURE-STRATEGY.md
└── scripts/
    └── bootstrap.sh                   # Optional setup helper
```

## Maintenance

**After installing a starter pack**:
- You own all code under `app/`.
- Updates to the starter pack are **your choice** (use `git subtree pull` if desired).
- Document any customizations in `docs/adr/`.

**Keep starter packs clean**:
- Starter packs must remain **generic** and **reusable**.
- Project-specific code should NOT be in the starter pack.
- If you create a variant, consider a new starter pack repository.

## Questions?

- Consult [ARCHITECTURE-ONBOARDING.md](./ARCHITECTURE-ONBOARDING.md) for setup guidance.
- Review [ARCHITECTURE-REQUIREMENTS.md](./ARCHITECTURE-REQUIREMENTS.md) for architectural standards.
- Create an issue if a starter pack is missing or needs improvement.
