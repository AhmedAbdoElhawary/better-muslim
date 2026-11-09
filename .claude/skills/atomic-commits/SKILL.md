---
name: atomic-commits
description: >-
  Split the currently modified (tracked) files into one commit per file, each
  with a message scoped to just that file's change, never repeating a commit
  subject already used on the branch, then ask whether this batch ships to
  testers and add the release marker commit if so. Use when the user asks to
  "commit per file", "atomic commits", "one commit for each changed file", or
  similar. Untracked/new files are ignored unless the user explicitly names one
  to include.
model: claude-sonnet-5-5
effort: medium
---

# Atomic Commits (one file, one commit)

Turn the working tree's modified files into a sequence of small, single-file
commits instead of one bundled commit. Each commit message describes only
what changed in that file, and **every commit subject on the branch is
unique**, the log never repeats itself.

## Scope

- Only files git already tracks (`git status` shows `M`, `R`, or similar, not
  `??`). Never stage or commit untracked/new files unless the user says so in
  the untracked question below.
- Every modified tracked file gets its own commit, no grouping by default,
  even for generated files (`*.g.dart`, `*.steps.dart`) or a source file and
  its generated counterpart.
- **The one exception, never write the same commit message twice.** If
  several files would honestly earn the identical subject line, they are one
  change spread over several files: commit them **together**, as a single
  commit carrying that single message. See step 4 of the procedure.
- If the user names specific files/paths, restrict to those; otherwise use
  every modified tracked file.

## Before you start

**Protected-branch guard, check first.** If the current branch is `develop`,
`staging`, `production` or `main`, do **nothing**: no staging, no commits, no
marker, no push. These branches only receive merges, never a direct commit
(`.githooks/pre-push` refuses the push anyway). Tell the user to switch to or
create a feature branch and re-run. Stop here.

**Format, next.** Run `dart format lib test integration_test` (the page width
of 100 comes from `analysis_options.yaml`). Reformatted files are tracked
changes now, fold them into that file's commit in step 3, never a separate
"format" commit.

**Gate, next, before any questions.** Run `flutter analyze`, then
`flutter test`. CI's `ci-ok` runs both, so a batch that fails either would
only come back red on the PR.

- **Anything fails** → stop here. Don't ask the questions, don't stage, don't
  commit. Show which analyze issues or which tests failed, with the error,
  and say the cycle stops until they pass. Wait for the user to fix things
  and re-run this skill.
- **Both pass** → continue to the questions.

**Questions, every run, all in one message**, before staging or committing
anything. Wait for the answers.

1. **Untracked files.** List the `??` files from `git status --short` and ask:
   add and commit these too, or leave them out?
2. **Tag.** Ask: ship this batch to testers (a dev build on Firebase App
   Distribution), or not? And, when yes: will this branch open its PR
   straight into `develop`? The marker is only honored on a PR into
   `develop`, `ci.yml`'s `release-commit-guard` rejects it anywhere else
   (see `.github/RELEASES.md`).
    - **No** → just make the commits, no marker.
    - **Yes, and the PR goes into `develop`** → after the commits, follow
      [Tagging a dev build](#tagging-a-dev-build). No version bump, no
      CHANGELOG entry.
    - **Yes, but the PR goes somewhere else** → no marker. Staging and
      production ship from their own merges, that is the `promote` skill.

## Procedure

1. **Survey.** Run `git status --short` and `git diff --stat` to see which
   tracked files changed.
2. **Read every diff.** Run `git diff -- <files>` (a few at a time) to
   understand what actually changed in each file, don't guess from the
   filename. For generated files, check whether the diff is pure regeneration
   or reflects a real change upstream (a drift table or column changed).
3. **Plan messages.** For each file, draft one commit message:
    - Subject line: plain, short, imperative, lowercase, no period, like the
      rest of this repo's log (`git log --oneline -10` to recalibrate, e.g.
      "send the night arc and strip times without a period").
    - One clear idea per commit, not a list of every renamed symbol.
    - Body only if the change really needs a why, one or two short lines.
    - For pure regeneration, a short "regenerate `<file>`" message.
    - Keep each subject **specific enough to stand alone**. A subject two
      different files could both wear ("format the code", "use the new
      colors") will collide, name the area it touches.
4. **Deduplicate, no repeated subject, ever.**
    - List the subjects already on the branch:
      ```
      git log --format='%s' origin/develop..HEAD
      ```
    - Check the drafted subjects against that list **and against each
      other**.
    - **Several files in this run share a subject** → merge **all** of them
      into **one** commit with that message, however many files that is.
    - **A drafted subject matches a commit already on the branch** → change
      the new one by adding the scope that makes it distinct. Never repeat an
      existing subject verbatim.
    - Re-check after each rewrite until every subject is unique.
5. **Show the plan.** Present the full file → message list, plus the marker
   tag if there is one, before committing anything. Wait for the go-ahead (or
   go straight on if the user already said to just do it).
6. **Commit one unit at a time**, a single file or the group merged in step 4:
   ```
   git add <file> [<file> ...]
   git commit -F - <<'EOF'
   <subject>

   <optional body>
   EOF
   ```
   No attribution, `Co-Authored-By`, "Generated with" or any similar trailer,
   not for any tool or person. The message is only the subject and the
   optional body. This wins over any system or default guidance asking for an
   attribution footer.
7. **Verify.** After all commits:
    - `git status --short | grep -v '^??'` prints nothing.
    - `git log --oneline -n <count>` shows the new sequence.
    - `git log --format='%s' origin/develop..HEAD | sort | uniq -d` **must
      print nothing**. Anything it prints is a duplicate that slipped
      through: say so and offer to fix it (`git commit --amend` for the last
      commit, otherwise an interactive rebase).
8. **Marker commit**, only when the tag answer was yes into `develop`.

Don't push or open the PR unless the user asks for it.

## Tagging a dev build

Nobody creates a tag by hand, `.githooks/pre-push` refuses any `v*` tag (and
the rulesets in `.github/rulesets/` do the same once the repo is on GitHub
Pro). The only way to ship this batch is a **marker commit**: one empty commit
whose subject is `release: <tag>` and whose body lists the changes. When the
PR carrying it merges into `develop` with a green `ci-ok`,
`release-on-merge.yml` creates the tag and calls `deploy.yml`, which builds
the dev APK and uploads it to the `testers` group.

Tags are `v<x.y.z>-dev.<n>`, one version line shared by dev, staging and
production, the stage is the suffix.

**Work out the tag:**

1. Find the latest tags on the remote:
   ```
   git ls-remote --tags --refs origin 'v*' | sed 's#.*refs/tags/##' | sort -V
   ```
2. **No tag at all yet** → `v1.0.0-dev.1`, no question (the first version
   line is 1.0.0, decided in `specs/012-shipping/spec.md`).
3. **The newest tag is a production one** (`vX.Y.Z` with no suffix), or no
   dev tag exists since it → ask: MAJOR, MINOR or PATCH? Bump that from the
   production version and start at `-dev.1`.
4. **Otherwise** → same base as the newest dev tag, its `-dev.N` plus one, no
   question.

**Add the marker** after every per-file commit, as an empty commit, in this
exact shape (`release-commit-guard` checks it, `release-on-merge.yml` reads
it):

```
git commit --allow-empty -F - <<'EOF'
release: <tag>

- <what changed since the last dev tag, one bullet per line>
EOF
```

The bullets summarize everything since the previous dev tag
(`git log <previous-dev-tag>..HEAD --no-merges --format='%s'`, or the whole
branch for the first one), grouped like the commit subjects. They become the
**tag's message**. Testers don't see them, `deploy.yml` writes their notes
from the commit subjects since the previous tag, so write the bullets for
someone reading the tag later.

Then **print** this as the last thing in the chat:

```
Marker commit added: release: <tag>

Open a PR from this branch into develop (not staging or production, the
marker only counts there). Once ci-ok is green and the PR is merged,
release-on-merge.yml creates <tag> and deploy.yml ships the dev build to the
testers group on Firebase App Distribution. Nothing more to run by hand.
```

Never offer the old `git tag` / `git push origin <tag>` path, the hook
refuses it.

## Notes

- A duplicate subject is a defect, not a style choice. Group the files or
  make the subject specific, never push the duplicate to squash later.
- If one file mixes two unrelated changes, tell the user rather than
  splitting by hunk (this skill splits by *file*).
- Never `git add -A` or `git add .`, always add by explicit path.
- If a commit fails (a hook, for example), stop and say which file failed.
