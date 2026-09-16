# bug-free-happiness

The shared quality phase for Flywheel-managed repositories: fixed
required-check names, the summary jobs that emit them, per-stack
correctness workflows, and one ruleset template that every repository
applies unchanged.

Design and rationale live in [SPEC.md](SPEC.md). Remaining work lives in
[ROADMAP.md](ROADMAP.md).

## Where it sits

| Layer | Owner | Provides |
| --- | --- | --- |
| Release | Flywheel | versioning, auto-merge, `flywheel/conventional-commit` |
| Quality contract | this repository | `quality / <class>` names, summary jobs, correctness workflows, ruleset template |
| Governance | symphonize | the reusable governance lint behind `quality / governance` |

Only the quality phase gates a merge. Build and publish run after
release, where a branch ruleset has nothing to block
(§spec:pipeline-phases, §spec:stack-implementations).

## What it is not

- **Not part of Flywheel.** Flywheel leaves quality checks to adopters,
  so this contract lives outside it (§spec:pipeline-phases).
- **Not the governance-document schema.** That moved to symphonize, whose
  reusable governance lint replaces the schema workflow the `v0` and `v1`
  tags here still name (§spec:release-automation).

## Required checks

| Check | Passes when | Source |
| --- | --- | --- |
| `flywheel/conventional-commit` | the PR title is a conventional commit | the owner's Flywheel App |
| `quality / governance` | governance documents conform and markdown lints clean | GitHub Actions |
| `quality / correctness` | the change builds, static analysis passes, and tests pass | GitHub Actions |

Each source is pinned. A check that accepts any source also accepts a
commit status, which anyone with status write access can post without
running anything (§spec:quality-classes, §spec:ruleset-template).

## Installation

Add `.github/workflows/quality.yml` to the repository, with one summary
job per required `quality / <class>` check. Pin every action and
reusable workflow by commit SHA with the version as a trailing comment,
so Dependabot proposes each bump.

## Usage

Each summary job depends on every job in its class, always runs, and
fails when any of them failed or was cancelled. GitHub treats a skipped
required check as passing, so a summary job that skips lets a broken
change merge (§spec:summary-jobs).

```yaml
name: quality

on:
  pull_request:
  merge_group:

permissions:
  contents: read

jobs:
  classify:
    runs-on: ubuntu-latest
    outputs:
      derived_release_commit: ${{ steps.classify.outputs.derived_release_commit }}
      promotion_pr: ${{ steps.classify.outputs.promotion_pr }}
    steps:
      - id: classify
        uses: point-source/flywheel/classify@<sha> # v2.1.0

  governance-lint:
    needs: classify
    if: needs.classify.outputs.derived_release_commit != 'true' && needs.classify.outputs.promotion_pr != 'true'
    uses: repentsinner/symphonize/.github/workflows/governance-lint.yml@<sha> # notation--v0.2.12
    with:
      readme-type: library

  governance:
    name: quality / governance
    needs: [classify, governance-lint]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - if: contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled')
        run: exit 1
```

`quality / correctness` follows the same shape over the repository's
build, lint and test jobs. This repository's own
[`quality.yml`](.github/workflows/quality.yml) is a complete example.

## License

MIT
