# Releases

Everything this app ships comes from a tag, and every tag is made by CI after a
pull request merges. Use the `promote` and `hotfix` skills, they drive exactly
this flow.

## The locks

The repo is private on GitHub Free, so GitHub itself can't refuse a push or
require a check. The locks are:

| What | Enforced by |
| --- | --- |
| No direct push to `develop`, `staging`, `production` | `.githooks/pre-push` (run `git config core.hooksPath .githooks` once per clone) |
| No hand-made `v*` tag | `.githooks/pre-push` |
| A red PR never ships | `release-on-merge.yml` refuses to tag unless the PR's `ci-ok` was green |
| A tag on the wrong branch never ships | the `guard` job in `deploy.yml` |

The merge button still works on a red PR. Don't press it: the code lands and
nothing ships, and the next release carries it anyway. The real rulesets are in
`.github/rulesets/`, ready for the day the plan changes.

## The ladder

```
feature/x ──PR──► develop ──PR──► staging ──PR──► production
             │              │               │
          ci.yml         ci.yml          ci.yml
             │              │               │
        release: tag?   always tag      always tag
        → v1.0.1-dev.16 → v1.0.1-stag.1 → v1.0.1 + GitHub Release
             └──────────────┴───────────────┴──► deploy.yml
```

One version line runs through all three stages, the stage is a suffix:

| Tag | Flavor | Secrets prefix | Goes to |
| --- | --- | --- | --- |
| `v1.3.0-dev.2` | dev | `DEV_` | App Distribution, dev app |
| `v1.3.0-stag.1` | staging | `STAGING_` | App Distribution, staging app |
| `v1.3.0` | production | `PROD_` | GitHub Release (.aab) + App Distribution, production app |

Who may merge into what (`merge-guard` in `ci.yml`):

| Into | Allowed from |
| --- | --- |
| `develop` | anything |
| `staging` | `develop`, `production` (back-merge), `hotfix/*` |
| `production` | `staging`, `hotfix/*`, never `develop` directly |

## PR into `develop`

`ci.yml` runs `merge-guard`, `release-commit-guard`, `quality`, `build-android`
and rolls them into **`ci-ok`**.

A merge into `develop` ships **nothing** unless the PR carries a release
marker: one commit whose subject is the tag and whose body is the tag message,
one bullet per change group.

```bash
git commit --allow-empty -F - <<'EOF'
release: v0.1.0-dev.2

- add login screen
- fix crash on empty list
EOF
```

`release-commit-guard` checks it before the merge: right shape, non-empty body,
at most one per PR, not a tag that already exists.

## PR into `staging`

No marker commit. Every merge ships. The version line comes from the newest
`v*-dev.*` tag on the merge commit, the `-stag.N` counter is bumped. The tag
message is the PR title plus the commits since the previous staging tag, so give
the promotion PR a real title.

PRs into `staging` and `production` also run `build-ios` (compile check only)
and `integration` (emulator journeys). They cost the most minutes, so develop
PRs skip them.

## PR into `production`

No marker commit. The version comes from the **top `CHANGELOG.md` entry**, and
its body becomes the tag message, the GitHub Release body and the tester notes.
A production PR must bump `CHANGELOG.md` first, if it doesn't,
`release-on-merge.yml` stops with *tag already exists*. That is intended.

`deploy.yml` then builds through Shorebird, uploads symbols to Sentry, and
creates the GitHub Release with the `.aab` attached. Nothing uploads to Google
Play: download that `.aab` and upload it by hand.

## Hotfixes

`hotfix/*` may PR straight into `staging` or `production`. A hotfix merge into
`production` creates no tag, the Shorebird patch from `patch.yml` ships it. It
only works for Dart-only fixes, the `hotfix` skill has the full rule.

Back-merge afterwards (`production → staging → develop`), by PR, or the next
release brings the bug back.

## Secrets and variables

`tool/accounts_wizard.sh` sets everything below except the keystore. Run it from
the repo root, it can be re-run and keeps what is done.

All are **repository** secrets/variables (Settings → Secrets and variables →
Actions). GitHub Free has no environment secrets on a private repo, so values
that differ per flavor carry a prefix.

| Name | Type | Value |
| --- | --- | --- |
| `DEV_FIREBASE_APP_ID` | secret | the `1:...:android:...` id of the dev app in Firebase |
| `STAGING_FIREBASE_APP_ID` | secret | same, staging app |
| `PROD_FIREBASE_APP_ID` | secret | same, production app |
| `DEV_GOOGLE_SERVICES_JSON` | secret | the dev Android app's `google-services.json`, raw text |
| `STAGING_GOOGLE_SERVICES_JSON` | secret | same, staging app |
| `PROD_GOOGLE_SERVICES_JSON` | secret | same, production app |
| `DEV_GOOGLE_SERVICE_INFO_PLIST` | secret | the dev iOS app's `GoogleService-Info.plist`, raw text |
| `STAGING_GOOGLE_SERVICE_INFO_PLIST` | secret | same, staging app |
| `PROD_GOOGLE_SERVICE_INFO_PLIST` | secret | same, production app |
| `FIREBASE_SERVICE_ACCOUNT` | secret | JSON key of a service account with the *Firebase App Distribution Admin* role |
| `DEV_SENTRY_DSN` | secret | Sentry DSN for dev builds |
| `STAGING_SENTRY_DSN` | secret | Sentry DSN for staging builds |
| `PROD_SENTRY_DSN` | secret | Sentry DSN for production builds |
| `ANDROID_KEYSTORE_BASE64` | secret | `base64 < upload.jks \| tr -d '\n'` |
| `ANDROID_KEYSTORE_PASSWORD` | secret | keystore password |
| `ANDROID_KEY_ALIAS` | secret | key alias |
| `ANDROID_KEY_PASSWORD` | secret | key password |
| `SHOREBIRD_TOKEN` | secret | Shorebird console → Account → API Keys |
| `SENTRY_AUTH_TOKEN` | secret | Sentry → Settings → Auth Tokens, an organization token (`sntrys_...`) |
| `SENTRY_PROJECT` | variable | slug of the Sentry project behind `PROD_SENTRY_DSN` |
| `SENTRY_ORG` | variable | only needed if `SENTRY_AUTH_TOKEN` is a personal token |
| `SENTRY_URL` | variable | optional, overrides the region URL in `deploy.yml` |
| `FIREBASE_TESTER_GROUPS` | variable | optional, default `testers` |

The same DSN in all three Sentry secrets is fine, every event is tagged with
its flavor as the Sentry environment.

## Why deploy is *called*, not triggered

A tag pushed with `GITHUB_TOKEN` deliberately does not fire another workflow's
`on: push`. So `deploy.yml` is a reusable workflow and `release-on-merge.yml`
calls it with the tag it just created. Its `on: push: tags` trigger is kept as
break-glass only, and only that path runs `verify`: a called deploy already
passed `ci-ok`.
