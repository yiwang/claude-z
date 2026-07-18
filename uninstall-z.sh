#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "  Uninstalling claude-z..."
echo ""

removed=0

if [[ -f "$HOME/.local/bin/claude-z" ]]; then
  rm "$HOME/.local/bin/claude-z"
  echo "  Removed: ~/.local/bin/claude-z"
  removed=1
fi

if [[ -d "$HOME/.config/claude-z" ]]; then
  rm -rf "$HOME/.config/claude-z"
  echo "  Removed: ~/.config/claude-z/"
  removed=1
fi

if [[ $removed -eq 0 ]]; then
  echo "  Nothing to remove. claude-z was not installed."
else
  echo ""
  echo "  Done. claude-z has been fully removed."
fi
echo ""
