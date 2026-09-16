# bug-free-happiness — Roadmap

## Release with Flywheel §road:release-with-flywheel

### Install the Flywheel App and its secrets §road:flywheel-app-secrets

Install the owner's Flywheel App on this repository, and store its ID as
the `FLYWHEEL_GH_APP_ID` variable and its private key as
`FLYWHEEL_GH_APP_PRIVATE_KEY` in both the Actions and Dependabot secret
stores. §spec:release-automation §spec:ruleset-template. Maintainer
action: an agent's token cannot install Apps or write secrets.

### Replace release-please with Flywheel §road:replace-release-please

Add `.flywheel.yml`, `.github/workflows/flywheel-pr.yml` and
`.github/workflows/flywheel-push.yml` from symphonize's notation Flywheel
templates, and delete `release-please.yml`, `auto-merge-release.yml`,
`update-major-tag.yml`, `release-please-config.json` and
`.release-please-manifest.json`. §spec:release-automation. Depends on
§road:flywheel-app-secrets.

### Publish the ruleset template §road:publish-ruleset-template

Add the four rulesets as JSON under `rulesets/`, each with its exact
name, pinned check sources and every parameter set, and the Flywheel App
ID as the one placeholder. §spec:ruleset-template.

### Apply the template to this repository §road:apply-template-here

Replace this repository's rulesets with `rulesets/` for the owner's App,
and delete the `RELEASE_PLEASE_PAT` secret. §spec:ruleset-template
§spec:release-automation §spec:pipeline-phases. Depends on
§road:replace-release-please and §road:publish-ruleset-template.
Maintainer action: an agent's token cannot change rulesets or secrets.

**Verify:** Confirm the live rulesets match `rulesets/` in name,
parameters and check sources. Merge a `fix:` PR: confirm the Flywheel
App posts `flywheel/conventional-commit`, the PR merges once all three
required checks pass, and Flywheel pushes a release commit and the next
`v<version>` tag after `v0.1.3`. Confirm `v0` and `v1` still point at
their earlier commits, and that force-pushing a `v*` tag is rejected.
Confirm a Dependabot PR satisfies the App-pinned
`flywheel/conventional-commit` check.

## Python correctness workflow §road:python-correctness

### Publish the Python correctness workflow §road:python-correctness-workflow

Add reusable `.github/workflows/python-correctness.yml` that runs a uv
project's linter, format check, type checker and tests.
§spec:stack-implementations.

### Self-test against Python fixtures §road:python-fixtures

Add a passing and a failing uv project under `tests/fixtures/python/`,
and make `quality / correctness` in `.github/workflows/quality.yml`
depend on calls that expect each outcome. §spec:stack-implementations
§spec:summary-jobs §spec:quality-classes. Depends on
§road:python-correctness-workflow.

**Verify:** On a PR, confirm the checks list shows the Python workflow
passing on the passing fixture and failing on the failing fixture, with
`quality / correctness` green because each outcome matched. Break the
passing fixture's test, and confirm `quality / correctness` fails and
blocks merge.

## Dart and Flutter correctness workflow §road:flutter-correctness

### Publish the Flutter correctness workflow §road:flutter-correctness-workflow

Add reusable `.github/workflows/flutter-correctness.yml` that runs a Dart
or Flutter project's analyzer, format check and tests.
§spec:stack-implementations.

### Self-test against Flutter fixtures §road:flutter-fixtures

Add a passing and a failing Flutter project under
`tests/fixtures/flutter/`, and make `quality / correctness` depend on
calls that expect each outcome. §spec:stack-implementations
§spec:summary-jobs §spec:quality-classes. Depends on
§road:flutter-correctness-workflow.

**Verify:** On a PR, confirm the checks list shows the Flutter workflow
passing on the passing fixture and failing on the failing fixture, with
`quality / correctness` green because each outcome matched. Break the
passing fixture's analyzer check, and confirm `quality / correctness`
fails and blocks merge.

## Security class §road:security-class

### Enable Dependabot here §road:dependabot-here

Add `.github/dependabot.yml` for the `github-actions` ecosystem on a
weekly cadence, grouping minor and patch updates. §spec:supply-chain
§spec:stack-implementations.

### Publish the pin-shape check §road:pin-shape-check

Add reusable `.github/workflows/security.yml` with a job that fails when
an external `uses:` reference under the caller's `.github/workflows/` is
not `<owner>/<repo>@<40-hex SHA>` followed by `# vX.Y.Z`, naming each
offending file and line. Local references are exempt, and the job adds
no dependency. §spec:supply-chain §spec:quality-classes.

### Add the advisory gate §road:advisory-gate

Add a job to `security.yml` that runs `google/osv-scanner-action` over the
caller's lockfiles, and its workflow references through the GitHub
Actions extractor. It fails on HIGH or CRITICAL advisories, annotates
MEDIUM and LOW ones, reads suppressions from the caller's
`osv-scanner.toml`, and refuses a suppression without an expiry.
§spec:supply-chain. Depends on §road:pin-shape-check.

### Show the dependency delta on pull requests §road:dependency-review

Add `actions/dependency-review-action` to `security.yml` on pull
requests, at the gate's threshold. §spec:supply-chain. Depends on
§road:advisory-gate.

### Self-test against security fixtures §road:security-fixtures

Add a passing fixture and two failing ones under
`tests/fixtures/security/` — a workflow referencing an Action by tag, and
a lockfile pinning a package with a known HIGH advisory — and add a
`quality / security` summary job to `.github/workflows/quality.yml` that
depends on calls expecting each outcome. §spec:supply-chain
§spec:summary-jobs §spec:quality-classes. Depends on §road:advisory-gate.

**Verify:** On a PR, confirm the checks list shows the security workflow
passing on the passing fixture and failing on each failing one — the
pin-shape job naming the offending file and line, the advisory job naming
an advisory ID, the package and the fixed version — with
`quality / security` green because each outcome matched. Add an expired
suppression to the passing fixture's `osv-scanner.toml`, and confirm
`quality / security` fails. Within a week of §road:dependabot-here
merging, confirm Dependabot opens a grouped PR bumping a SHA pin.

## Supply-chain reports §road:supply-chain-reports

### Publish the weekly advisory audit §road:advisory-audit

Add reusable `.github/workflows/security-audit.yml` that runs
osv-scanner over the caller's default branch at the gate's threshold and
uploads SARIF to the Security tab, failing nothing, and call it weekly
from this repository. §spec:supply-chain §spec:pipeline-phases. Depends
on §road:advisory-gate.

### Publish the Scorecard template §road:scorecard-template

Add `templates/scorecard.yml`, a workflow running `ossf/scorecard-action`
with published results within the action's workflow restrictions and
uploading SARIF to the Security tab, and copy it into this repository's
`.github/workflows/`. §spec:supply-chain.

**Verify:** Confirm this repository's weekly audit run completes, and its
findings, if any, appear among the Security tab's code scanning alerts
without failing a check. Confirm the Scorecard run completes, its
findings appear there, and the public Scorecard page for this repository
shows the latest scan date.

## Ruleset template §road:ruleset-template

### Draft Flywheel's ruleset-application requests §road:flywheel-apply-requests

Write the five `apply-rulesets.sh` change requests to
`docs/upstream/flywheel.md` for the maintainer to file.
§spec:ruleset-application. Maintainer action: an agent's token cannot
open issues.

### Apply the template to a pilot adopter §road:pilot-ruleset-apply

Audit, then apply, `rulesets/` to one Flywheel-managed Python adopter
whose summary jobs depend on the Python correctness workflow.
§spec:ruleset-application §spec:pipeline-phases §spec:problem. Depends on
§road:publish-ruleset-template and §road:python-fixtures. Blocked —
Flywheel's `apply-rulesets.sh` lacks the changes in
§road:flywheel-apply-requests. Unblocked when Flywheel releases them.

**Verify:** Run the audit against the pilot before applying, and confirm
it lists every difference from `rulesets/`. Apply, rerun the audit, and
confirm it reports no drift. Confirm a Dependabot PR in the pilot
satisfies `flywheel/conventional-commit`. Open a PR whose test fails,
and confirm it cannot auto-merge.

## Retire the governance-schema workflow §road:retire-schema-workflow

### Remove the governance-schema workflow §road:remove-schema-workflow

Delete `.github/workflows/governance-lint.yml` and its mentions in
`README.md`. §spec:release-automation §spec:stack-implementations.

**Verify:** Confirm `.github/workflows/` holds no `governance-lint.yml`
and `README.md` does not mention it. Confirm a caller pinned to `@v1`
still resolves the workflow, because that tag no longer moves.
