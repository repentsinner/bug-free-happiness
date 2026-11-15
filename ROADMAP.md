# bug-free-happiness — Roadmap

## Organization rulesets §road:org-rulesets

### Render either ruleset level §road:render-ruleset-levels

Add `rulesets/render.sh`, which writes the repository or organization
variant of each ruleset in `rulesets/` to a given directory with the App
ID substituted, the organization variant adding the `bug-free-happiness`
= `v1` repository-property condition, and document it in
`rulesets/README.md`. §spec:ruleset-levels §spec:ruleset-application.

### Create the organization rulesets §road:create-org-rulesets

In one organization on a plan with organization rulesets, define the
single-select `bug-free-happiness` custom property with the value `v1`,
and create the four rulesets from the organization variant, targeting
no repository yet. §spec:ruleset-levels §spec:ruleset-application.
Depends on §road:render-ruleset-levels. Maintainer action: an agent's
token cannot change organization settings.

### Adopt one repository at organization level §road:adopt-org-repository

Set `bug-free-happiness` to `v1` on one Flywheel-managed repository that
already emits the summary jobs, then delete its repository-level
rulesets and confirm it has no classic branch protection.
§spec:ruleset-levels §spec:ruleset-template §spec:problem. Depends on
§road:create-org-rulesets. Maintainer action: an agent's token cannot
change repository settings.

**Verify:** Confirm the repository lists no repository-level rulesets,
its branch rules come only from the four organization rulesets, and
classic branch protection is disabled. Compare each live organization
ruleset against the rendered organization variant, and confirm they
match in name, conditions, parameters, check sources and bypass actors.
Open a PR whose `quality / correctness` dependency fails, and confirm the
merge is blocked. Merge a `fix:` PR, and confirm Flywheel's release push
succeeds and tags the next version. Confirm a repository without the
property shows none of the organization rules on its default branch.

## Python correctness workflow §road:python-correctness

### Publish the Python correctness workflow §road:python-correctness-workflow

Add reusable `.github/workflows/python-correctness.yml` that runs a uv
project's linter, format check, type checker and tests.
§spec:stack-implementations.

### Self-test against Python fixtures §road:python-fixtures

Add a passing uv project and one failing project per check (lint,
format, types, tests) under `tests/fixtures/python/`, and make
`quality / correctness` in `.github/workflows/quality.yml` depend on a
call per fixture, each naming its expected failure through `expect`,
plus a mypy call on the passing project. §spec:stack-implementations
§spec:summary-jobs §spec:quality-classes. Depends on
§road:python-correctness-workflow.

**Verify:** On a PR, confirm every Python call passes, each failing
fixture's log shows its named check failing and the others passing, and
`quality / correctness` is green. Break the passing fixture's test, and
confirm `quality / correctness` fails and blocks merge.

## Type checking everywhere §road:type-checking

### Type-check the last untyped adopter §road:type-check-last-adopter

Bring the one Python adopter that calls the workflow without a type
checker to pyright or mypy: add type stubs for its untyped C-extension
dependency, fix the remaining findings, and drop `type-checker: none`.
§spec:stack-implementations. Maintainer action in that repository.

### Migrate the mypy adopters to pyright §road:migrate-mypy-adopters

Move each adopter that calls the workflow with `type-checker: mypy` to
pyright, fixing the findings pyright adds, then remove `mypy` from the
input. §spec:stack-implementations. Maintainer action in each adopter.

### Remove the transitional none §road:remove-type-checker-none

Remove `none` from `python-correctness.yml`'s `type-checker` input, so a
caller naming it fails. §spec:stack-implementations. Depends on
§road:type-check-last-adopter.

**Verify:** Confirm no adopter's call names `type-checker: none`. Call
the workflow with `none` from a fixture, and confirm the job fails with
an error naming the accepted values.

## Dart and Flutter correctness check §road:flutter-correctness

### Publish the Dart and Flutter check §road:flutter-correctness-workflow

Add the check script, the composite action
`.github/actions/flutter-check/action.yml` and the reusable
`.github/workflows/flutter-correctness.yml` around it, running dependency
resolution, analysis with infos fatal, the format check and tests on each
listed package with the SDK from `.fvmrc` or `sdk-version`, and an
`expect` input for self-tests. §spec:flutter-correctness
§spec:stack-implementations.

### Add the floor leg §road:flutter-floor-leg

Add a `floor` input that also runs the check on the oldest SDK a
package's `environment` constraint admits, under the floor leg's relaxed
rules. §spec:flutter-correctness. Depends on
§road:flutter-correctness-workflow.

### Fetch private git dependencies §road:flutter-private-deps

Add the `app-client-id` input and `app-private-key` secret that mint a
read-only token for private git dependencies, as the Python workflow
does. §spec:flutter-correctness §spec:stack-implementations. Depends on
§road:flutter-correctness-workflow.

### Self-test against Dart and Flutter fixtures §road:flutter-fixtures

Add a passing Dart package, a passing Flutter package, a package for the
floor leg and one failing fixture per check under `tests/fixtures/flutter/`,
and make `quality / correctness` in `.github/workflows/quality.yml` depend
on calls expecting each outcome. §spec:flutter-correctness
§spec:summary-jobs §spec:quality-classes. Depends on
§road:flutter-floor-leg.

**Verify:** On a PR, confirm the checks list shows a passing call for each
passing fixture, and for each failing fixture a call that passes because
its `expect` names the check that failed, with `quality / correctness`
green. Break the passing Dart fixture's formatting and confirm
`quality / correctness` fails. Run the check script locally against the
passing Flutter fixture and confirm it reaches the same verdict as CI.
Remove a fixture's `.fvmrc` without setting `sdk-version` and confirm the
check fails naming the missing SDK pin.

## Dependabot configuration check §road:dependabot-config-check

### Publish the Dependabot configuration check §road:dependabot-config-job

Add reusable `.github/workflows/security.yml` with a job that fails when
the caller's Dependabot configuration is missing, lacks an entry for
`github-actions` or for the ecosystem of a Python or Dart manifest the
caller tracks, schedules an entry less often than weekly, or groups
none of an entry's minor and patch updates. Self-test it from a
`quality / security` summary job in `.github/workflows/quality.yml`
against fixtures under `tests/fixtures/dependabot/`.
§spec:supply-chain §spec:summary-jobs §spec:quality-classes.

**Verify:** On a PR, confirm the fixtures job reports every fixture as
`ok`, each failing fixture's output naming its gap, and the call on the
pass fixture and `quality / security` both pass with no failed job in the
run. Change the pass fixture's interval to `monthly`, and confirm
`quality / security` fails.

## Security class §road:security-class

### Add the advisory gate §road:advisory-gate

Add a job to `security.yml` that runs `google/osv-scanner-action` over the
caller's lockfiles, and its workflow references through the GitHub
Actions extractor. It fails on HIGH or CRITICAL advisories, annotates
MEDIUM and LOW ones, reads suppressions from the caller's
`osv-scanner.toml`, and refuses a suppression without an expiry.
§spec:supply-chain.

### Show the dependency delta on pull requests §road:dependency-review

Add `actions/dependency-review-action` to `security.yml` on pull
requests, at the gate's threshold. §spec:supply-chain. Depends on
§road:advisory-gate.

### Self-test against security fixtures §road:security-fixtures

Add a passing fixture and a failing one under `tests/fixtures/security/`:
a lockfile pinning a package with a known HIGH advisory. The pin-shape
check already has its fixtures under `tests/fixtures/pin-shape/`. Make
the `quality / security` summary job in `.github/workflows/quality.yml`
also depend on a call expecting each outcome. §spec:supply-chain
§spec:summary-jobs §spec:quality-classes. Depends on §road:advisory-gate.

**Verify:** On a PR, confirm the checks list shows the security workflow
passing on the passing fixture and failing on the failing one, the
advisory job naming an advisory ID, the package and the fixed version, with
`quality / security` green because each outcome matched. Add an expired
suppression to the passing fixture's `osv-scanner.toml`, and confirm
`quality / security` fails. Confirm a grouped Dependabot PR bumping a
SHA pin passes the pin-shape check, and that the Flywheel App's
`flywheel/conventional-commit` check passes on it.

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
§spec:ruleset-application §spec:ruleset-template §spec:pipeline-phases
§spec:problem. Depends on
§road:python-fixtures. Blocked — Flywheel's `apply-rulesets.sh` lacks the
changes in §road:flywheel-apply-requests. Unblocked when Flywheel
releases them.

**Verify:** Run the audit against the pilot before applying, and confirm
it lists every difference from `rulesets/`. Apply, rerun the audit, and
confirm it reports no drift. Confirm a Dependabot PR in the pilot
satisfies `flywheel/conventional-commit`. Open a PR whose test fails,
and confirm it cannot auto-merge.
