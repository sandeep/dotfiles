# Dotfiles

This repository contains my personal dotfiles and a script to manage them. The `install.sh` script symlinks configuration files, manages Homebrew packages, and synchronizes Visual Studio Code settings and extensions.

## Installation

To use these dotfiles, clone the repository and run the `install.sh` script:

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Script Features

The `install.sh` script performs the following actions:

### Dotfile Management

The script manages `.gitconfig` and `.tmux.conf`. It will:
- Symlink the files from the repository to your home directory.
- If a file already exists, it will show you a diff and ask you to overwrite the local file, update the repository file, or skip.

### Homebrew Management

The script manages Homebrew packages using a `Brewfile`. It will:
- Check if Homebrew is installed and offer to install it if it's not.
- Install all packages listed in the `Brewfile`.
- Compare your installed packages to the `Brewfile` and offer to update the `Brewfile` in the repository.

### Visual Studio Code Configuration

The script synchronizes your Visual Studio Code settings, keybindings, and snippets by creating symlinks to the files in the repository.

### Visual Studio Code Extensions

The script manages your Visual Studio Code extensions. It will:
- Compare your installed extensions with the `extensions.txt` file in the repository.
- If there are differences, it will show you the changes and ask you to overwrite the backup, merge the changes, or skip.
- Ask if you want to install the extensions listed in the `extensions.txt` file.