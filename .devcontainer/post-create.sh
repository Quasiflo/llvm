#!/usr/bin/env bash
echo "Fixing permissions on mounted volumes ..."
sudo chown -R vscode:vscode /mnt/mise-data /home/vscode/.local

echo "Configuring zsh ..."
cat >> ~/.zshrc << 'EOF'
eval "$(mise activate zsh)" # Enables Mise in shells
export EDITOR=nano # Preference for Yazi to use nano
EOF

echo "Enabling global mise tools ..."
mise trust /workspaces/llvm/.config
mise use -g cmake@latest
mise use -g ninja@latest
mise use -g python@latest

echo "Enabling mise experimental features ..."
mise settings experimental=true

echo "Updating apt and installing file utility ..." # Needed for Yazi file manager for file previews
sudo apt update
sudo apt install -y file

echo "Post-create setup finished."