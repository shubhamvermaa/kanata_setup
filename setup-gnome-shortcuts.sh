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

# IMPORTANT NOTE ON CHROME APPS:
# The .desktop filenames for Chrome Web Apps (like Gemini or ChatGPT below) 
# use cryptic IDs that are often unique to your browser profile.
# You will need to replace these with your own! 
# Find yours by running: ls ~/.local/share/applications | grep chrome
declare -A SHORTCUTS=(
    ["kanata-firefox"]="Switch to Firefox:firefox_firefox.desktop:<Super><Shift>f"
    ["kanata-nautilus"]="Switch to Files:org.gnome.Nautilus.desktop:<Super><Shift>e:nautilus"
    ["kanata-gemini"]="Switch to Gemini:chrome-gdfaincndogidkdcdkhapmbffkckdkhn-Default.desktop:<Super><Shift>g"
    ["kanata-chatgpt"]="Switch to ChatGPT:chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default.desktop:<Super><Shift>c"
    ["kanata-antigravity"]="Switch to Antigravity:antigravity-ide.desktop:<Super><Shift>a"
    ["kanata-vscode"]="Switch to VS Code:code.desktop:<Super><Shift>v"
    ["kanata-ghostty"]="Switch to Ghostty:com.mitchellh.ghostty.desktop:<Super><Shift>y"
    ["kanata-notion"]="Switch to Notion:chrome-eggdienekcmbialeignhkgeiiikhchco-Default.desktop:<Super><Shift>n"
)

# Read the current custom bindings list safely
CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

# Convert the gsettings array to a clean bash list of paths
declare -a BINDINGS_ARR=()
if [ "$CURRENT_BINDINGS" != "@as []" ] && [ "$CURRENT_BINDINGS" != "[]" ]; then
    # Strip brackets, single quotes, spaces, and split by comma
    CLEAN_BINDINGS=$(echo "$CURRENT_BINDINGS" | tr -d "[]'" | tr "," "\n" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            BINDINGS_ARR+=("$line")
        fi
    done <<< "$CLEAN_BINDINGS"
fi

# Ensure all our kanata shortcuts are appended if not already present
for key in "${!SHORTCUTS[@]}"; do
    path="$BASE_PATH/$key/"
    exists=false
    for existing in "${BINDINGS_ARR[@]}"; do
        if [ "$existing" = "$path" ]; then
            exists=true
            break
        fi
    done
    if [ "$exists" = false ]; then
        BINDINGS_ARR+=("$path")
    fi
done

# Build the gsettings list string: e.g. ['/path1/', '/path2/']
BINDINGS_LIST="["
for i in "${!BINDINGS_ARR[@]}"; do
    if [ "$i" -gt 0 ]; then
        BINDINGS_LIST+=", "
    fi
    BINDINGS_LIST+="'${BINDINGS_ARR[$i]}'"
done
BINDINGS_LIST+="]"

# Set the updated custom keybindings array
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
echosucc "All custom shortcuts configured non-destructively."

# 4. Final instructions
echoinfo "--------------------------------------------------------"
echoinfo "GNOME SETUP COMPLETE!"
echoinfo "1. Please LOG OUT and LOG IN to activate the extension."
echoinfo "2. Ensure you have run 'sudo ./setup-kanata-hardened.sh'."
echoinfo "--------------------------------------------------------"
