# Rulesets

The four repository rulesets every adopter carries. Each file is the
request body for `POST /repos/{owner}/{repo}/rulesets`.

| File | Ruleset |
| --- | --- |
| `loss-prevention.json` | Loss prevention: no deletion or force push on the default branch |
| `review.json` | Review: pull request and pinned required checks on the default branch |
| `tag-namespace.json` | Tag namespace: no deletion or force push on `v*` and `*/v*` tags |
| `required-signatures.json` | Required signatures: signed commits on the default branch |

## Placeholder

The owner's Flywheel App ID is the one variable. Each file holds the
string `"${FLYWHEEL_APP_ID}"` where GitHub expects that integer, as a
bypass `actor_id` and as the `integration_id` of
`flywheel/conventional-commit`. Replace the quoted placeholder with the
bare integer before sending a file:

```sh
sed 's/"${FLYWHEEL_APP_ID}"/'"$APP_ID"'/g' rulesets/review.json |
  gh api -X POST repos/<owner>/<repo>/rulesets --input -
```

`15368` is the GitHub Actions integration, the same for every owner.
