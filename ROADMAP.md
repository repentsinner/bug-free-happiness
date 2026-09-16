# bug-free-happiness — Roadmap

## Summary jobs on this repository §road:dogfood-summary-jobs

### Require the summary checks on this repository §road:require-summary-checks

Add a review ruleset on the default branch requiring `quality / governance`
and `quality / correctness` from any source. §spec:ruleset-template
§spec:problem. Maintainer action: an agent's token cannot change
repository settings.

**Verify:** Open a PR that breaks a workflow file so actionlint fails.
Confirm the checks list shows `quality / correctness` failing under that
exact name, and the merge box reports it as a required check blocking
merge. Fix the file, and confirm both `quality / governance` and
`quality / correctness` pass and the PR becomes mergeable.

## Python correctness workflow §road:python-correctness

### Publish the Python correctness workflow §road:python-correctness-workflow

Add reusable `.github/workflows/python-correctness.yml` that runs a uv
project's linter, format check, type checker and tests.
§spec:stack-implementations. Depends on §road:require-summary-checks.

### Self-test against Python fixtures §road:python-fixtures

Add a passing and a failing uv project under `tests/fixtures/python/`,
and make `quality / correctness` in `.github/workflows/quality.yml`
depend on calls that expect each outcome. §spec:stack-implementations
§spec:summary-jobs. Depends on §road:python-correctness-workflow.

**Verify:** On a PR, confirm the checks list shows the Python workflow
passing on the passing fixture and failing on the failing fixture, with
`quality / correctness` green because each outcome matched. Break the
passing fixture's test, and confirm `quality / correctness` fails and
blocks merge.

## Dart and Flutter correctness workflow §road:flutter-correctness

### Publish the Flutter correctness workflow §road:flutter-correctness-workflow

Add reusable `.github/workflows/flutter-correctness.yml` that runs a Dart
or Flutter project's analyzer, format check and tests.
§spec:stack-implementations. Depends on §road:require-summary-checks.

### Self-test against Flutter fixtures §road:flutter-fixtures

Add a passing and a failing Flutter project under
`tests/fixtures/flutter/`, and make `quality / correctness` depend on
calls that expect each outcome. §spec:stack-implementations
§spec:summary-jobs. Depends on §road:flutter-correctness-workflow.

**Verify:** On a PR, confirm the checks list shows the Flutter workflow
passing on the passing fixture and failing on the failing fixture, with
`quality / correctness` green because each outcome matched. Break the
passing fixture's analyzer check, and confirm `quality / correctness`
fails and blocks merge.

## Ruleset template §road:ruleset-template

### Publish the ruleset template §road:publish-ruleset-template

Add the four rulesets as JSON under `rulesets/`, with the Flywheel App ID
as the one placeholder. §spec:ruleset-template. Depends on
§road:require-summary-checks.

### Draft Flywheel's ruleset-application requests §road:flywheel-apply-requests

Write the five `apply-rulesets.sh` change requests to
`docs/upstream/flywheel.md` for the maintainer to file.
§spec:ruleset-application. Maintainer action: an agent's token cannot
open issues.

### Apply the template to a pilot adopter §road:pilot-ruleset-apply

Audit, then apply, `rulesets/` to one Flywheel-managed Python adopter
whose summary jobs depend on the Python correctness workflow.
§spec:ruleset-application §spec:pipeline-phases. Depends on
§road:publish-ruleset-template and §road:python-fixtures. Blocked —
Flywheel's `apply-rulesets.sh` lacks the changes in
§road:flywheel-apply-requests. Unblocked when Flywheel releases them.

**Verify:** Run the audit against the pilot before applying, and confirm
it lists every difference from `rulesets/`. Apply, rerun the audit, and
confirm it reports no drift. Confirm a Dependabot PR in the pilot
satisfies `flywheel/conventional-commit`. Open a PR whose test fails,
and confirm it cannot auto-merge.

## Retire the governance-schema workflow §road:retire-schema-workflow

### Remove the old workflow and rewrite the README §road:rewrite-readme

Delete `.github/workflows/governance-lint.yml` and rewrite `README.md` to
document the quality classes, summary jobs, stack workflows and ruleset
template. §spec:quality-classes §spec:stack-implementations.

**Verify:** Confirm `.github/workflows/` holds no `governance-lint.yml`,
and that a caller pinned to `@v1` still resolves, because the tag does
not move. Follow the README in a scratch repository to add summary jobs,
and confirm both required checks report under their exact names.
