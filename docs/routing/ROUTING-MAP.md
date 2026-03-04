# Routing Map

This document defines the **conceptual routes and navigation paths** for the application in a stack-agnostic way.

## Purpose

- Define user/system flows at a conceptual level
- Independent of specific framework or URL structure
- Guides API design, UI navigation, and workflow orchestration
- Updated as features are added

## Route Categories

### Administrative Routes
**Purpose**: System configuration and management

| Route | Purpose | Guards | Notes |
|-------|---------|--------|-------|
| (Examples to be added in derived project) | | | |

### User/Domain Routes
**Purpose**: Core business workflows

| Route | Purpose | Guards | Notes |
|-------|---------|--------|-------|
| (Examples to be added in derived project) | | | |

### Public Routes
**Purpose**: Unauthenticated access

| Route | Purpose | Guards | Notes |
|-------|---------|--------|-------|
| (Examples to be added in derived project) | | | |

## Route Guards

**Guards** are conditions that control access:
- **Authentication**: User must be logged in
- **Authorization**: User must have specific role/permission
- **Feature flag**: Feature must be enabled
- **Rate limit**: Request rate limits apply
- **Validation**: Input validation required

## Routing Patterns

### Agnostic Patterns

- **Hierarchical resources**: `/parent/{id}/child/{id}`
- **RESTful conventions**: `GET`, `POST`, `PUT`, `DELETE`
- **Query parameters**: For filtering, pagination, sorting
- **Versioning**: `v1/`, `v2/` if needed

### Stack-Specific Implementation

Each starter pack will define how these agnostic patterns map to:
- REST endpoint structure
- GraphQL queries/mutations
- RPC method names
- gRPC service definitions

## Navigation Flow (Example Template)

```
START
  ↓
[Unauthenticated Routes]
  ├→ Home
  ├→ Login
  └→ Public Docs
  ↓
[Authenticate]
  ↓
[Authenticated Routes]
  ├→ Dashboard
  ├→ User Profile
  └→ Domain Features
  ↓
[Authorization Checks]
  ├→ Admin Routes (if admin)
  └→ Standard User Routes
  ↓
END
```

---

**To populate**: Add specific routes after architecture and first features are defined.
