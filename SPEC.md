# bug-free-happiness — Specification

bug-free-happiness defines the quality phase that every
Flywheel-managed repository shares: the check names a branch ruleset
requires, how a repository produces them, and the ruleset set that
requires them. It also publishes the stack-specific workflows that
implement the correctness class.

The governance-document schema this repository once planned to hold
lives in symphonize's notation plugin (symphonize SPEC, "Plugin
decomposition").

## Problem §spec:problem
*Status: not started*

One maintainer runs many repositories across a user account and
several organizations. Each repository's rulesets were copied by hand
from another's, and they drift:

- Required check lists differ between repositories, so the same change
  passes the gate in one and not in another.
- A ruleset that requires a check name no workflow in the repository
  emits blocks every pull request indefinitely. The check stays
  `Expected`, and nothing reports why.
- A required check pinned to one GitHub App rejects the same check
  posted by the workflow token. Flywheel posts it that way on
  Dependabot pull requests that cannot read the App key, so those pull
  requests never merge.
- Build and test jobs that are not required checks do not gate native
  auto-merge. A pull request whose build fails merges anyway.

The system shall let one ruleset set apply to every adopting repository
unchanged, except for the owner's Flywheel App. Repositories differ
only in what runs behind a fixed set of check names.

## Pipeline phases §spec:pipeline-phases
*Status: not started*

A change moves through four phases:

1. **Quality** — runs on the pull request and in the merge queue.
   Branch rulesets gate merging on it.
2. **Release** — Flywheel cuts the version after merge.
3. **Build** — produces artifacts from the release.
4. **Publish** — distributes them.

This contract covers the quality phase. Build and publish run after
merge, where a branch ruleset has no pull request to block. Flywheel's
optional release gate can require heavier checks on production
branches; those checks follow the naming in §spec:quality-classes.

A compile or container build that runs on the pull request to prove
the change sound belongs to quality, not build.

**Why not Flywheel:** Flywheel excludes quality-check execution and
quality workflow templates from its scope (Flywheel non-goal NG1). The
quality phase needs an owner outside it.

## Quality classes §spec:quality-classes
*Status: not started*

Every required quality check is named `quality / <class>`. The ruleset
template (§spec:ruleset-template) requires two classes:

- `quality / governance` — governance documents conform to the notation
  schema, and markdown lints clean.
- `quality / correctness` — the change builds, static analysis passes
  (linters, type checkers, shellcheck), and tests pass.

A repository may emit further classes, such as `quality / performance`,
`quality / reliability` or `quality / security`. The template shall not
require a class until every adopter can produce it with real signal.

**Why two required classes:** a required name that a repository cannot
emit blocks every pull request there. A job that passes without
checking anything clears the gate with a false signal. Detail within a
class comes from the jobs it depends on (§spec:summary-jobs), which
report individually in the checks list.

**Why a class name, not a job name:** job names change with
implementation — a matrix entry, a reusable workflow's internal job, a
renamed job. A ruleset keyed to them drifts with every such change,
which is the failure §spec:problem describes.

**Tradeoff accepted:** adding a required class later touches every
adopter twice — once to emit it, once to reapply the ruleset.

## Summary jobs §spec:summary-jobs
*Status: not started*

An adopting repository emits each required class from exactly one
summary job whose display name is the class's check name. The summary
job shall:

- run in a workflow triggered by both `pull_request` and `merge_group`;
- depend on every job that implements the class;
- run whatever the outcome of those jobs;
- fail when any of those jobs failed or was cancelled;
- succeed without class work on Flywheel's release, back-merge and
  promotion commits, as Flywheel's `classify` action identifies them.

**Why always run, and fail explicitly:** GitHub treats a skipped
required check as passing. A summary job left to its default skips when
a dependency fails, and the pull request merges.

**Why `merge_group`:** in a merge queue, a required check without a
`merge_group` trigger never reports, and the queue stalls.

**Why a local summary job, not a direct reusable workflow call:** a
reusable workflow call reports as `<caller job> / <called job>`, so the
called workflow would dictate the required name. One call also reaches
one workflow and cannot include a repository's own jobs, such as a
build against a private SDK.

**Why Flywheel's classifier:** Flywheel owns the shape of its own
commits. Matching commit messages in each repository duplicates that
knowledge and drifts when Flywheel changes it.

**Rejected — required workflows:** a ruleset can require a whole
workflow to pass, but only in an organization ruleset, which a user
account cannot have (§spec:ruleset-template).

## Stack implementations §spec:stack-implementations
*Status: not started*

This repository publishes a reusable correctness workflow per stack:
Python, and Dart with Flutter. An adopter's `quality / correctness`
summary job depends on its stack workflow's jobs and on any jobs the
repository adds for itself. symphonize's reusable governance lint
implements `quality / governance`.

Stack workflows are versioned with release-please under a floating
major tag. Adopters pin a commit SHA with the version as a trailing
comment, and Dependabot proposes each bump.

**Why a public repository:** adopters span owners, and GitHub shares a
private repository's reusable workflows only with repositories of the
same owner.

**Why separate from symphonize:** symphonize kept the governance schema
in-house because that schema is symphonize-specific (symphonize SPEC,
"Plugin decomposition"). Correctness is not: its consumers need no
symphonize governance, and it carries language toolchains that update
on their own schedules. Keeping it apart means a Flutter toolchain bump
does not cut a notation release.

**Why the implementation stays out of the ruleset:** a stack workflow
may add, rename or remove jobs without any adopter touching its
ruleset, because only the summary job's name is required.

## Ruleset template §spec:ruleset-template
*Status: not started*

Every adopter carries the same four rulesets:

| Ruleset | Targets | Rules | Bypass |
|---|---|---|---|
| Loss prevention | default branch | no deletion, no force push | none |
| Review | default branch | pull request with zero approvals; required checks `flywheel/conventional-commit`, `quality / governance`, `quality / correctness`, from any source, not strict | Flywheel App |
| Tag namespace | `v*`, `*/v*` tags | no deletion, no force push | Flywheel App |
| Required signatures | default branch | signed commits | Flywheel App |

The owner's Flywheel App ID is the template's only variable. A
multi-stream repository also targets its Flywheel-managed branches,
read from its `.flywheel.yml`, beside the default branch.

**Why the App ID varies:** Flywheel requires each adopter to create a
private App of its own (Flywheel ADR 0002), so each owner's App has a
different ID.

**Why any source:** when the App key is unavailable, as on a Dependabot
pull request without a Dependabot-store copy of the key, Flywheel posts
`flywheel/conventional-commit` with the workflow token. A check pinned
to the App rejects that post and blocks the pull request indefinitely.

**Security tradeoff of any source:** a collaborator with write access
could add a job that reports a required name and always passes. That
job appears in the pull request diff, where review catches it. Pull
requests from forks receive a read-only token and cannot post checks.

**Why the default branch by alias:** `~DEFAULT_BRANCH` holds for a
repository whose default branch is not `main`, so the template needs no
per-repository branch name.

**Rejected — organization rulesets:** a user account cannot have them,
and an organization needs a Team or Enterprise plan.

**Rejected — GitHub's ruleset export and import:** an export embeds the
App's actor ID, so a file exported under one owner does not import
correctly under another.

## Ruleset application §spec:ruleset-application
*Status: not started*

Applying the template to a repository is idempotent. It creates missing
rulesets, updates existing ones in place by name, and removes rulesets
the template supersedes. An audit mode reports each repository whose
live rulesets differ from the template, without changing anything.

Flywheel's `apply-rulesets.sh` applies the template. This repository
publishes the template as data and does not fork the tool. Flywheel's
script needs five changes first, raised upstream:

- `--required-checks` extends the default `flywheel/conventional-commit`
  rather than replacing it, as the script's own usage text describes.
- Required checks and targets come from a file, so every adopter reads
  one list.
- Targets include `~DEFAULT_BRANCH`.
- A required-signatures ruleset is part of the applied set.
- An audit mode compares live rulesets against the file.

**Why audit separately from apply:** drift is the failure this
repository exists to prevent. A report listing every divergent
repository shows the scale of a change before anything is applied.
