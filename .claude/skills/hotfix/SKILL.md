---
name: hotfix
description: >-
  Ship an urgent fix without waiting for a full release: decide whether it
  can go out as a Shorebird code-push patch or needs a full release, then
  drive whichever path applies. Use when the user says "hotfix", "patch this
  out", "push a quick fix", or similar. Sibling to [[promote]] — this is the
  fast lane, promote is the normal ladder.
---

# Hotfix

A hotfix is urgent: something is broken in an already-shipped build and
testers/users need the fix now, not at the next planned release.

There are two ways out, and picking the wrong one either fails outright or
silently doesn't ship what the user thinks it shipped. Decide first.

## Step 0 — is this production?

**Only `production` can be patched.** Dev and staging are built with plain
`flutter build` (see `deploy.yml`) and are not patchable on purpose, a new
`-dev.N` / `-stag.N` tag already ships them in minutes.

If the broken branch is `develop` or `staging`: skip straight to "Full
release" below, PR the fix in and let CI cut the next tag for that stage. Do
not offer a patch, it will not work.

## Step 1 — can this be a patch?

A **Shorebird patch** ships in minutes with no reinstall, but it can only
change Dart code, assets, and `--dart-define` values. Look at the diff for
the fix:

| The fix touches | Patchable? |
| --- | --- |
| Dart code only (`lib/**`) | ✅ Yes |
| Assets | ✅ Yes |
| A pure-Dart dependency version bump | ✅ Yes |
| Android/iOS native code (Kotlin, Swift, `android/`, `ios/`) | ❌ No |
| A **new** plugin with native code | ❌ No — compiles, then crashes on device |
| A Flutter SDK version bump | ❌ No |

If anything in the diff falls in the ❌ column, **stop offering a patch**,
tell the user why, and fall through to "Full release" below.

Also refuse a patch if production has never had a `deploy.yml` run produce a
release. Shorebird can only patch a build it originally released.

## Step 2a — Patch (Dart-only fix, production only)

1. Confirm the fix is committed on a `hotfix/*` branch. The pre-push hook
   refuses a direct push to `develop`/`staging`/`production`.
2. Get it onto `production` **by pull request**: `gh pr create --base
   production --head hotfix/<name>`, wait for `ci-ok` (`gh pr checks --watch`),
   then `gh pr merge --merge`. Never merge on red, the rulesets refuse it
   and `release-on-merge.yml` would not ship it. A `hotfix/*` merge into
   production creates **no tag** on purpose, the patch below is what ships.
3. Run the patch workflow from the `production` branch:
   `gh workflow run patch.yml --ref production`. It refuses any other branch,
   the patch must be built from the code that is actually live. There is no
   approval prompt on this plan, so confirm with the user right before running
   it: this goes straight to every production user.
4. **Remind the user to back-merge.** A patch does not create a tag or move
   any other branch. The fix still needs to flow back down
   (`production → staging → develop`) as [[promote]] describes, or the next
   real release brings the bug back.
5. Tell the user how to verify: testers must **fully close and reopen the app
   twice**. Shorebird downloads a patch in the background and applies it on
   the next cold start, not instantly.

## Step 2b — Full release (native/plugin/Flutter-version fix)

A patch cannot help here. This is a normal, urgent trip through
[[promote]]'s ladder, hand off to that skill, but flag that it is
time-sensitive so the user doesn't sit on the staging step.

## Notes

- Never suggest skipping verification to go faster. A bad patch is much
  harder to walk back than a bad full release.
- Never `git push` a protected branch, never `git tag`, never `--no-verify`.
  An urgent fix is not a reason to go around the gate.
- No attribution trailers on any commit this skill makes.
- If unsure whether a change is native or Dart-only, check rather than guess:
  `git diff --stat` against `android/`, `ios/`, and `pubspec.yaml`'s
  dependency versions is enough to tell.
