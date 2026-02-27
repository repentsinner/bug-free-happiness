# bug-free-happiness Specification

## 1. Problem Statement

*Status: complete*

Repos lack consistent enforcement of documentation structure. SPEC.md
status lines, README headings, and markdown formatting drift or go
unchecked. Each repo either reimplements validation or skips it.

## 2. Reusable Spec Lint Workflow

*Status: complete*

The system shall provide a single reusable workflow (`spec-lint.yml`)
that callers invoke via `workflow_call`. One job runs three checks in
sequence: markdownlint, SPEC.md status-line validation, and opt-in
README heading validation.

The SPEC.md validator shall require every `## N.` numbered section to
contain a `*Status:` line matching `not started`, `in progress`, or
`complete`. Sections without a status line or with malformed status
lines shall produce `::error::` annotations and fail the job.

When no `SPEC.md` exists, the validator shall skip without error.

## 3. README Heading Validation

*Status: complete*

The workflow shall accept a `readme-type` input: `library`,
`application`, or `""` (empty string). Empty default preserves backward
compatibility — existing callers get no new behavior.

When `readme-type` is set, the system shall extract H2 headings from
`README.md`, lowercase them, and check against required headings for the
type. Missing headings produce `::error::` annotations and fail the job.

Required headings by type:

- **Both:** License (synonyms: license, licensing, licensing note)
- **Library:** Installation (synonyms: installation, install, getting
  started, quick start), Usage, API (synonyms: api, api reference)
- **Application:** Getting Started (synonyms: quick start, getting
  started, installation, install), Usage

## 4. Release Automation

*Status: complete*

Releases shall follow conventional commits with automated version bumps
via release-please. A floating major version tag (`v1`) shall
auto-update when a new release is published, so callers referencing
`@v1` track the latest compatible version without changing their
workflows.
