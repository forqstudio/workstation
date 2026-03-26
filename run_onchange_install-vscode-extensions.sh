#!/bin/bash
set -e

# Install VSCode extensions (re-runs whenever this file changes)
if command -v code &>/dev/null; then
  # core
  code --install-extension ms-python.python --force
  code --install-extension ms-dotnettools.csdevkit --force
  code --install-extension ms-azuretools.vscode-containers --force
  code --install-extension ms-vscode-remote.remote-containers --force
  code --install-extension HashiCorp.terraform --force
  code --install-extension Anthropic.claude-code --force
  
  # theme
  code --install-extension sdras.night-owl --force
fi
