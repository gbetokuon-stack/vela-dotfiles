#!/usr/bin/env bash
# Update the live Vela rice from git, then sync local tweaks back safely.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo "==> Fetching origin..."
git fetch --all --prune

if [[ -n "$(git status --porcelain)" ]]; then
    echo "! Working tree is dirty. Commit or stash your changes first." >&2
    git status --short >&2
    exit 1
fi

if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    ahead=$(git rev-list --count '@{upstream}..HEAD')
    behind=$(git rev-list --count 'HEAD..@{upstream}')
    echo "    ahead=$ahead behind=$behind"
    if (( ahead > 0 )); then
        echo "! Local has $ahead unpushed commit(s); pull would need a rebase. Skipping auto-pull." >&2
    elif (( behind > 0 )); then
        git pull --ff-only
    else
        echo "    Already up to date."
    fi
fi

echo "==> Deploying configs (backs up existing files)..."
./install.sh

echo "==> Reloading Hyprland..."
hyprctl reload 2>/dev/null || true
echo "Done. Check Vela Settings (Super+I) if anything looks off."
