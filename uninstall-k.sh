#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "  Uninstalling claude-k..."
echo ""

removed=0

if [[ -f "$HOME/.local/bin/claude-k" ]]; then
  rm "$HOME/.local/bin/claude-k"
  echo "  Removed: ~/.local/bin/claude-k"
  removed=1
fi

if [[ -d "$HOME/.config/claude-k" ]]; then
  rm -rf "$HOME/.config/claude-k"
  echo "  Removed: ~/.config/claude-k/"
  removed=1
fi

if [[ $removed -eq 0 ]]; then
  echo "  Nothing to remove. claude-k was not installed."
else
  echo ""
  echo "  Done. claude-k has been fully removed."
fi
echo ""
