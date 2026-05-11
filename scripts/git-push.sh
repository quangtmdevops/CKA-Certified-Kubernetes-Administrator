#!/bin/bash

# Check commit message
if [ -z "$1" ]; then
  echo "Usage: ./git-push.sh \"commit message\""
  exit 1
fi

COMMIT_MESSAGE="$1"

# Current branch
BRANCH=$(git branch --show-current)

echo "Current branch: $BRANCH"

# Git workflow
git add .

git commit -m "$COMMIT_MESSAGE"

git push origin "$BRANCH"
