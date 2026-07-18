#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "  Uninstalling claude-o..."
echo ""

removed=0

if [[ -f "$HOME/.local/bin/claude-o" ]]; then
  rm "$HOME/.local/bin/claude-o"
  echo "  Removed: ~/.local/bin/claude-o"
  removed=1
fi

if [[ -d "$HOME/.config/claude-o" ]]; then
  rm -rf "$HOME/.config/claude-o"
  echo "  Removed: ~/.config/claude-o/"
  removed=1
fi

if [[ $removed -eq 0 ]]; then
  echo "  Nothing to remove. claude-o was not installed."
else
  echo ""
  echo "  Done. claude-o has been fully removed."
fi
echo ""
