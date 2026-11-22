# Rulesets, applied

The repo is public, so GitHub Free applies these. `.githooks/pre-push` still refuses the same pushes
before they leave the mac.

What they enforce:

- `develop.json`, `staging.json`, `production.json`: no direct push, no force
  push, no deletion. The only way in is a pull request whose `ci-ok` passed.
  `bypass_actors` is empty, so this applies to the repo owner too. `staging` and
  `production` take merge commits only, a squash drops the dev tag the staging
  version is read from.
- `version-tags.json`: nobody may move or delete a `v*` tag. Creating one is
  not blocked, on a personal repo GitHub refuses the GitHub Actions app as a
  bypass actor, so blocking creation would also block `release-on-merge.yml`.

## Apply or update

1. `gh auth refresh -h github.com -s workflow`
2. Make sure `ci.yml` with the `ci-ok` job is already on `develop`. A PR from a
   branch older than that can never report `ci-ok` and would be stuck forever.
3. `./apply.sh`. It creates what is missing and updates what exists, matched on
   the `name` field.
4. Rebase any open PR onto `develop` so it picks up `ci-ok`.
