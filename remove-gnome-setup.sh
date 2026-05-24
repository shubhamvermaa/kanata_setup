#!/usr/bin/env bash

# ==============================================================================
# Script to remove Kanata GNOME shortcuts and Extension
# ==============================================================================

set -euo pipefail

EXTENSION_UUID="window-cycler@custom"
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
BIN_DIR="$HOME/.local/bin"

echoinfo() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
echosucc() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }

# 1. Disable the Extension
echoinfo "Disabling GNOME Extension: $EXTENSION_UUID..."
gnome-extensions disable "$EXTENSION_UUID" 2>/dev/null || true
echosucc "Extension disabled."

# 2. Remove Extension Files
echoinfo "Removing extension files..."
rm -rf "$EXTENSIONS_DIR/$EXTENSION_UUID"
echosucc "Extension files removed."

# 3. Remove switch-app-window.sh script
echoinfo "Removing switch-app-window.sh script..."
rm -f "$BIN_DIR/switch-app-window.sh"
echosucc "Script removed."

# 4. Remove Custom GNOME Shortcuts
echoinfo "Removing Custom GNOME Shortcuts..."

BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# Remove custom1 through custom8 from the bindings array
for i in {1..8}; do
    TARGET="'$BASE_PATH/custom$i/'"
    CURRENT_BINDINGS=$(echo "$CURRENT_BINDINGS" | sed "s|$TARGET, ||g" | sed "s|, $TARGET||g" | sed "s|$TARGET||g")
    
    # Reset the individual keybinding entries
    gsettings reset "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BASE_PATH/custom$i/" name || true
    gsettings reset "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BASE_PATH/custom$i/" command || true
    gsettings reset "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BASE_PATH/custom$i/" binding || true
done

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$CURRENT_BINDINGS"

echosucc "Shortcuts removed."

echoinfo "--------------------------------------------------------"
echoinfo "GNOME SETUP REMOVAL COMPLETE!"
echoinfo "Please LOG OUT and LOG IN to fully clear the extension state."
echoinfo "--------------------------------------------------------"
