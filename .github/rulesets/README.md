# Rulesets — not applied yet

These need **GitHub Pro** (or Team) on a private repo. On GitHub Free they can't
be applied, so today the same rules are enforced by:

- `.githooks/pre-push` refuses a direct push to `develop`, `staging`,
  `production` and any `v*` tag, on this machine.
- `release-on-merge.yml` refuses to tag a PR whose `ci-ok` was not green, so a
  red merge never ships.

The files stay here so the switch is one command the day the plan changes.

What they enforce once applied:

- `develop.json`, `staging.json`, `production.json`: no direct push, no force
  push, no deletion. The only way in is a pull request whose `ci-ok` passed.
  `bypass_actors` is empty, so this applies to the repo owner too.
- `version-tags.json`: nobody may move or delete a `v*` tag. Creating one is
  not blocked, on a personal repo GitHub refuses the GitHub Actions app as a
  bypass actor, so blocking creation would also block `release-on-merge.yml`.

## Apply (after upgrading)

1. `gh auth refresh -h github.com -s workflow`
2. Make sure `ci.yml` with the `ci-ok` job is already on `develop`. A PR from a
   branch older than that can never report `ci-ok` and would be stuck forever.
3. `./apply.sh`. It creates what is missing and updates what exists, matched on
   the `name` field.
4. Rebase any open PR onto `develop` so it picks up `ci-ok`.
