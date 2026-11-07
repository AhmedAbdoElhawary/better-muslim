#!/usr/bin/env bash
#
# A wizard walks a human through a manual procedure, step by step.
#
# Everything above the "STAGES" marker is the wizard library: do not hand-edit
# it. Author the per-step stages below the marker.

set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────
# Wizard library: delightful, consistent UX, identical across every wizard.
# ──────────────────────────────────────────────────────────────────────────

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
  BOLD=$(tput bold); DIM=$(tput dim); RESET=$(tput sgr0)
  BLUE=$(tput setaf 4); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
else
  BOLD=""; DIM=""; RESET=""; BLUE=""; GREEN=""; YELLOW=""
fi

# Author sets this at the top of the stages section.
TOTAL_STAGES=0

_STAGE_INDEX=0
ENV_FILE="${ENV_FILE:-.env}"
WRITTEN_ENV=()    # KEYs written to ENV_FILE this run
WRITTEN_SECRET=() # secret NAMEs set this run
SKIPPED=()        # things we couldn't do (e.g. gh missing)

# _clear wipes the terminal so only the current step is on screen. No-op when
# output isn't a terminal, so piped logs stay readable.
_clear() {
  [[ -t 1 ]] || return 0
  if command -v tput >/dev/null 2>&1 && tput clear 2>/dev/null; then return 0; fi
  printf '\033[2J\033[3J\033[H'
}

# banner "Title" shows the opening frame: what this wizard does.
banner() {
  _clear
  printf '\n%s%s  %s%s\n' "$BOLD" "$BLUE" "$1" "$RESET"
  printf '%s  %s stages%s\n\n' "$DIM" "$TOTAL_STAGES" "$RESET"
  printf '%s  You drive the browser; this wizard tells you exactly what to do and\n' "$DIM"
  printf '  captures the values you copy back. Stop any time with Ctrl-C and re-run\n'
  printf '  later, since it remembers values already saved.%s\n' "$RESET"
  pause "Ready to start?"
}

# stage "Name" clears the screen, then announces a stage and shows progress.
# Clearing keeps only the current step on screen.
stage() {
  _clear
  _STAGE_INDEX=$((_STAGE_INDEX + 1))
  printf '\n%s%s▸ Stage %s/%s · %s%s\n' \
    "$BOLD" "$BLUE" "$_STAGE_INDEX" "$TOTAL_STAGES" "$1" "$RESET"
}

# say "..." prints a plain instruction line.
say()  { printf '  %s\n' "$1"; }
# step "..." is a numbered-feeling action the human takes in the browser.
step() { printf '  %s•%s %s\n' "$BLUE" "$RESET" "$1"; }
note() { printf '  %s%s%s\n' "$DIM" "$1" "$RESET"; }
warn() { printf '  %s⚠ %s%s\n' "$YELLOW" "$1" "$RESET"; }

# open_url URL opens it in the human's browser, cross-platform incl. WSL.
open_url() {
  local url="$1"
  printf '  %s↗ opening%s %s\n' "$GREEN" "$RESET" "$url"
  { if   command -v wslview     >/dev/null 2>&1; then wslview "$url"
    elif command -v explorer.exe >/dev/null 2>&1; then explorer.exe "$url"
    elif command -v xdg-open    >/dev/null 2>&1; then xdg-open "$url"
    elif command -v open        >/dev/null 2>&1; then open "$url"
    else false; fi
  } >/dev/null 2>&1 || warn "couldn't open a browser, so visit it manually: $url"
}

# pause "msg" waits for the human to confirm they've done the manual part.
pause() {
  printf '  %s%s%s ' "$DIM" "${1:-Press Enter to continue}" "$RESET"
  read -r _ || true
}

# confirm "question" is a y/N gate; returns success on yes.
confirm() {
  local reply=""
  printf '  %s? %s [y/N] ' "$YELLOW" "$1"
  read -r reply || true
  [[ "$reply" =~ ^[Yy] ]]
}

# _existing KEY: current value of KEY in ENV_FILE, if any, with write_env's single
# quotes or a plain dotenv double-quoted value undone.
_existing() {
  [[ -f "$ENV_FILE" ]] || return 1
  local line value sq="'\\''"; line=$(grep -E "^${1}=" "$ENV_FILE" | tail -n1) || return 1
  value="${line#*=}"
  if [[ "$value" == \'*\' ]]; then value="${value:1:${#value}-2}"; value="${value//"$sq"/\'}"
  elif [[ "$value" == \"*\" ]]; then
    value="${value:1:${#value}-2}"
    [[ "$value" == *[\\\$\"]* ]] && return 1   # escapes, $ or ": can't decode safely; ask again
  fi
  printf '%s' "$value"
}

# ask KEY "Prompt" reads a value into $KEY. Offers the existing .env value as
# a default on re-runs (Enter keeps it). Visible input (non-secret), edited
# with Readline. Fails at EOF with no input.
ask() {
  local key="$1" prompt="$2" current input s=$'\001' e=$'\002' p rc=0
  current=$(_existing "$key" || true)
  # Readline needs the colour codes wrapped in \001..\002 to place the cursor.
  p="  $s$BOLD$e$prompt$s$RESET$e "
  [[ -n "$current" ]] && p+="$s$DIM$e[Enter keeps current]$s$RESET$e "
  read -e -r -p "$p" input || rc=1
  if (( rc )) && [[ -z "$input" ]]; then return 1; fi
  [[ -z "$input" && -n "$current" ]] && input="$current"
  printf -v "$key" '%s' "$input"
}

# ask_secret KEY "Prompt" is like ask, but input is hidden.
ask_secret() {
  local key="$1" prompt="$2" current input rc=0
  current=$(_existing "$key" || true)
  if [[ -n "$current" ]]; then
    printf '  %s%s%s %s[Enter keeps current]%s ' "$BOLD" "$prompt" "$RESET" "$DIM" "$RESET"
  else
    printf '  %s%s%s ' "$BOLD" "$prompt" "$RESET"
  fi
  read -rs input || rc=1
  printf '\n'
  if (( rc )) && [[ -z "$input" ]]; then return 1; fi
  [[ -z "$input" && -n "$current" ]] && input="$current"
  printf -v "$key" '%s' "$input"
}

# write_env KEY VALUE upserts KEY='VALUE' into ENV_FILE (replaces any existing
# line) and sets $KEY. Idempotent. Creates ENV_FILE at mode 0600; writes through
# a symlink and keeps an existing file's mode.
write_env() {
  local key="$1" value="$2" tmp sq="'\\''"
  [[ -e "$ENV_FILE" ]] || (umask 077 && : > "$ENV_FILE")
  tmp=$(mktemp)
  grep -vE "^${key}=" "$ENV_FILE" > "$tmp" || true
  printf "%s='%s'\n" "$key" "${value//\'/$sq}" >> "$tmp"
  cat "$tmp" > "$ENV_FILE"
  rm -f "$tmp"
  printf -v "$key" '%s' "$value"
  WRITTEN_ENV+=("$key")
  printf '  %s✓ wrote%s %s → %s\n' "$GREEN" "$RESET" "$key" "$ENV_FILE"
}

# set_secret NAME VALUE sets a GitHub Actions repo secret via gh. Falls back
# to a warning (and records it) if gh is unavailable or unauthenticated.
set_secret() {
  local name="$1" value="$2"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    if printf '%s' "$value" | gh secret set "$name" >/dev/null 2>&1; then
      WRITTEN_SECRET+=("$name")
      printf '  %s✓ set%s GitHub secret %s\n' "$GREEN" "$RESET" "$name"
      return
    fi
  fi
  SKIPPED+=("GitHub secret $name (set it manually: gh secret set $name)")
  warn "skipped GitHub secret $name: gh not ready; set it later"
}

# set_var NAME VALUE sets a GitHub Actions repo variable (non-secret).
set_var() {
  local name="$1" value="$2"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    if gh variable set "$name" --body "$value" >/dev/null 2>&1; then
      printf '  %s✓ set%s GitHub variable %s\n' "$GREEN" "$RESET" "$name"
      return
    fi
  fi
  SKIPPED+=("GitHub variable $name")
  warn "skipped GitHub variable $name, gh not ready; set it later"
}

# finish clears, then shows a closing summary of everything configured.
finish() {
  _clear
  printf '\n%s%s  ✓ Setup complete%s\n' "$BOLD" "$GREEN" "$RESET"
  (( ${#WRITTEN_ENV[@]} ))    && note "wrote ${#WRITTEN_ENV[@]} value(s) to $ENV_FILE: ${WRITTEN_ENV[*]}"
  (( ${#WRITTEN_SECRET[@]} )) && note "set ${#WRITTEN_SECRET[@]} GitHub secret(s): ${WRITTEN_SECRET[*]}"
  if (( ${#SKIPPED[@]} )); then
    printf '\n'; warn "still to do by hand:"
    for s in "${SKIPPED[@]}"; do note "  - $s"; done
  fi
  printf '\n'
}

# ──────────────────────────────────────────────────────────────────────────
# STAGES: Firebase, Sentry and Shorebird for better-muslim. Run from the repo root.
# ──────────────────────────────────────────────────────────────────────────

# public ids only, secrets go straight to github and never touch the disk
ENV_FILE=.accounts.env
BUNDLE=com.elhawary.bettermuslim

# grep reads to the end on purpose, -q would break gh's pipe and pipefail would call that a miss
have_secret() { gh secret list --json name --jq '.[].name' | grep -x "$1" >/dev/null; }

# path pasted or dragged in, with its quotes and escapes undone
clean_path() {
  local path="${1%"${1##*[![:space:]]}"}"
  path="${path//\\ / }"; path="${path//\'/}"; path="${path//\"/}"
  printf '%s' "${path/#\~/$HOME}"
}

app_id() {
  firebase apps:list "$1" --project "$FIREBASE_PROJECT" --json 2>/dev/null | python3 -c '
import json, sys
for app in json.load(sys.stdin).get("result", []):
    if sys.argv[1] in (app.get("packageName"), app.get("bundleId")):
        print(app["appId"])
        break
' "$2"
}

save_config() {
  firebase apps:sdkconfig "$1" "$2" --project "$FIREBASE_PROJECT" --json 2>/dev/null | python3 -c '
import json, pathlib, sys
target = pathlib.Path(sys.argv[1])
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.load(sys.stdin)["result"]["fileContents"])
' "$3"
}

# PREFIX flavor "App name" bundle id, the same id on both platforms
setup_flavor() {
  local prefix="$1" flavor="$2" name="$3" id="$4" android ios
  android=$(app_id ANDROID "$id" || true)
  if [[ -z "$android" ]]; then
    firebase apps:create ANDROID "$name" --package-name "$id" --project "$FIREBASE_PROJECT" >/dev/null 2>&1 || true
    android=$(app_id ANDROID "$id" || true)
  fi
  ios=$(app_id IOS "$id" || true)
  if [[ -z "$ios" ]]; then
    firebase apps:create IOS "$name" --bundle-id "$id" --project "$FIREBASE_PROJECT" >/dev/null 2>&1 || true
    ios=$(app_id IOS "$id" || true)
  fi
  if [[ -z "$android" || -z "$ios" ]]; then
    SKIPPED+=("Firebase apps for $flavor")
    warn "couldn't create the $flavor apps, re-run the wizard"
    return
  fi
  local json="android/app/src/$flavor/google-services.json"
  local plist="ios/Runner/Firebase/$flavor/GoogleService-Info.plist"
  save_config ANDROID "$android" "$json"
  save_config IOS "$ios" "$plist"
  set_secret "${prefix}_FIREBASE_APP_ID" "$android"
  set_secret "${prefix}_GOOGLE_SERVICES_JSON" "$(cat "$json")"
  set_secret "${prefix}_GOOGLE_SERVICE_INFO_PLIST" "$(cat "$plist")"
}

run_wizard() {

TOTAL_STAGES=10

banner "Better Muslim accounts"

stage "Before we start"
say "The Firebase project has to live on elhawarydev@gmail.com."
if ! gh auth status >/dev/null 2>&1; then
  warn "gh isn't logged in, run: gh auth login"
  exit 1
fi
if ! command -v firebase >/dev/null 2>&1; then
  warn "firebase isn't installed, run: npm install -g firebase-tools"
  exit 1
fi
note "github repo: $(gh repo view --json nameWithOwner --jq .nameWithOwner)"
note "firebase: $(firebase login:list 2>/dev/null | tail -1)"
step "If firebase shows another account, stop here and run: firebase login:add"
pause "Right accounts? Press Enter"

stage "Firebase: the project"
open_url "https://console.firebase.google.com/"
step "Create a project named better-muslim."
step "Keep Google Analytics ON, it can't be scripted later. Pick a new Analytics account."
step "Analytics location: pick your country. Leave the data sharing boxes unticked."
step "Skip Gemini and any AI assistance offers."
step "Copy the Project ID, it may have a suffix like better-muslim-1a2b3."
ask FIREBASE_PROJECT "Project ID:"
write_env FIREBASE_PROJECT "$FIREBASE_PROJECT"

stage "Firebase: six apps and their config files"
say "Android and iOS for each flavor. This part runs by itself."
setup_flavor DEV dev "Better Muslim Dev" "$BUNDLE.dev"
setup_flavor STAGING staging "Better Muslim Stag" "$BUNDLE.staging"
setup_flavor PROD production "Better Muslim" "$BUNDLE"
note "the config files stay out of git, .gitignore covers them"
pause "Press Enter"

stage "Firebase: the testers group"
open_url "https://console.firebase.google.com/project/$FIREBASE_PROJECT/appdistribution"
step "If the page has a Get started button, press it."
pause "Done? Press Enter"
if firebase appdistribution:groups:list --project "$FIREBASE_PROJECT" 2>/dev/null | grep testers >/dev/null; then
  note "the testers group is already there"
elif firebase appdistribution:groups:create Testers testers --project "$FIREBASE_PROJECT" >/dev/null 2>&1; then
  printf '  %s✓ created%s the testers group\n' "$GREEN" "$RESET"
else
  SKIPPED+=("App Distribution group with the alias testers")
  warn "couldn't create the group, make it under Testers & Groups with the alias testers"
fi
step "Under Testers & Groups, add the emails of whoever should get builds."
pause "Done? Press Enter"

stage "Firebase: the service account for CI"
if have_secret FIREBASE_SERVICE_ACCOUNT && ! confirm "FIREBASE_SERVICE_ACCOUNT is already set. Replace it?"; then
  note "kept the one in github"
else
  open_url "https://console.cloud.google.com/iam-admin/serviceaccounts/create?project=$FIREBASE_PROJECT"
  step "Name it github-distribution, press Create and continue."
  step "Add the role Firebase App Distribution Admin, nothing else. Press Done."
  step "Open the account → Keys → Add key → Create new key → JSON."
  warn "that file gives admin access to App Distribution, never put it in the repo"
  ask KEY_PATH "Drag the downloaded json here:"
  key_file=$(clean_path "$KEY_PATH")
  if python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["type"] == "service_account"' "$key_file" 2>/dev/null; then
    set_secret FIREBASE_SERVICE_ACCOUNT "$(cat "$key_file")"
    if confirm "Delete the file from this Mac? GitHub has it now."; then
      rm -f "$key_file"
    fi
  else
    SKIPPED+=("FIREBASE_SERVICE_ACCOUNT, the file wasn't a service account key")
    warn "that file isn't a service account key, re-run this stage"
  fi
fi
pause "Press Enter"

stage "Analytics: privacy settings"
say "These stay on unless you turn them off. They match the spec and the privacy policy."
open_url "https://console.firebase.google.com/project/$FIREBASE_PROJECT/settings/integrations"
step "Google Analytics → Manage, then open the property in Analytics."
step "Admin → Data collection and modification → Data collection:"
step "   Google signals: off."
step "   Granular location and device data: off for every region."
step "   Advanced settings to allow for ads personalization: off for every region."
step "Admin → Data collection and modification → Data retention:"
step "   Event data and user data: 2 months. Save."
note "the menu names move around, the setting names don't"
pause "All four done? Press Enter"

stage "Sentry: the project"
open_url "https://sentry.io/signup/"
step "Make the organization with the data region set to the EU, it can't move later."
step "Create one project, platform Flutter, named better-muslim."
step "Copy the organization slug and the project slug from the url."
ask SENTRY_ORG "Organization slug:"
ask SENTRY_PROJECT "Project slug:"
write_env SENTRY_ORG "$SENTRY_ORG"
write_env SENTRY_PROJECT "$SENTRY_PROJECT"
set_var SENTRY_ORG "$SENTRY_ORG"
set_var SENTRY_PROJECT "$SENTRY_PROJECT"
if have_secret PROD_SENTRY_DSN && ! confirm "The DSNs are already set. Replace them?"; then
  note "kept the ones in github"
else
  open_url "https://$SENTRY_ORG.sentry.io/settings/projects/$SENTRY_PROJECT/keys/"
  step "Copy the DSN. One project, so all three flavors share it."
  ask_secret SENTRY_DSN "Paste the DSN:"
  set_secret DEV_SENTRY_DSN "$SENTRY_DSN"
  set_secret STAGING_SENTRY_DSN "$SENTRY_DSN"
  set_secret PROD_SENTRY_DSN "$SENTRY_DSN"
fi
pause "Press Enter"

stage "Sentry: IP storage and the CI token"
open_url "https://$SENTRY_ORG.sentry.io/settings/projects/$SENTRY_PROJECT/security-and-privacy/"
step "Turn on Prevent Storing of IP Addresses."
warn "don't skip it, the iOS SDK sends the IP even with PII off"
pause "Done? Press Enter"
if have_secret SENTRY_AUTH_TOKEN && ! confirm "SENTRY_AUTH_TOKEN is already set. Replace it?"; then
  note "kept the one in github"
else
  open_url "https://$SENTRY_ORG.sentry.io/settings/auth-tokens/"
  step "Create an organization token named github-symbols. It starts with sntrys_."
  ask_secret SENTRY_AUTH_TOKEN "Paste the token:"
  set_secret SENTRY_AUTH_TOKEN "$SENTRY_AUTH_TOKEN"
fi
pause "Press Enter"

stage "Shorebird: the CI key"
if have_secret SHOREBIRD_TOKEN && ! confirm "SHOREBIRD_TOKEN is already set. Replace it?"; then
  note "kept the one in github"
else
  open_url "https://console.shorebird.dev/"
  step "Account → API Keys → Create API Key, named github."
  step "Pick the longest expiry, and put the date in your calendar."
  warn "the key shows only once, copy it now"
  ask_secret SHOREBIRD_TOKEN "Paste the key:"
  set_secret SHOREBIRD_TOKEN "$SHOREBIRD_TOKEN"
fi
pause "Press Enter"

stage "Check everything"
missing=0
for name in ANDROID_KEYSTORE_BASE64 ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD \
  FIREBASE_SERVICE_ACCOUNT SENTRY_AUTH_TOKEN SHOREBIRD_TOKEN \
  DEV_FIREBASE_APP_ID STAGING_FIREBASE_APP_ID PROD_FIREBASE_APP_ID \
  DEV_GOOGLE_SERVICES_JSON STAGING_GOOGLE_SERVICES_JSON PROD_GOOGLE_SERVICES_JSON \
  DEV_GOOGLE_SERVICE_INFO_PLIST STAGING_GOOGLE_SERVICE_INFO_PLIST PROD_GOOGLE_SERVICE_INFO_PLIST \
  DEV_SENTRY_DSN STAGING_SENTRY_DSN PROD_SENTRY_DSN; do
  if ! have_secret "$name"; then
    warn "missing secret $name"
    missing=$((missing + 1))
  fi
done
if ! gh variable list --json name --jq '.[].name' | grep -x SENTRY_PROJECT >/dev/null; then
  warn "missing variable SENTRY_PROJECT"
  missing=$((missing + 1))
fi
if (( missing )); then
  warn "$missing missing, re-run the wizard, it keeps what is done"
else
  printf '  %s✓ every secret and variable is in github%s\n' "$GREEN" "$RESET"
fi
pause "Press Enter"

finish
}

run_wizard "$@"; exit
