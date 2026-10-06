#!/usr/bin/env bash
# Script to populate standard labels in GitHub repository using GitHub API
set -euo pipefail

REPO="${1:-${GITHUB_REPOSITORY:-}}"
if [ -z "$REPO" ]; then
  echo "Usage: $0 owner/repo [token]"
  echo "Or set GITHUB_REPOSITORY and GITHUB_TOKEN environment variables."
  exit 1
fi

TOKEN="${2:-${GITHUB_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
  if [ -f "$HOME/.git-credentials" ]; then
    TOKEN=$(cut -d: -f3 "$HOME/.git-credentials" | cut -d@ -f1)
  else
    echo "Error: No GitHub token provided or found in ~/.git-credentials"
    exit 1
  fi
fi

echo "Setting up standard labels for $REPO..."

LABELS=(
  '{"name":"autonomous","color":"1d76db","description":"Triggers autonomous agent pipeline upon issue creation or command"}'
  '{"name":"bug","color":"d73a4a","description":"Something isn\\'t working as expected"}'
  '{"name":"enhancement","color":"a2eeef","description":"New feature or request"}'
  '{"name":"documentation","color":"0075ca","description":"Improvements or additions to documentation"}'
  '{"name":"visual","color":"e99695","description":"Issue contains screenshots or visual design mockups"}'
  '{"name":"plan-ready","color":"0e8a16","description":"Autonomous planning completed and plan committed"}'
  '{"name":"in-progress","color":"fbca04","description":"Autonomous agent is currently implementing this issue"}'
  '{"name":"checkpoint","color":"b60205","description":"Task paused at timeout checkpoint, needs follow-up run"}'
  '{"name":"help wanted","color":"008672","description":"Extra attention or human feedback needed"}'
  '{"name":"good first issue","color":"7057ff","description":"Good for newcomers"}'
  '{"name":"duplicate","color":"cfd3d7","description":"This issue or pull request already exists"}'
  '{"name":"invalid","color":"e4e669","description":"This issue doesn\\'t seem right"}'
  '{"name":"wontfix","color":"ffffff","description":"This will not be worked on"}'
)

for label_json in "${LABELS[@]}"; do
  LABEL_NAME=$(echo "$label_json" | jq -r '.name')
  echo "Configuring label: $LABEL_NAME"
  # Try to update existing label, otherwise create new
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$REPO/labels/$LABEL_NAME" \
    -d "$label_json" || true)

  if [ "$STATUS" -ne 200 ]; then
    curl -s -X POST \
      -H "Authorization: token $TOKEN" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$REPO/labels" \
      -d "$label_json" > /dev/null || true
  fi
done

echo "Labels setup completed successfully for $REPO."
