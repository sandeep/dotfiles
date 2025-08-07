#!/bin/bash
# This script symlinks dotfiles from the 'home' directory to the user's home
# directory, handles Brewfile installation, and provides diff-based updates.

set -e

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Banner ---
echo -e "${BLUE}--------------------------------------------------${NC}"
echo -e "${BLUE}      Dotfiles and Brewfile Installer             ${NC}"
echo -e "${BLUE}--------------------------------------------------${NC}"

# --- Directories ---
dir=~/dotfiles
homedir=~/

# --- Manage dotfiles ---
dotfiles="gitconfig tmux.conf"
echo -e "\n${YELLOW}--- Managing dotfiles ---${NC}"
for file in $dotfiles; do
    source_file="$dir/home/$file"
    dest_file="$homedir/.$file"

    if [ -f "$dest_file" ] && [ ! -L "$dest_file" ]; then
        if ! cmp -s "$source_file" "$dest_file"; then
            echo -e "\n${YELLOW}Differences found for .$file:${NC}"
            diff --color=always "$dest_file" "$source_file" || true

            echo -e "\n${YELLOW}Choose an action for .$file:${NC}"
            echo "  1) Overwrite local file with a symlink to the repo version."
            echo "  2) Update the repo file with your local changes."
            echo "  3) Skip."
            read -p "Enter your choice (1-3): " choice

            case "$choice" in
                1)
                    ln -sf "$source_file" "$dest_file"
                    echo -e "${GREEN}Overwritten .$file with a symlink.${NC}"
                    ;;
                2)
                    cp "$dest_file" "$source_file"
                    echo -e "${GREEN}Updated repository's $file.${NC}"
                    ;;
                *)
                    echo "Skipped .$file."
                    ;;
            esac
        else
            echo -e "${GREEN}Local .$file is identical to the repository version. Creating symlink.${NC}"
            ln -sf "$source_file" "$dest_file"
        fi
    elif [ ! -e "$dest_file" ] && [ ! -L "$dest_file" ]; then
        ln -s "$source_file" "$dest_file"
        echo -e "${GREEN}Symlinked $source_file to $dest_file${NC}"
    else
        echo -e "${GREEN}.$file is already a symlink. Skipping.${NC}"
    fi
done

# --- Handle Brewfile ---
echo -e "\n${YELLOW}--- Handling Brewfile ---${NC}"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed."
    read -p "Do you want to install Homebrew now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Skipping Homebrew installation and Brewfile processing."
        exit 0
    fi
fi

# Ask to process Brewfile
read -p "Do you want to install packages from the Brewfile? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Installing from Brewfile...${NC}"
    brew bundle --file="$dir/home/Brewfile"
    echo -e "${GREEN}Brewfile installation complete.${NC}"
fi

# --- Update Brewfile ---
echo -e "\n${YELLOW}--- Checking for Brewfile updates ---${NC}"
temp_brewfile=$(mktemp)
brew bundle dump --force --file="$temp_brewfile"

if ! cmp -s "$temp_brewfile" "$dir/home/Brewfile"; then
    echo "Your installed Homebrew packages differ from the Brewfile."
    read -p "Do you want to update the Brewfile in your dotfiles repository? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$temp_brewfile" "$dir/home/Brewfile"
        echo -e "${GREEN}Brewfile updated.${NC}"
    else
        echo "Skipped Brewfile update."
    fi
fi
rm "$temp_brewfile"

# --- VS Code ---
echo -e "\n${YELLOW}--- Managing VS Code configuration ---${NC}"
vscode_config_dir="$homedir/Library/Application Support/Code/User"
vscode_dotfiles_dir="$dir/home/vscode"

# Symlink settings and keybindings
for file in settings.json keybindings.json; do
    ln -sf "$vscode_dotfiles_dir/$file" "$vscode_config_dir/$file"
    echo -e "${GREEN}Symlinked $file to $vscode_config_dir/$file${NC}"
done

# Symlink snippets directory
ln -sf "$vscode_dotfiles_dir/snippets" "$vscode_config_dir/snippets"
echo -e "${GREEN}Symlinked snippets directory to $vscode_config_dir/snippets${NC}"

# --- VS Code Extensions ---
echo -e "
${YELLOW}--- Managing VS Code extensions ---${NC}"

# Get the backup file path
extensions_backup_file="$vscode_dotfiles_dir/extensions.txt"

# Get the list of currently installed extensions
current_extensions=$(mktemp)
code --list-extensions > "$current_extensions"

# Check if the backup file exists
if [ -f "$extensions_backup_file" ]; then
    # Check for differences
    if ! cmp -s "$current_extensions" "$extensions_backup_file"; then
        echo -e "
${YELLOW}Your installed VS Code extensions differ from the backup file.${NC}"
        diff --color=always "$extensions_backup_file" "$current_extensions" || true

        echo -e "
${YELLOW}Choose an action:${NC}"
        echo "  1) Overwrite the backup file with your current extensions."
        echo "  2) Merge your current extensions with the backup file (additive)."
        echo "  3) Skip."
        read -p "Enter your choice (1-3): " choice

        case "$choice" in
            1)
                cp "$current_extensions" "$extensions_backup_file"
                echo -e "${GREEN}Backup file overwritten.${NC}"
                ;;
            2)
                cat "$current_extensions" >> "$extensions_backup_file"
                sort -u "$extensions_backup_file" -o "$extensions_backup_file"
                echo -e "${GREEN}Current extensions merged into the backup file.${NC}"
                ;;
            *)
                echo "Skipped backup."
                ;;
        esac
    else
        echo -e "${GREEN}Your installed VS Code extensions are in sync with the backup file.${NC}"
    fi
else
    echo -e "
${YELLOW}No backup file found for VS Code extensions.${NC}"
    read -p "Do you want to create a backup of your current extensions? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$current_extensions" "$extensions_backup_file"
        echo -e "${GREEN}Backup file created.${NC}"
    fi
fi

rm "$current_extensions"

# Ask to install extensions
read -p "Do you want to install extensions from the backup file? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Installing extensions...${NC}"
    if [ -f "$extensions_backup_file" ]; then
        while read extension; do
            code --install-extension "$extension"
        done < "$extensions_backup_file"
        echo -e "${GREEN}Extensions installed.${NC}"
    else
        echo -e "${YELLOW}No backup file found. Skipping installation.${NC}"
    fi
fi


echo -e "\n${GREEN}Installation script finished.${NC}"
