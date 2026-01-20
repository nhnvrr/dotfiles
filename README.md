Standalone macOS bootstrap (no Nix)
----------------------------------

This folder holds a minimal macOS-only setup that relies on Homebrew instead of Nix. It installs a few GUI apps and links the existing dotfiles from `config/`.

Usage
- Run `./install.sh` on macOS. The script will install Homebrew if missing, then install the casks for Visual Studio Code, Spotify, and Google Chrome.
- Your existing configs are symlinked into place:
  - `config/zsh/.zshrc` -> `~/.zshrc`
  - `config/starship/starship.toml` -> `~/.config/starship/starship.toml`
  - `config/pgcli/config` -> `~/.config/pgcli/config`
  - `config/gh/config.yml` -> `~/.config/gh/config.yml` (if present)

Notes
- The script does not depend on Nix; it only touches Homebrew and your home directory configs.
- Re-run `./install.sh` any time you want to refresh the apps or relink dotfiles.
