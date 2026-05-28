# bug-free-happiness Specification

## 1. Problem Statement

*Status: in progress*

Repos lack a shared, enforceable definition of what well-formed
governance documents look like. SPEC.md status lines, README headings,
markdown formatting, and cross-document traceability drift or go
unchecked. Each repo either reimplements the rules, the validation, and
the scaffolding, or skips them.

bug-free-happiness is the conventions kernel — the single source of truth
a repo adopts to participate in the governance loop. It owns three faces,
released together on one version line:

- **Contract** (§ 8) — the canonical grammar: governance file formats,
  the `§`-slug rules, and the status-line format.
- **Scaffolder** (§ 9) — the command that materializes the contract and a
  CI caller into an adopter repo.
- **Enforcement** (§ 2–§ 7) — the reusable workflow that validates a repo
  against the contract in CI.

It serves a spectrum of adopters from these three faces:

- **Generic adopters** want documentation hygiene — markdown formatting,
  SPEC.md status lines, README heading profiles — without any governance
  methodology. They reference the enforcement workflow with no opt-in
  flags; the generic core (§ 2) is all they get.
- **Governance-system adopters** (e.g. the symphonize plugin suite) take
  the full contract: the slug-based traceability grammar, the scaffolder,
  and the enforcement workflow with the governance checks (§ 5) switched
  on.

**Why one repo, not a kernel split across repos:** a linter is the
executable form of the contract — the lint rules and the grammar are one
specification viewed two ways. Co-locating contract, scaffolder, and
enforcement under one version makes their coherence structural: one tag
moves all three together, so they cannot drift. Splitting them
reintroduces a cross-repo version handshake that has already failed in
practice — the enforcement workflow once validated numbered `## N.`
sections while the canonical grammar had moved to slug-style headings,
and nothing caught the divergence. The only version handshake the kernel
keeps is the outer one, between the kernel and its plugin consumers
(§ 6, § 10).

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
the enforcement workflow is a reusable GitHub Actions workflow referenced
by git ref, not a plugin. Its coherence rests on the `@vN` ref pin plus
the `contracts-version` marker. The plugin `dependencies` field governs a
different edge: between the scaffolder plugin (§ 9) and the plugin
consumers that depend on it (e.g. the future curate and dispatch
plugins). Both artifacts ship from this one repo (§ 10), but through
different distribution channels with different coherence mechanisms.

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

## 8. Conventions Contract

*Status: not started*

The kernel holds the canonical CONVENTIONS.md — the grammar that defines
governance file formats, the `§req:`/`§spec:`/`§road:` slug rules, and the
status-line format. This file is the source of truth. Adopter repos
receive a materialized copy (§ 9) rather than referencing it at runtime,
because a CI step and a working agent can only reliably read files in
their own workspace.

The materialized copy carries a `contracts-version` marker (§ 6) naming
the grammar version it was cut from, so an adopter's documents, its lint
runs, and the kernel agree on one grammar.

The contract splits along the same line as enforcement (§ 5):

- The **generic-core grammar** — status-line format and README heading
  profiles — applies to every adopter.
- The **traceability grammar** — the `§`-slug rules and cross-document
  reference conventions — applies only to governance-system adopters who
  opt in.

**Why the kernel owns the canonical grammar:** the grammar and the lint
that enforces it must agree, and § 1 places both in this repo for that
reason. A consumer that kept its own grammar copy as the source of truth
would recreate the drift the single-repo design exists to prevent. The
kernel defines; adopters receive.

**Why materialize, not reference at runtime:** a referenced contract
would require every adopter's CI and every agent acting on the repo to
reach into this repo's checkout. Materializing a versioned copy into the
adopter keeps the contract readable in the one place tools can always
see — the adopter's own working tree — at the cost of a version marker to
detect staleness.

## 9. Scaffolder

*Status: not started*

The kernel provides a scaffolder — a Claude Code plugin command — that
materializes the contract and a CI caller workflow into an adopter repo.
Running it writes the governance file skeletons, the materialized
CONVENTIONS.md with its `contracts-version` marker, and a caller workflow
referencing this repo's `governance-lint.yml` at the matching major
version. The scaffolder is idempotent: it skips files that already exist
and warns rather than overwrites.

Because the scaffolder and the enforcement workflow ship from the same
repo and version, a freshly scaffolded project references a coherent
kernel — the contract it receives, the lint it calls, and the grammar
version it records all originate from one release.

**Why the scaffolder lives with the contract and lint:** scaffolding is
the act of distributing the contract. A scaffolder in a different repo or
at a different version could write a caller that pins a lint version
incompatible with the contract version it materializes — the exact
incoherence § 1 rejects. One repo, one version, removes that failure
mode.

**Migration note:** the scaffolder and the canonical CONVENTIONS.md
currently live in the symphonize repository (`commands/init.md` and
`CONVENTIONS.md`). The end state is that the kernel owns the canonical
versions and symphonize consumes them as one adopter among others.
Dismantling the symphonize-side originals is a separate downstream
change; this section establishes only that the kernel repo owns these
artifacts.

## 10. Single-Repo, Dual Packaging

*Status: not started*

The kernel ships two artifact types from one repository on one version
line:

- The **reusable GitHub Actions workflow** (§ 2), consumed via
  `uses: …/governance-lint.yml@<major>` — a git-ref reference resolved by
  GitHub Actions.
- The **scaffolder plugin** (§ 9), consumed through a Claude Code plugin
  marketplace — resolved by the plugin manager, which can sparse-checkout
  the plugin subtree and enforce semver `dependencies` between plugins.

The two consumption paths do not collide: CI consumers reference a path
and a tag; plugin consumers install through the marketplace. One
release-please version and one tag cover both.

**Why this is not two repos:** the workflow and the scaffolder are two
distribution channels for the same contract. Separating them by repo
would split the kernel's version line and reintroduce the coherence
problem § 1 solves. The two coherence mechanisms in § 6 — the `@vN` ref
pin for the workflow and the `contracts-version` marker for materialized
files — both originate here. The plugin `dependencies` field governs only
the outer kernel↔plugin-consumer edge, not these in-repo artifacts.
