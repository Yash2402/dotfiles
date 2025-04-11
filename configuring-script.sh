#!/usr/bin/env bash

# Strict mode for safety
IFS=$'\n\t'

CONFIG_DIR="$HOME/dev/dotfiles"

show_menu() {
    echo "Select sections to run (space-separated):"
    echo "1) System Update"
    echo "2) Install Core Packages"
    echo "3) SSH Setup"
    echo "4) ZSH Setup"
    echo "5) Neovim Setup"
    echo "6) Copy Config Files"
    echo "7) Install Fonts"
    echo "8) Extra Tools Setup"
    echo "9) Lock Screen Setup"
    echo "0) Run All"
    read -rp "Your choice: " choices
}

run_all=false
sections=()

parse_choices() {
    for choice in $choices; do
        if [[ "$choice" == "0" ]]; then
            run_all=true
            break
        fi
        sections+=("$choice")
    done
}

run_section() {
    [[ "$run_all" == true || "${sections[*]}" =~ $1 ]] && $2
}

# 1. System update
system_update() {
    echo "0. SYSTEM UPDATE --------------------------------------------------------"
    sudo dnf update -y && sudo dnf upgrade -y
}

# 2. Core packages
install_core_packages() {
    echo "1. INSTALLING CORE PACKAGES ---------------------------------------------"
    sudo dnf install -y \
        i3 xorg-x11-server-Xorg \
        alacritty btop cava mpv kitty neovim obs-studio picom polybar rofi maim tmux \
        zsh curl wget unzip \
        gcc g++ clang clang++ \
        feh cmatrix brightnessctl playerctl xset\
        python3-pydbus
}

# 3. SSH setup
ssh_setup() {
    echo "2. SSH SETUP ------------------------------------------------------------"
    read -p "Enter your email: " email
    ssh-keygen -t ed25519 -C "$email"
    echo "Copy the public ssh key from ~/.ssh/id_ed25519.pub and add it to your GitHub account"
}

# 4. ZSH setup
zsh_setup() {
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
}

# 5. Neovim
neovim_setup() {
    echo "4. NEOVIM SETUP ---------------------------------------------------------"
    if [ ! -d "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim" ]; then
        git clone --depth 1 https://github.com/wbthomason/packer.nvim "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    else
        echo "--- Packer already installed ---"
    fi
}

# 6. Config
copy_config_files() {
    echo "5. COPYING CONFIG FILES -------------------------------------------------"
    echo "Copying configuration files..."

    if [ -d "$HOME/.config" ]; then
        echo "Backing up existing .config to .config.bak"
        mv "$HOME/.config" "$HOME/.config.bak"
    fi

    if [ -d "$CONFIG_DIR/.config" ]; then
        cp -r "$CONFIG_DIR/.config" "$HOME/"
    else
        echo "WARNING: .config not found in $CONFIG_DIR"
    fi

    if [ -f "$CONFIG_DIR/.Xresources" ]; then
        cp "$CONFIG_DIR/.Xresources" "$HOME/"
    else
        echo "WARNING: .Xresources not found in $CONFIG_DIR"
    fi

    if [ -f "$CONFIG_DIR/.zshrc" ]; then
        cp "$CONFIG_DIR/.zshrc" "$HOME/"
    else
        echo "WARNING: .zshrc not found in $CONFIG_DIR"
    fi
}

# 7. Fonts
install_fonts() {
    echo "6. FONT INSTALLATION ----------------------------------------------------"
    if [ -d "$CONFIG_DIR/fonts" ] && [ "$(ls -A "$CONFIG_DIR/fonts")" ]; then
        sudo mkdir -p /usr/local/share/fonts
        sudo cp -r "$CONFIG_DIR/fonts/"* /usr/local/share/fonts
        sudo fc-cache -v -f
    else
        echo "WARNING: fonts directory not found or empty in $CONFIG_DIR/fonts"
    fi

    echo "    - Installing iosevka nerd font"
    mkdir -p ~/dev/iosevka && cd ~/dev/iosevka
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Iosevka.zip
}

# 8. Extra tools
install_extra_tools() {
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
}

# 9. Lock screen
setup_lockscreen() {
    echo "8. BETTERLOCKSCREEN & i3lock-color --------------------------------------"
    wget https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh -O - -q | bash -s user
    sudo dnf install -y giflib-devel.aarch64 autoconf automake cairo-devel fontconfig gcc libev-devel libjpeg-turbo-devel libXinerama libxkbcommon-devel libxkbcommon-x11-devel libXrandr pam-devel pkgconf xcb-util-image-devel xcb-util-xrm-devel
    git clone https://github.com/Raymo111/i3lock-color.git
    cd i3lock-color
    ./build.sh
    ./install-i3lock-color.sh
    cd .. && rm -rf i3lock-color

    betterlockscreen -u "$CONFIG_DIR/.config/screenshots/Wallpaper-used-vortex-ring-sobel-figma-created-by-yash-sharma.png" --fx dim,pixel,blur,dimpixel
}

# Start script
show_menu
parse_choices

run_section 1 system_update
run_section 2 install_core_packages
run_section 3 ssh_setup
run_section 4 zsh_setup
run_section 5 neovim_setup
run_section 6 copy_config_files
run_section 7 install_fonts
run_section 8 install_extra_tools
run_section 9 setup_lockscreen

echo ""
echo "SETUP COMPLETE! You may still need to:"
echo "1. Log out and log back in for shell and font changes to take effect."
echo "2. Run 'nvim' and execute ':PackerSync' to install Neovim plugins."
echo "3. Change your default shell to Zsh: chsh -s \$(which zsh)"
echo "4. Run 'p10k configure' to reconfigure Powerlevel10k if needed."
echo "5. Review any WARNING messages above."

exit 0

