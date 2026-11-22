---
name: promote
description: >-
  Move code up the release ladder (develop -> staging, or staging ->
  production) by opening the promotion PR, waiting for CI, and merging it.
  Use when the user says "promote", "ship to staging", "cut a release",
  "release to production", or similar. Not for day-to-day feature merges
  into develop — those need no gate and ship nothing.
---

# Promote (develop → staging → production)

This app ships on **tags**, but **nobody makes a tag by hand**. The pre-push
hook refuses direct pushes to `develop`, `staging`, `production` and any `v*`
tag, and `release-on-merge.yml` only tags a merged PR whose `ci-ok` was green.
The only way up the ladder is a merged pull request.

So this skill never runs `git push origin staging`, never runs `git tag`, and
never runs `git merge` on a protected branch. It opens a PR and merges it.

The repo is public and its rulesets refuse a merge without a green `ci-ok`.
**Never merge on red** or try to get around them.

One version line runs through all three stages, the stage is a suffix:

```
v1.3.0-dev.1  →  v1.3.0-dev.2  →  v1.3.0-stag.1  →  v1.3.0
   develop           develop          staging      production
```

## Which direction?

Read the current branch to figure out the move:

| Current branch | Target | Tag that CI will create |
| --- | --- | --- |
| `develop` | `staging` | next `-stag.N` on the version line the newest dev tag is on |
| `staging` | `production` | `vx.y.z` from the top `CHANGELOG.md` entry |

If the current branch is neither, ask the user which promotion they mean.

## Merge-direction rules (enforce here too, not just in CI)

| Into | Allowed from |
| --- | --- |
| `develop` | anything |
| `staging` | `develop`, `production` (back-merge), `hotfix/*` |
| `production` | `staging`, `hotfix/*` — **never `develop` directly** |

If the move isn't in this table, refuse and explain why. CI's `merge-guard`
enforces it too, this check stops a bad promotion before it is even a PR.

## Promote: develop → staging

1. `git fetch` and confirm `origin/develop` has a `v*-dev.*` tag on it
   (`git describe --tags --match 'v*-dev.*' --abbrev=0 origin/develop`). If it
   has none, stop: there is no version line to promote, ship a dev build first.
2. Work out the tag CI will create, so the user sees it before agreeing:
   version line from that dev tag, counter = `1 +` the highest existing
   `vX.Y.Z-stag.*` (or `1`).
3. **Ask the user:** promote `develop → staging` (CI will tag `<new-tag>`), or
   cancel? Exactly these two options, no silent default.
   - **Cancel** → stop, nothing changes.
4. Open the PR: `gh pr create --base staging --head develop --title "promote:
   develop → staging" --body "<short summary of what is going up>"`. The PR
   title becomes the first line of the tag message, so write a real one.
5. Wait for CI: `gh pr checks --watch`. If `ci-ok` fails, stop and report it.
6. Merge it: `gh pr merge --merge`. Then tell the user the run to watch
   (`gh run list --workflow=release-on-merge.yml --limit 1`).
7. Do **not** add a `release:` commit to this PR. Only PRs into `develop` use
   those; on `staging` and `production` they are ignored.
8. No `pubspec.yaml` change and no `CHANGELOG.md` entry here, those wait for
   production.

## Promote: staging → production

This is the only place `CHANGELOG.md` and `pubspec.yaml` change, and the
CHANGELOG is not cosmetic: **the top entry's version number is what CI turns
into the release tag.** It needs the user's explicit sign-off before anything
is written.

1. `git fetch` and confirm `origin/staging` is where the release should come
   from.
2. Find the last production version: `git tag --list 'v[0-9]*' --sort=-v:refname`
   filtered to tags with no `-dev.`/`-stag.` suffix. None yet means this is the
   first release.
3. **Ask the user:** which part to bump — MAJOR, MINOR, or PATCH — to get the
   new version (e.g. `1.2.0` → `1.3.0`). Or cancel.
   - **Cancel** → stop here, nothing changes.
4. **Draft the CHANGELOG entry.** Read every commit between the last
   production tag and `origin/staging` (`git log <last-prod-tag>..origin/staging
   --no-merges`). Write a `## [x.y.z] - YYYY-MM-DD` block in the same voice as
   the existing entries: a short human paragraph, then a few plain bullet
   points, written for the person installing the app, not a commit dump. This
   text becomes the tag message, the GitHub Release body and the tester notes.
5. **Show the draft and stop. Wait for the user.**
   - **Approve** → continue to step 6.
   - **Edit** → revise per feedback, show again, repeat until approved.
   - **Cancel** → stop, nothing changes.
6. The bump travels **up the ladder like everything else**, it is not pushed
   onto `staging`. Branch off `develop` (e.g. `release/x.y.z`), insert the
   approved block at the top of `CHANGELOG.md`, bump `pubspec.yaml`'s
   `version:` to `x.y.z+n` (CI overrides the build number with the run number
   anyway), and commit both together as `chore: release x.y.z` (no attribution
   trailers). PR it into `develop` with no `release:` marker commit, so it lands
   without shipping a dev build.
7. Run the `develop → staging` promotion above so `staging` now carries the
   bumped CHANGELOG.
8. Open the production PR: `gh pr create --base production --head staging
   --title "release: x.y.z" --body "<the approved CHANGELOG block>"`.
9. Wait for `ci-ok` (`gh pr checks --watch`), then `gh pr merge --merge`.
10. CI tags `vx.y.z` and calls `deploy.yml`, which builds through Shorebird,
    uploads symbols to Sentry, creates the GitHub Release with the `.aab` and
    sends a universal APK to testers. Tell the user the last step is theirs:
    download the `.aab` from the GitHub Release and upload it to Play by hand.

If the merge lands and `release-on-merge` fails with *tag already exists*, the
CHANGELOG was not bumped. Fix the CHANGELOG on a new PR, do not tag by hand.

## After a hotfix

If a `hotfix/*` branch was merged into `staging` or `production`, remind the
user to back-merge that fix down so it isn't lost on the next promotion:
`hotfix → production` needs `production → staging` and `staging → develop`
afterward. Those back-merges are PRs too.

## Notes

- Never `git push` a protected branch and never `git tag`, and never bypass
  the pre-push hook with `--no-verify`. Working around the gate is the one
  thing this flow exists to stop.
- No attribution trailers on any commit this skill makes.
- If a step would fail (dirty working tree, merge conflict, diverged branch),
  stop and report it rather than forcing past it.
- Full picture of the flow: `.github/RELEASES.md`.
