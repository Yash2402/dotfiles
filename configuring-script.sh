#!/usr/bin/env bash

# Strict mode for safety
set -euo pipefail
IFS=$'\n\t'

HOME_BACKUP_DIR="/run/media/yashsharma/Samsung T7/linux-backup/home"
CONFIG_DIR="$HOME/dev/dotfiles"

echo "0. SYSTEM UPDATE --------------------------------------------------------"
sudo dnf update -y && sudo dnf upgrade -y

echo "CONNECT TO SSD FIRST"
echo "You have 10 seconds..."
sleep 10

echo "1. INSTALLING CORE PACKAGES ---------------------------------------------"
sudo dnf install -y \
    i3 xorg-x11-server-Xorg \
    alacritty btop cava mpv kitty neovim obs-studio picom polybar rofi maim tmux \
    zsh curl wget unzip \
    gcc g++ clang clang++ \
    feh cmatrix brightnessctl \
    python3-pydbus

echo "2. SSH SETUP ------------------------------------------------------------"
if [ -d "${HOME_BACKUP_DIR}/.ssh" ]; then
    echo "Copying .ssh directory..."
    cp -r "${HOME_BACKUP_DIR}/.ssh" "$HOME/"
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh"/*
else
    echo "WARNING: Backup .ssh directory not found in ${HOME_BACKUP_DIR}"
fi

echo "3. ZSH SETUP ------------------------------------------------------------"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "--- Installing Oh My Zsh ---"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || echo "Oh My Zsh installation failed or already exists."
else
    echo "--- Oh My Zsh already installed ---"
fi

echo "    - Zsh plugins: "
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
mkdir -p "$ZSH_CUSTOM/plugins"

declare -A plugins=(
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-bat]="https://github.com/fdellwing/zsh-bat.git"
    [you-should-use]="https://github.com/MichaelAquilina/zsh-you-should-use.git"
)

for plugin in "${!plugins[@]}"; do
    if [ ! -d "${ZSH_CUSTOM}/plugins/$plugin" ]; then
        git clone "${plugins[$plugin]}" "${ZSH_CUSTOM}/plugins/$plugin"
    fi
done

echo "    - Cloning Powerlevel10k theme ---"
if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"
fi

echo "4. NEOVIM SETUP ---------------------------------------------------------"
if [ ! -d "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim" ]; then
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
else
    echo "--- Packer already installed ---"
fi

echo "5. COPYING CONFIG FILES -------------------------------------------------"
if [ -d "$HOME/.config" ]; then
    echo "Backing up existing .config to .config.bak"
    mv "$HOME/.config" "$HOME/.config.bak"
fi

if [ -d "$CONFIG_DIR/.config" ]; then
    cp -r "$CONFIG_DIR/.config" "$HOME/"
else
    echo "WARNING: .config directory not found in $CONFIG_DIR"
fi

if [ -f "$CONFIG_DIR/.Xresources" ]; then
    cp "$CONFIG_DIR/.Xresources" "$HOME/"
else
    echo "WARNING: .Xresources not found"
fi

if [ -f "$CONFIG_DIR/.zshrc" ]; then
    cp "$CONFIG_DIR/.zshrc" "$HOME/"
else
    echo "WARNING: .zshrc not found"
fi

echo "6. FONT INSTALLATION ----------------------------------------------------"
if [ -d "$CONFIG_DIR/fonts" ] && [ "$(ls -A "$CONFIG_DIR/fonts")" ]; then
    sudo mkdir -p /usr/local/share/fonts
    sudo cp -r "$CONFIG_DIR/fonts/"* /usr/local/share/fonts
    sudo fc-cache -v -f
else
    echo "WARNING: fonts directory not found or empty in $CONFIG_DIR/fonts"
fi

echo "    - Installing iosevka nerd font"
mkdir -p ~/dev/iosevka; cd ~/dev/iosevka
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Iosevka.zip


echo "7. INSTALLING EXTRA TOOLS -----------------------------------------------"
for tool in boomer autotilling neofetch; do
    TOOL_PATH="$CONFIG_DIR/tools/$tool"
    if [ -f "$TOOL_PATH" ]; then
        sudo cp "$TOOL_PATH" /usr/bin/
        sudo chmod +x "/usr/bin/$tool"
    else
        echo "WARNING: Tool $tool not found in $CONFIG_DIR/tools"
    fi
done



echo ""
echo "🎉 SETUP COMPLETE! You may still need to:"
echo "1. Log out and log back in for shell and font changes to take effect."
echo "2. Run 'nvim' and execute ':PackerSync' to install Neovim plugins."
echo "3. Change your default shell to Zsh: chsh -s \$(which zsh)"
echo "4. Run 'p10k configure' to reconfigure Powerlevel10k if needed."
echo "5. Review any WARNING messages above."

exit 0

