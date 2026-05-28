# bug-free-happiness Specification

## 1. Problem Statement

*Status: in progress*

Repos lack consistent enforcement of documentation structure. SPEC.md
status lines, README headings, and markdown formatting drift or go
unchecked. Each repo either reimplements validation or skips it.

bug-free-happiness is the enforcement arm of a conventions kernel — the
single reusable workflow that validates a repo's governance documents in
CI. It serves two audiences from one workflow:

- **Generic adopters** want documentation hygiene — markdown formatting,
  SPEC.md status lines, README heading profiles — without adopting any
  particular governance methodology. These checks run by default.
- **Governance-system adopters** (e.g. the symphonize plugin suite)
  layer a slug-based traceability contract on top — `§`-prefixed
  cross-references between SPEC.md, ROADMAP.md, and REQUIREMENTS.md, plus
  prose linting. These checks are opt-in (§ 5) so they never burden
  adopters who have not bought into the contract.

**Why one workflow, two audiences:** a governance system that owns its
own lint couples enforcement to that system's release cadence and forces
every downstream repo to inherit the system's full opinion. Factoring
enforcement into a standalone, opt-in workflow lets the generic checks be
adopted alone, lets the governance-specific checks evolve behind a flag,
and gives the governance system a single source of truth for "is this
repo's documentation valid" that it consumes rather than re-implements.

## 2. Reusable Governance Lint Workflow

*Status: in progress*

The system shall provide a single reusable workflow,
`governance-lint.yml`, that callers invoke via `workflow_call`. One job
runs the checks in sequence; failures surface as `::error::` annotations.

The always-on generic core comprises:

- **markdownlint** over the governance files present in the repo.
- **SPEC.md status-line validation** (§ 3).
- **README heading validation** (§ 4), active only when `readme-type` is
  set.

The generic core requires no opinion beyond "this repo has governance
documents worth keeping well-formed." It runs identically whether or not
the opt-in governance checks (§ 5) are enabled.

**Why the name is `governance-lint.yml`, not `spec-lint.yml`:** the
workflow validates the whole governance document set, not SPEC.md alone.
The prior `spec-lint.yml` name predates that scope and no longer
describes what the workflow does. Pre-1.0, the rename is corrected
forward with no compatibility shim (§ 6 governs the version contract).

## 3. Status-Line Grammar

*Status: not started*

The status-line validator shall require every `##` second-level heading
in SPEC.md to be followed by a `*Status:` line matching `not started`,
`in progress`, or `complete`, ignoring blank lines between the heading
and the status line. Headings without a status line, or with a malformed
status line, produce `::error::` annotations and fail the job. When no
SPEC.md exists, the validator skips without error.

The validator shall not require section headings to be numbered. It
recognizes any `##` heading, whether the section is numbered
(`## 1. Problem statement`) or slug-style
(`## Problem statement §spec:problem`).

**Why any heading, not numbered-only:** a numbered-only check matches
zero sections in a slug-style SPEC.md and reports success — a false
green. The kernel must serve both heading grammars, because the two
audiences (§ 1) use different conventions: generic adopters number their
sections, governance-system adopters use slug-style headings. Validating
every `##` heading is the superset that covers both and removes the
silent-pass failure mode.

## 4. README Heading Validation

*Status: complete*

The workflow accepts a `readme-type` input: `library`, `application`, or
`""` (empty string, the default — skips the check). When set, the system
extracts H2 headings from README.md, lowercases them, and checks them
against the required headings for the type. Missing headings produce
`::error::` annotations and fail the job.

Required headings by type:

- **Both:** License (synonyms: license, licensing, licensing note)
- **Library:** Installation (synonyms: installation, install, getting
  started, quick start), Usage, API (synonyms: api, api reference)
- **Application:** Getting Started (synonyms: quick start, getting
  started, installation, install), Usage

## 5. Opt-In Governance Checks

*Status: not started*

The workflow shall expose boolean `workflow_call` inputs that enable the
governance-system-specific checks. Each defaults to `false`, so a caller
that sets none gets only the generic core (§ 2). The inputs:

- **`traceability`** — enables the slug-based traceability checks:
  - Heading-slug presence: every `##` SPEC.md heading carries a
    `§spec:<slug>`; every `###` ROADMAP.md heading a `§road:<slug>`;
    every `##` REQUIREMENTS.md heading a `§req:<slug>`.
  - Cross-document reference resolution: every `§spec:`/`§road:`/`§req:`
    reference appearing in a governance document resolves to a defined
    heading slug. Dangling references fail the job. References inside
    fenced code blocks and inline code spans are exempt.
- **`vale`** — runs the Vale prose linter when a `.vale.ini` config
  exists in the repo. Absent the config, the step is a no-op even when
  the input is `true`.
- **`extended-globs`** — widens markdownlint and structure validation to
  REQUIREMENTS.md and CHANGELOG.md, and enables CHANGELOG.md structure
  validation (an `## [Unreleased]` section is present; every `##`
  heading is `[Unreleased]` or a `[N.N.N]` version).

**Why opt-in, not always-on:** the traceability contract, Vale, and the
CHANGELOG structure are symphonize's opinion, not universal documentation
hygiene. Forcing them on every adopter would make the workflow unusable
for the generic audience (§ 1) and defeat the reason for extracting it.
Defaulting each input to `false` keeps the generic core adoptable alone
while letting a governance-system caller switch on the full contract in
one place.

**Why booleans, not a single mode string:** the checks are independent —
a repo may want prose linting without slug traceability, or extended
globs without Vale. Independent toggles compose; a single enumerated
mode would force the caller to accept bundles they did not ask for.

**Tradeoff accepted:** more inputs widen the workflow's surface and the
matrix of states to test. The independence is worth the surface — the
alternative is either a coarse all-or-nothing flag or a second workflow
to maintain.

## 6. Version Coherence

*Status: not started*

A caller pins the workflow with `uses: …/governance-lint.yml@<ref>`. The
version contract shall make that reference coherent across three facets:

- The floating major-version tag tracks the latest compatible release,
  so callers pinning `@vN` receive backward-compatible updates without
  editing their workflow. The tag shall point at the published release it
  names — it shall not lag behind a renamed or restructured workflow.
- The major tag the README and scaffolding instruct callers to pin shall
  match the published major version. While the tool is pre-1.0, that
  reference is `@v0` (or a pinned `@v0.N.N`), not `@v1`.
- A governance-system caller and the kernel agree on a grammar version
  through a `contracts-version` marker carried in the consuming repo's
  materialized conventions (e.g. CONVENTIONS.md frontmatter). The kernel
  declares the grammar version it enforces; the caller's governance-lint
  step is expected to run a kernel ref whose grammar version matches the
  marker. A mismatch is a detectable drift, not a silent one.

**Why this matters now:** the `spec-lint.yml → governance-lint.yml`
rename (§ 2) changed the workflow path without moving the floating major
tag, so `@v1` still resolves the old `spec-lint.yml` while `main` ships
`governance-lint.yml`. The README instructs callers to pin
`spec-lint.yml@v1`, a reference that survives only because the tag is
stale. A caller adopting the current workflow by its real name and major
gets nothing. The version contract closes that gap.

**Why a marker, not the plugin dependency field:** Claude Code plugins
declare machine-enforced `dependencies` with semver ranges, but
bug-free-happiness is a reusable GitHub Actions workflow referenced by
git ref, not a plugin. Its coherence rests on the `@vN` ref pin plus the
`contracts-version` marker. The plugin dependency mechanism governs the
conventions *plugin* and its plugin consumers — a separate layer of the
kernel, not this workflow.

**Tradeoff accepted:** the `contracts-version` marker is detected, not
enforced by a package manager. The kernel cannot refuse to run against a
mismatched consumer; it can only surface the mismatch. For a CI workflow
pinned by ref, detection is the available guarantee.

## 7. Release Automation

*Status: complete*

Releases follow conventional commits with automated version bumps via
release-please. A floating major-version tag auto-updates when a new
release is published, so callers referencing the major tag track the
latest compatible version without changing their workflows. The major
tag the README and scaffolding reference is governed by § 6.
