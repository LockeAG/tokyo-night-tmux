#!/usr/bin/env bash

# Exit early if SHOW_WIDGET is set to "0"
SHOW_WIDGET=$(tmux show-option -gv @tokyo-night-tmux_show_wbg)
[ "$SHOW_WIDGET" == "0" ] && exit 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/../lib/coreutils-compat.sh"
source "$CURRENT_DIR/themes.sh"

# Change to the specified directory or exit
cd "$1" || exit 1

# Get the current git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Exit if not in a git repository
[ -z "$BRANCH" ] && exit 0

# Function to extract the provider from the Git remote URL
get_provider() {
  REMOTE_URL=$(git config --get remote.origin.url)

  if [[ "$REMOTE_URL" =~ git@([^:]+): ]]; then
    PROVIDER="${BASH_REMATCH[1]}"
  elif [[ "$REMOTE_URL" =~ https://([^/]+)/ ]]; then
    PROVIDER="${BASH_REMATCH[1]}"
  else
    PROVIDER=""
  fi
}

# Initialize variables
PROVIDER_ICON=""
PR_COUNT=0
REVIEW_COUNT=0
ISSUE_COUNT=0
BUG_COUNT=0

PR_STATUS=""
REVIEW_STATUS=""
ISSUE_STATUS=""
BUG_STATUS=""

# Get the provider
get_provider

# Exit if provider is not supported
if [[ "$PROVIDER" != "github.com" && "$PROVIDER" != "gitlab.com" ]]; then
  exit 0
fi

# Functions to get counts from GitHub and GitLab
get_github_counts() {
  if ! command -v gh &>/dev/null; then
    echo "GitHub CLI not found."
    exit 1
  fi

  PROVIDER_ICON="$RESET#[fg=${THEME[foreground]}] "

  PR_COUNT=$(gh pr list --json number --jq 'length')
  REVIEW_COUNT=$(gh pr status --json reviewRequests --jq '.currentUser.prs | length')
  RES=$(gh issue list --json "assignees,labels" --assignee @me)
  ISSUE_COUNT=$(echo "$RES" | jq 'length')
  BUG_COUNT=$(echo "$RES" | jq '[.[] | select(.labels[].name == "bug")] | length')
  ISSUE_COUNT=$((ISSUE_COUNT - BUG_COUNT))
}

get_gitlab_counts() {
  if ! command -v glab &>/dev/null; then
    echo "GitLab CLI not found."
    exit 1
  fi

  PROVIDER_ICON="$RESET#[fg=#fc6d26] "

  PR_COUNT=$(glab mr list --json id --jq 'length')
  REVIEW_COUNT=$(glab mr list --reviewer=@me --json id --jq 'length')
  ISSUE_COUNT=$(glab issue list --json id --jq 'length')
}

# Fetch counts based on the provider
if [[ "$PROVIDER" == "github.com" ]]; then
  get_github_counts
elif [[ "$PROVIDER" == "gitlab.com" ]]; then
  get_gitlab_counts
fi

# Build status strings based on counts
[ "$PR_COUNT" -gt 0 ] && PR_STATUS="#[fg=${THEME[ghgreen]},bg=${THEME[background]},bold] ${RESET}${PR_COUNT} "
[ "$REVIEW_COUNT" -gt 0 ] && REVIEW_STATUS="#[fg=${THEME[ghyellow]},bg=${THEME[background]},bold] ${RESET}${REVIEW_COUNT} "
[ "$ISSUE_COUNT" -gt 0 ] && ISSUE_STATUS="#[fg=${THEME[ghgreen]},bg=${THEME[background]},bold] ${RESET}${ISSUE_COUNT} "
[ "$BUG_COUNT" -gt 0 ] && BUG_STATUS="#[fg=${THEME[ghred]},bg=${THEME[background]},bold] ${RESET}${BUG_COUNT} "

# Combine all status components
WB_STATUS="#[fg=${THEME[black]},bg=${THEME[background]},bold] $RESET$PROVIDER_ICON $RESET$PR_STATUS$REVIEW_STATUS$ISSUE_STATUS$BUG_STATUS"

# Output the final status line
echo "$WB_STATUS"

# Delay execution if the status-interval is less than 20 seconds to prevent API rate limiting
INTERVAL=$(tmux display -p '#{status-interval}')
[ "$INTERVAL" -lt 20 ] && sleep 20
