# dart_define — two tiers of config

The repo is private today, but private repos get shared, forked or made public
later, and anything committed stays in git history forever. So config is split
the same way a public repo would need it.

## Tier 1 — `<flavor>.json` (committed)

Non-secret selectors only.

```json
{
  "FLAVOR": "dev",
  "APP_NAME": "My App Dev"
}
```

## Tier 2 — `<flavor>.secret.json` (git-ignored, never committed)

Values that must not sit in the repo. Same shape, different file:

```json
{
  "SENTRY_DSN": "https://<key>@o0.ingest.sentry.io/<project>"
}
```

Ignored by `/dart_define/*.secret.json` in `.gitignore`. In CI it is written at
build time from a GitHub secret and deleted after the build. CI adds
`SENTRY_RELEASE` next to the DSN, so the app and its background engines report
the same version.

## How both get passed

`--dart-define-from-file` can be repeated, Flutter merges them:

```bash
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=dart_define/dev.json \
  --dart-define-from-file=dart_define/dev.secret.json
```

**The secret file is optional.** Without it `SENTRY_DSN` is empty and Sentry
stays off. That is the right state for local work anyway, monitoring is
release-mode only (`lib/core/monitoring/monitoring.dart`).

## Do NOT use `.env` / flutter_dotenv for secrets

`flutter_dotenv` ships `.env` as a Flutter asset, a plain file inside the APK:

```bash
unzip -p app.apk assets/flutter_assets/.env   # prints your "secrets"
```

`--dart-define` compiles values into the binary instead. Still extractable with
`strings`, but not handed over in one command.

**Neither is actually secure.** Nothing shipped inside a mobile app can be kept
from a determined user. A real secret (keystore, CI token, service account) is
never in the app or the repo, only in GitHub secrets. Client identifiers like a
Sentry DSN are protected by server-side limits, not by hiding them.
