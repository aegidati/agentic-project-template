# App Directory

This is the **canonical location** where architecture starter packs are installed.

## Installation

In derived projects:

1. Choose a starter pack from [starters/README.md](../starters/README.md)
2. Install using one of these methods:

### Option 1: Git Subtree (Recommended)
```bash
git subtree add --prefix app/ <STARTER-PACK-URL> <BRANCH>
```

### Option 2: Copy/Paste
```bash
cp -r <starter-pack>/* app/
```

### Option 3: Script-Based
```bash
./scripts/bootstrap.sh --starter-pack <NAME>
```

See [docs/architecture/STARTER-PACKS.md](../docs/architecture/STARTER-PACKS.md) for detailed instructions.

## What Goes Here?

After installation, `app/` contains:
- Language-specific project structure (src/, tests/, etc.)
- Build configuration (package.json, pom.xml, .csproj, etc.)
- Minimal working example (health check, hello world)
- Initial ADR recommendations

## Important Rules

✓ **Do**: Keep `app/` structure clean and respect starter pack conventions  
✓ **Do**: Document changes to `app/` structure in ADRs  
✗ **Don't**: Store this directory in version control before starter pack selection  
✗ **Don't**: Mix multiple starter packs in one `app/`  

## Ownership

- **Template**: This directory is reserved by the template
- **Derived project**: You own everything in `app/` after installation
- **Updates**: You choose whether to update starter pack versions

---

**Status**: Empty in template (to be populated in derived projects)

See: [docs/architecture/ARCHITECTURE-ONBOARDING.md](../docs/architecture/ARCHITECTURE-ONBOARDING.md)
