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
CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

# Convert the gsettings array to a clean bash list of paths
declare -a BINDINGS_ARR=()
if [ "$CURRENT_BINDINGS" != "@as []" ] && [ "$CURRENT_BINDINGS" != "[]" ]; then
    CLEAN_BINDINGS=$(echo "$CURRENT_BINDINGS" | tr -d "[]'" | tr "," "\n" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            BINDINGS_ARR+=("$line")
        fi
    done <<< "$CLEAN_BINDINGS"
fi

# Build a new array excluding any paths containing '/kanata-'
declare -a REMAINING_ARR=()
for path in "${BINDINGS_ARR[@]}"; do
    if [[ "$path" == *"/kanata-"* ]]; then
        echoinfo "Clearing keybinding at path: $path"
        # Reset the individual keybinding entries
        gsettings reset "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" name || true
        gsettings reset "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" command || true
        gsettings reset "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" binding || true
    else
        REMAINING_ARR+=("$path")
    fi
done

# Rebuild the gsettings array string
if [ ${#REMAINING_ARR[@]} -eq 0 ]; then
    BINDINGS_LIST="[]"
else
    BINDINGS_LIST="["
    for i in "${!REMAINING_ARR[@]}"; do
        if [ "$i" -gt 0 ]; then
            BINDINGS_LIST+=", "
        fi
        BINDINGS_LIST+="'${REMAINING_ARR[$i]}'"
    done
    BINDINGS_LIST+="]"
fi

# Set the custom keybindings array with only the remaining user shortcuts
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$BINDINGS_LIST"

echosucc "Shortcuts removed."

echoinfo "--------------------------------------------------------"
echoinfo "GNOME SETUP REMOVAL COMPLETE!"
echoinfo "Please LOG OUT and LOG IN to fully clear the extension state."
echoinfo "--------------------------------------------------------"
