#!/usr/bin/env bash

# ==============================================================================
# Script to automate GNOME Shortcuts and Extension setup for Kanata
# This script handles everything that 'setup-kanata-hardened.sh' does not.
# ==============================================================================

set -euo pipefail

PLAYGROUND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSION_UUID="window-cycler@custom"
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"

echoinfo() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
echosucc() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }

# 1. Install/Update the GNOME Extension
echoinfo "Installing GNOME Extension: $EXTENSION_UUID..."
mkdir -p "$EXTENSIONS_DIR"
cp -r "$PLAYGROUND_DIR/$EXTENSION_UUID" "$EXTENSIONS_DIR/"
echosucc "Extension files copied."

# 2. Enable the Extension
echoinfo "Enabling the extension..."
gnome-extensions enable "$EXTENSION_UUID"
echosucc "Extension added to enabled-extensions list."

# 2.5 Install switch-app-window.sh script
BIN_DIR="$HOME/.local/bin"
echoinfo "Installing switch-app-window.sh to $BIN_DIR..."
mkdir -p "$BIN_DIR"
cp "$PLAYGROUND_DIR/switch-app-window.sh" "$BIN_DIR/"
chmod +x "$BIN_DIR/switch-app-window.sh"
echosucc "Script installed."

# 3. Configure Custom GNOME Shortcuts
echoinfo "Configuring Custom GNOME Shortcuts..."

# Define the paths for our custom bindings
BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
declare -A SHORTCUTS=(
    ["custom1"]="Switch to Firefox:firefox_firefox.desktop:<Super><Shift>f"
    ["custom2"]="Switch to Files:org.gnome.Nautilus.desktop:<Super><Shift>e:nautilus"
    ["custom3"]="Switch to Gemini:chrome-gdfaincndogidkdcdkhapmbffkckdkhn-Default.desktop:<Super><Shift>g"
    ["custom4"]="Switch to ChatGPT:chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default.desktop:<Super><Shift>c"
    ["custom5"]="Switch to Antigravity:antigravity-ide.desktop:<Super><Shift>a"
    ["custom6"]="Switch to VS Code:code.desktop:<Super><Shift>v"
    ["custom7"]="Switch to Ghostty:com.mitchellh.ghostty.desktop:<Super><Shift>y"
)

# Build the list of active custom shortcut paths
BINDINGS_LIST="['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']" # Keep your OCR shortcut
for key in "${!SHORTCUTS[@]}"; do
    BINDINGS_LIST="${BINDINGS_LIST%]*}, '$BASE_PATH/$key/']"
done

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$BINDINGS_LIST"

# Apply each shortcut's details
for key in "${!SHORTCUTS[@]}"; do
    IFS=':' read -r name app_id binding fallback <<< "${SHORTCUTS[$key]}"
    path="$BASE_PATH/$key/"
    
    cmd="$BIN_DIR/switch-app-window.sh $app_id"
    if [ -n "$fallback" ]; then cmd="$cmd $fallback"; fi

    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" name "$name"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" command "$cmd"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" binding "$binding"
done
echosucc "All 7 custom shortcuts configured."

# 4. Final instructions
echoinfo "--------------------------------------------------------"
echoinfo "GNOME SETUP COMPLETE!"
echoinfo "1. Please LOG OUT and LOG IN to activate the extension."
echoinfo "2. Ensure you have run 'sudo ./setup-kanata-hardened.sh'."
echoinfo "--------------------------------------------------------"
