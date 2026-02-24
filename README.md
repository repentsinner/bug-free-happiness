# bug-free-happiness

Reusable GitHub Actions workflows for documentation quality enforcement.

## Installation

Add a caller workflow to your repo (e.g. `.github/workflows/spec-lint.yml`):

```yaml
name: Spec Lint

on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    uses: repentsinner/bug-free-happiness/.github/workflows/spec-lint.yml@v1
```

## Usage

### Inputs

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `readme-type` | string | `""` | `library`, `application`, or `""` (skip) |

### README heading validation

Pass `readme-type` to enable heading checks:

```yaml
jobs:
  lint:
    uses: repentsinner/bug-free-happiness/.github/workflows/spec-lint.yml@v1
    with:
      readme-type: library
```

### What gets checked

1. **Markdownlint** — enforced via `DavidAnson/markdownlint-cli2-action`
2. **SPEC.md status lines** — every numbered section needs a `*Status:` line
3. **README headings** (opt-in) — required H2 headings per project type

## API

### `spec-lint.yml`

Reusable workflow (`workflow_call`).

**Inputs:**

- `readme-type` (string, optional) — heading validation profile.
  `library` requires: Installation, Usage, API, License.
  `application` requires: Getting Started, Usage, License.
  Empty string skips heading validation.

**Outputs:** none. Errors surface as GitHub annotations.

### Heading synonym patterns

| Heading | Accepted synonyms |
|---------|-------------------|
| License | license, licensing, licensing note |
| Installation | installation, install, getting started, quick start |
| Usage | usage |
| API | api, api reference |
| Getting Started | quick start, getting started, installation, install |

## License

MIT
