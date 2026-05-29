# bug-free-happiness Specification

## 1. Problem Statement

*Status: in progress*

Repos lack an enforceable definition of what well-formed governance
documents look like — SPEC.md status lines, README headings, markdown
formatting, and cross-document traceability drift or go unchecked.

bug-free-happiness is **symphonize's governance-schema** (called *the
kernel* through the rest of this spec): the structural definition of
symphonize's governance documents plus the CI workflow that enforces it.
It is consumed only by symphonize — not a general-purpose linter other
projects adopt. If symphonize ever needs a different governance-doc
schema, it would plug a different one in on its own side; that seam stays
unbuilt until a second schema exists. The schema has three faces, released
together on one version line:

- **Contract** (§ 8) — the structural grammar: governance file formats,
  the `§`-slug rules, the status-line format, and the cross-reference
  rules. It defines what a well-formed governance document is, not how to
  author one — authoring is symphonize's curation methodology, not the
  schema.
- **Scaffolder** (§ 9) — the command that wires an adopter repo up to the
  kernel (governance skeletons plus a pinned CI caller).
- **Enforcement** (§ 2–§ 7) — the reusable workflow that validates a repo
  against the contract in CI.

**Why contract and enforcement stay together:** a linter is the
executable form of the schema — the lint rules and the grammar are one
specification viewed two ways. Keeping them on one version line makes
their coherence structural: one tag moves both, so they cannot drift.
They drifted once, when the workflow validated numbered `## N.` sections
while the grammar had moved to slug-style headings and nothing caught it.
The schema's only outward dependency edge is its plugin consumers —
symphonize's curation and dispatch commands — which pin it by version
(§ 6, § 10).

## 2. Reusable Governance Lint Workflow

*Status: in progress*

The system shall provide a single reusable workflow,
`governance-lint.yml`, that callers invoke via `workflow_call`. One job
runs the checks in sequence; failures surface as `::error::` annotations.

The workflow runs symphonize's full schema in one job — there are no
opt-in switches; every check runs every time:

- **markdownlint** over SPEC.md, ROADMAP.md, README.md, and
  REQUIREMENTS.md (CHANGELOG.md is excluded — see § 5).
- **SPEC.md status-line validation** (§ 3).
- **README heading validation** (§ 4), active when `readme-type` is set.
- **Traceability and prose checks** (§ 5) — slug presence, cross-reference
  resolution, and Vale.

The sole input is `readme-type` (§ 4) — a README-profile selector, a
parameter rather than a feature switch.

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

**Why any heading, not numbered-only:** symphonize's SPEC.md uses
slug-style headings (`## Title §spec:slug`), not numbered sections. A
numbered-only check matches zero sections in a slug-style SPEC.md and
reports success — a false green, which is exactly the drift that occurred
once (§ 1). Validating every `##` heading removes that silent-pass failure
mode and stays robust if the heading style ever changes.

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

## 5. Traceability and Prose Checks

*Status: not started*

Beyond markdownlint, status lines, and README profiles (§ 2–§ 4), the
schema enforces symphonize's traceability and prose rules. These run on
every invocation — there are no opt-in switches:

- **Slug presence:** every `##` SPEC.md heading carries a `§spec:<slug>`;
  every `###` ROADMAP.md heading a `§road:<slug>`; every `##`
  REQUIREMENTS.md heading a `§req:<slug>`.
- **Cross-document reference resolution:** every `§spec:`/`§road:`/`§req:`
  reference in a governance document resolves to a defined heading slug.
  Dangling references fail the job. References inside fenced code blocks
  and inline code spans are exempt.
- **Prose:** Vale runs when a `.vale.ini` config exists; absent the
  config the step is a no-op.

CHANGELOG.md is excluded from every check. release-please generates it
from conventional commits and regenerates it each release, so enforcing
its structure or formatting fights the generator and is overwritten. The
schema references CHANGELOG as the history endpoint but does not own its
shape — its format belongs to release-please and the Keep a Changelog
convention.

**Why no opt-in switches:** earlier drafts made these checks toggleable to
serve a generic doc-lint audience that wanted markdown hygiene without the
`§`-system. That audience does not exist — the schema is symphonize's, and
its only consumer wants every check, so toggles would be dead
configuration. bug-free-happiness's own repo is not a symphonize-governance
project, so it lints its own docs with plain markdownlint rather than
calling this full-schema workflow on itself.

## 6. Version Coherence

*Status: not started*

A caller pins the workflow with `uses: …/governance-lint.yml@<ref>`. Two
existing mechanisms — not a bespoke marker — carry version coherence:

- **The workflow ref.** The floating major-version tag tracks the latest
  compatible release, so callers pinning `@vN` receive backward-compatible
  updates without editing their workflow. The tag shall point at the
  published release it names — it shall not lag behind a renamed or
  restructured workflow. The major the README and scaffolding instruct
  callers to pin shall match the published major; while the tool is
  pre-1.0, that reference is `@v0` (or a pinned `@v0.N.N`), not `@v1`.
- **The plugin dependency.** Plugin consumers (the future curate and
  dispatch plugins) declare a machine-enforced semver `dependencies` on
  the scaffolder plugin (§ 9); the plugin manager resolves and enforces
  that range.

Together these pin both faces of the kernel — the CI workflow by git ref,
the plugin by dependency range — to one repo's version line. No separate
`contracts-version` marker is needed: the grammar is not shipped to
adopters as a file (§ 8), so there is nothing to carry a marker, and the
ref and the dependency already declare which kernel version a repo
targets.

**Why this matters now:** the `spec-lint.yml → governance-lint.yml`
rename (§ 2) changed the workflow path without moving the floating major
tag, so `@v1` still resolves the old `spec-lint.yml` while `main` ships
`governance-lint.yml`. The README instructs callers to pin
`spec-lint.yml@v1`, a reference that survives only because the tag is
stale. A caller adopting the current workflow by its real name and major
gets nothing. The ref discipline above closes that gap.

## 7. Release Automation

*Status: complete*

Releases follow conventional commits with automated version bumps via
release-please. A floating major-version tag auto-updates when a new
release is published, so callers referencing the major tag track the
latest compatible version without changing their workflows. The major
tag the README and scaffolding reference is governed by § 6.

## 8. Conventions Contract

*Status: not started*

The kernel defines the **structural contract** — the machine-checkable
grammar for a well-formed governance document: governance file formats,
the `§req:`/`§spec:`/`§road:` slug rules, the status-line format, the
cross-reference rules (§ 5), and the governance-root definition (which
directories are governance roots and how files scope to them).

The contract is **expressed, not distributed**: it ships no document to
adopters. It is operative in two forms — the **enforcement workflow**
(§ 2) is its executable form (what the linter checks *is* the contract),
and the kernel's own documentation is its human-readable form. Plugin
consumers (curate, dispatch) are built against this grammar and carry what
they need to produce conforming documents; they do not read a contract
file from the adopter's repo, and the linter does not either — its rules
live in the workflow. So no per-adopter `CONVENTIONS.md` is materialized.

**Scope boundary — what the contract excludes:** the kernel is
content-agnostic. The contract defines document *structure*, not
authoring *methodology* or development *process*. How to write a good
spec (declarative, rationale-driven, thin vertical slices), how to run
discovery (interview frameworks), how to compress a completed section,
and process rules (branching, commit conventions, the quality gate) are
the opinions of the governance *system* built on the schema, not part of
the schema. They live in symphonize's own layers — its curation and
dispatch commands. Symphonize's `CONVENTIONS.md` therefore bundles three
contracts; only the structural one is the schema's, and the schema
expresses it through enforcement, not a shipped document.

**Why the schema owns only structure:** the grammar and the lint that
enforces it shall agree, and § 1 keeps both on one version line for that
reason. The schema deliberately does not define methodology — a linter
cannot enforce it, and it is symphonize's curation layer's job, not the
schema's.

**Why expressed, not distributed:** once the linter is the executable
form of the contract and symphonize's commands are built against the same
grammar, nothing at runtime needs to read a contract document from a
repo. A materialized copy would only add a second source of truth to keep
in sync with the linter — the drift the single-version design exists to
prevent. Humans who want a written reference read the schema's own
documentation.

## 9. Scaffolder

*Status: not started*

The kernel provides a scaffolder — a Claude Code plugin command — that
wires an adopter repo up to the kernel. Running it writes the governance
file skeletons and a CI caller workflow referencing this repo's
`governance-lint.yml` at the matching major version, and (for a
governance-system adopter) declares the plugin dependency on the kernel.
It does not materialize a contract file (§ 8). The scaffolder is
idempotent: it skips files that already exist and warns rather than
overwrites.

Because the scaffolder and the enforcement workflow ship from the same
repo and version, a freshly scaffolded project references a coherent
kernel — the CI ref it pins and the plugin dependency it declares both
resolve to one release.

**Why the scaffolder ships with the lint:** the scaffolder writes the CI
ref that callers pin. Shipping it from the same repo and version as the
workflow guarantees it writes a ref that exists and matches — a scaffolder
at a different version could write a stale or mismatched ref, the exact
incoherence § 1 rejects (and the stale-tag failure § 6 describes). One
repo, one version, removes that failure mode.

**Migration note:** the scaffolder currently lives in the symphonize
repository (`commands/init.md`), and symphonize's `CONVENTIONS.md` bundles
the structural grammar with authoring methodology and process discipline.
The end state: the kernel owns the scaffolder and defines the structural
grammar (through its linter and docs), while symphonize's `CONVENTIONS.md`
is removed — its methodology moving inline into the curation commands and
its process discipline into the dispatch commands. Dismantling the
symphonize-side originals is a separate downstream change; this section
establishes only that the kernel repo owns the scaffolder and the
structural grammar.

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
pin for the workflow and the plugin `dependencies` range for the
scaffolder plugin — both originate from this one version line.
