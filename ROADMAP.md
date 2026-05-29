# bug-free-happiness — Roadmap

Build the not-started sections of SPEC.md into the full governance-schema:
the enforcement workflow (§ 2, § 3, § 5, § 6), plugin packaging (§ 10), and
the scaffolder (§ 9). §4 and §7 are complete. §8 (the contract) is
*expressed* by the enforcement workflow, not built separately — completing
the enforcement workstreams realizes it.

Sections are in build-dependency order. bug-free-happiness uses plain
numbered SPEC sections and lints its own docs with plain markdownlint, so
this roadmap cites spec sections by number and omits the `§`-slug
machinery.

## Fix workflow naming and version coherence

Update README.md and any self-references to pin `governance-lint.yml@v0` —
the workflow's real name and published major — instead of the stale
`spec-lint.yml@v1`, and make the floating major tag track the published
release. § 2, § 6. Foundational: the workflow must be correctly
referenceable before symphonize consumes it.

**Verify:** a caller pinning `governance-lint.yml@v0` resolves the current
workflow; `grep -ri spec-lint .` finds no live references (CHANGELOG
history may retain them); the floating major tag points at the latest
release, not a pre-rename commit.

## Validate status lines on any heading

Change the status-line validator in `governance-lint.yml` from
numbered-only (`## N.`) to any `##` heading. § 3.

**Verify:** a slug-style SPEC.md has every `##` section's status line
checked — a section missing one fails the job — while bug-free-happiness's
own numbered SPEC.md still passes.

## Add traceability and prose checks

Port from symphonize's `governance-lint.yml`: `§spec`/`§road`/`§req`
heading-slug presence, cross-document reference resolution (fenced-code
and inline-code exempt), markdownlint over REQUIREMENTS.md, and the Vale
step (active when `.vale.ini` exists). These run on every invocation, no
toggles. § 5.

**Verify:** a repo whose SPEC.md cites a `§spec:` slug that no heading
defines fails with a dangling-reference error; a repo with `.vale.ini`
has its SPEC/REQUIREMENTS prose linted; a repo without `.vale.ini` skips
Vale without error.

## Package bug-free-happiness as a plugin

Add a `.claude-plugin/plugin.json` manifest and marketplace entry so the
scaffolder ships as a Claude Code plugin alongside the reusable workflow,
on one release-please version line. § 10. Prerequisite for the scaffolder
and for symphonize declaring a plugin dependency on the schema.

**Verify:** `plugin.json` validates; bug-free-happiness installs from its
marketplace; the installed plugin and the workflow tag carry the same
version.

## Build the scaffolder command

Adapt symphonize's `commands/init.md` into a bug-free-happiness scaffolder
plugin command that writes the governance-file skeletons, a CI caller
referencing `governance-lint.yml@v0`, and a declared plugin dependency on
bug-free-happiness; idempotent (skips existing files, warns rather than
overwrites). § 9. Depends on "Fix workflow naming and version coherence"
(a correct ref to pin) and "Package bug-free-happiness as a plugin".

**Verify:** running the scaffolder in a fresh repo writes the
SPEC/ROADMAP/CHANGELOG skeletons and a `governance-lint.yml` caller pinned
to a major that resolves; re-running skips existing files and warns; the
scaffolded repo's CI passes against the workflow.
