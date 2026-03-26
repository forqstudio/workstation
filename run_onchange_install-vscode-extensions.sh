#!/bin/bash
set -e

# Install VSCode extensions (re-runs whenever this file changes)
if command -v code &>/dev/null; then
  code --install-extension ms-dotnettools.csdevkit
  code --install-extension ms-azuretools.vscode-containers
  code --install-extension ms-vscode-remote.remote-containers
  code --install-extension Anthropic.claude-code
  code --install-extension sdras.night-owl
fi
