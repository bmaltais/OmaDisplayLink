# shellcheck shell=bash
# Numbered steps with one plain-language line each, shared by setup, reinstall and uninstall.
# PREVIEW=1 says what each step would do and changes nothing.

PREVIEW="${PREVIEW:-0}"
# SIMULATE=1 (the plugin's demo mode) asks the real questions but pretends every step succeeded, so a
# screenshot or a walkthrough shows what a run looks like without running anything.
SIMULATE="${SIMULATE:-0}"
STEP_TOTAL=0
STEP_N=0

steps_begin() { STEP_TOTAL="$1"; STEP_N=0; }

# step TITLE WHAT_IT_DOES
step() {
  STEP_N=$((STEP_N + 1))
  printf '\n\033[1mStep %d of %d: %s\033[0m\n%s\n' "$STEP_N" "$STEP_TOTAL" "$1" "$2"
}
step_ok() { printf '  \033[32m✔\033[0m %s\n' "$1"; }
step_skip() { printf '  - %s\n' "$1"; }
step_would() { printf '  Would: %s\n' "$1"; }

# run_step WHAT CMD...: runs the command, or in preview only says what it would do.
run_step() {
  local what="$1"
  shift
  if ((PREVIEW)); then
    step_would "$what"
    return 0
  fi
  if ((SIMULATE)); then
    sleep 0.4
    step_ok "$what"
    return 0
  fi
  if "$@"; then
    step_ok "$what"
  else
    printf '  \033[31m✘ Failed:\033[0m %s\n' "$what"
    return 1
  fi
}

# ask QUESTION: a yes/no prompt; preview and demo answer yes without asking.
ask() {
  ((PREVIEW)) && return 0
  gum confirm "$1"
}

# stop_flow: a step failed; say what to do and leave with an error.
stop_flow() {
  echo
  echo "Stopped. Nothing after this step was run."
  echo "To ask for help: close this window, click the bar icon and choose Copy report, then paste it into an issue."
  exit 1
}
