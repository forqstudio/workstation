#!/bin/bash
set -e

sudo apt install -y unzip

# FiraCode Nerd Font
if ! fc-list | grep -qi "FiraCode Nerd Font"; then
  FIRACODE_VERSION=$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
    | grep '"tag_name"' | sed 's/.*"tag_name": *"\(.*\)".*/\1/')
  mkdir -p "$HOME/.local/share/fonts"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${FIRACODE_VERSION}/FiraCode.zip" \
    -o /tmp/FiraCode.zip
  unzip -o /tmp/FiraCode.zip -d "$HOME/.local/share/fonts/FiraCode"
  rm /tmp/FiraCode.zip
  fc-cache -fv
fi

