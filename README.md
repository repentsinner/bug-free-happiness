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
  push:
    branches: [main]
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

## Python correctness

A uv project calls `python-correctness.yml` and makes its
`quality / correctness` summary job depend on the call. The workflow
runs ruff's lint and format checks, the type checker the call names
(`pyright`, the default, or `mypy`, which is deprecated and warns), and
`pytest` from the
project's lock. It pins ruff, pyright and mypy itself, so match those
versions locally (§spec:stack-implementations). mypy reads its targets from the project's
`[tool.mypy]` settings.

```yaml
  python:
    needs: classify
    if: needs.classify.outputs.derived_release_commit != 'true' && needs.classify.outputs.promotion_pr != 'true'
    uses: repentsinner/bug-free-happiness/.github/workflows/python-correctness.yml@<sha> # v0.4.0
    with:
      type-checker: pyright
```

A project with private git dependencies passes a GitHub App with
Contents read access to them. The workflow mints a read-only token per
run and fetches the owner's github.com git dependencies over HTTPS with
it. Declare those sources as `https://github.com/...` URLs, which
Dependabot can also fetch. Developers authenticate them with `gh auth
setup-git`, or keep using an SSH key by mapping the URLs back with
`git config --global url."git@github.com:<owner>/".insteadOf
"https://github.com/<owner>/"` (§spec:stack-implementations).

```yaml
    uses: repentsinner/bug-free-happiness/.github/workflows/python-correctness.yml@<sha> # v0.5.0
    with:
      app-client-id: ${{ vars.DEPS_READER_CLIENT_ID }}
    secrets:
      app-private-key: ${{ secrets.DEPS_READER_PRIVATE_KEY }}
```

## Local checks

`bfh-check` runs the same checks on your machine, with the same tool
versions: `uv sync --locked`, ruff's lint and format checks, the type
checker, and pytest. Use the release your `quality.yml` pins, so the
versions match:

```bash
uvx --from "git+https://github.com/repentsinner/bug-free-happiness@v0.8.0#subdirectory=.github/tools/python" bfh-check
```

Pass `--type-checker mypy` if your `quality.yml` names it, and put pytest
arguments after `--`. The workflow and `bfh-check` both supply ruff and
the type checker, so an adopter's dev group needs neither
(§spec:stack-implementations).

## Dart and Flutter correctness

A Dart or Flutter project calls `flutter-correctness.yml` and makes its
`quality / correctness` summary job depend on the call. For each package,
the workflow resolves dependencies, runs the analyzer with infos fatal,
checks formatting and runs the tests. Every check runs to completion, so
the job's failure names each check that failed. A package that depends on
the Flutter SDK runs `flutter` commands; any other package runs `dart`.

The project owns its SDK pin. The workflow reads the nearest `.fvmrc`, from
the package directory up to the repository root, and installs that Flutter
release. A Dart package with a `.fvmrc` runs the Dart that Flutter release
bundles. A package without one takes its release from `sdk-version`: a
Flutter release for a Flutter package, a Dart release otherwise. If neither
names an exact release, the job fails rather than run the `stable` channel
(§spec:flutter-correctness).

```yaml
  flutter:
    needs: classify
    if: needs.classify.outputs.derived_release_commit != 'true' && needs.classify.outputs.promotion_pr != 'true'
    uses: repentsinner/bug-free-happiness/.github/workflows/flutter-correctness.yml@<sha> # v0.9.0
    with:
      packages: |
        packages/core
        packages/app
      floor: true
      downgrade: true
```

`packages` lists package directories and defaults to the repository root.
With `floor: true`, each package also runs on the oldest SDK its
`environment` constraint admits: `environment.flutter` for a Flutter
package, `environment.sdk` otherwise. That leg tests the claim a library's
constraint makes, so it fails on analyzer errors and warnings but not
infos, and it skips the format check, because lint rules and formatter
output change between SDK releases.

With `downgrade: true`, each package also runs on its pinned SDK with its
direct dependencies at the oldest versions their constraints admit. The
pinned leg resolves to the newest versions, so a lower bound that names a
release without an API the code uses passes there and fails here. A project
that depends on the library can resolve anywhere in the range, which is
why a published library wants this leg. The leg follows the floor leg's
analyzer and format rules. It leaves `dev_dependencies` at their pinned-leg
versions, because the test runner's oldest releases don't load on a
current SDK and the library's users never resolve them.

A project with private git dependencies passes a GitHub App with Contents
read access to them, as a Python project does. Each job mints a read-only
token and fetches github.com git dependencies over HTTPS with it, so
`ssh://` and `git@github.com:` sources keep working for developers with SSH
keys (§spec:flutter-correctness).

```yaml
    uses: repentsinner/bug-free-happiness/.github/workflows/flutter-correctness.yml@<sha> # v0.9.0
    with:
      app-client-id: ${{ vars.DEPS_READER_CLIENT_ID }}
    secrets:
      app-private-key: ${{ secrets.DEPS_READER_PRIVATE_KEY }}
```

A project that needs more than the SDK, such as system packages, a native
toolchain or code generation, runs the `flutter-check` action as a step of
its own job, after that setup. The action takes `path`, `sdk-version`,
`floor` and `downgrade`, and checks one package. It takes `app-client-id` and
`app-private-key` as inputs too, so pass the key from a secret.

```yaml
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha> # v7.0.1
      - run: sudo apt-get install -y libusb-1.0-0-dev
      - uses: repentsinner/bug-free-happiness/.github/actions/flutter-check@<sha> # v0.9.0
```

The action runs [`flutter-check.sh`](.github/actions/flutter-check/flutter-check.sh),
which a developer or a project's own CI script can run too. It checks each
package directory it is given, with whichever `dart` and `flutter` are on
PATH, so put the pinned SDK there first, for example with `fvm exec`. For
the floor leg, put the floor SDK on PATH and pass `--floor`. For the
downgrade leg, pass `--downgrade`. It puts the package's `pubspec.lock`
back when it finishes.

```sh
fvm exec bash flutter-check.sh packages/core packages/app
PATH="$HOME/fvm/versions/3.44.4/bin:$PATH" bash flutter-check.sh --floor packages/core
fvm exec bash flutter-check.sh --downgrade packages/core
```

## Optional checks

`quality / security` reports supply-chain findings on each pull request.
The ruleset template doesn't require it yet, so a failure shows in the
checks list without blocking the merge (§spec:supply-chain). Its first
job reads the repository's Dependabot configuration. The configuration
needs an entry for `github-actions` and for each tracked stack: `uv` or
`pip` for Python manifests, `pub` for `pubspec.yaml`. Each entry runs
daily or weekly, with a group that takes minor and patch updates.

```yaml
  security-checks:
    needs: classify
    if: needs.classify.outputs.derived_release_commit != 'true' && needs.classify.outputs.promotion_pr != 'true'
    uses: repentsinner/bug-free-happiness/.github/workflows/security.yml@<sha> # v0.3.0

  security:
    name: quality / security
    needs: [classify, security-checks]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - if: contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled')
        run: exit 1
```

## License

MIT
