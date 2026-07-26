#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script to install GNOME extension and setup shortcuts
# ==============================================================================

# ... setup logging
function echoinfo() { echo -e "\e[34m[INFO]\e[0m $1"; }
function echosuccess() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
function echoerror() { echo -e "\e[31m[ERROR]\e[0m $1"; }

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# 1. Install Extension
echoinfo "Installing GNOME Extension: window-cycler@custom..."
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/window-cycler@custom"
mkdir -p "$EXT_DIR"
cp window-cycler@custom/metadata.json "$EXT_DIR/"
cp window-cycler@custom/extension.js "$EXT_DIR/"
echosuccess "Extension files copied."

echoinfo "Enabling the extension..."
gnome-extensions enable window-cycler@custom || true
echosuccess "Extension added to enabled-extensions list."

# 2. Install Wrapper Script
echoinfo "Installing switch-app-window.sh to $BIN_DIR..."
cp switch-app-window.sh "$BIN_DIR/"
chmod +x "$BIN_DIR/switch-app-window.sh"
echosuccess "Script installed."

# 3. Configure Custom GNOME Shortcuts
echoinfo "Configuring Custom GNOME Shortcuts..."

BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

declare -A SHORTCUTS=(
    ["kanata-gemini"]="Switch to Gemini:chrome-gdfaincndogidkdcdkhapmbffkckdkhn-Default.desktop:<Super><Shift>g"
    ["kanata-chatgpt"]="Switch to ChatGPT:chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default.desktop:<Super><Shift>c"
    ["kanata-firefox"]="Switch to Firefox:firefox_firefox.desktop:<Super><Shift>f"
    ["kanata-nautilus"]="Switch to Files:org.gnome.Nautilus.desktop:nautilus:<Super><Shift>e"
    ["kanata-antigravity"]="Switch to Antigravity:antigravity-ide.desktop:<Super><Shift>a"
    ["kanata-vscode"]="Switch to VS Code:code.desktop:<Super><Shift>v"
    ["kanata-ghostty"]="Switch to Ghostty:com.mitchellh.ghostty.desktop:<Super><Shift>t"
    ["kanata-notion"]="Switch to Notion:chrome-eggdienekcmbialeignhkgeiiikhchco-Default.desktop:<Super><Shift>n"
    ["kanata-terminal"]="Switch to Terminal:org.gnome.Ptyxis.desktop:ptyxis --new-window:<Super><Shift>r"
)

# Read the current custom bindings list safely
CURRENT_BINDINGS=$(dconf read /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings || echo "@as []")

# Remove existing custom50-custom59 bindings to prevent duplicates
CLEANED_BINDINGS=$(echo "$CURRENT_BINDINGS" | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/[^']*'" | grep -v 'custom5[0-9]' | tr '\n' ',' | sed 's/,$//')

declare -a BINDINGS_ARR=()
if [ -n "$CLEANED_BINDINGS" ] && [ "$CLEANED_BINDINGS" != "@as []" ] && [ "$CLEANED_BINDINGS" != "[]" ]; then
    CLEAN_BINDINGS=$(echo "$CLEANED_BINDINGS" | tr -d "[]'" | tr "," "\n" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            BINDINGS_ARR+=("$line")
        fi
    done <<< "$CLEAN_BINDINGS"
fi

# Generate new custom5X binding paths
NEW_PATHS=""
counter=50
for key in "${!SHORTCUTS[@]}"; do
    path="$BASE_PATH/custom${counter}/"
    NEW_PATHS="$NEW_PATHS'$path', "
    counter=$((counter + 1))
done

# Build the new array string
BINDINGS_LIST="["
if [ ${#BINDINGS_ARR[@]} -gt 0 ]; then
    for b in "${BINDINGS_ARR[@]}"; do
        BINDINGS_LIST="$BINDINGS_LIST'$b', "
    done
fi
BINDINGS_LIST="${BINDINGS_LIST}${NEW_PATHS%, }]"

dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "$BINDINGS_LIST"

# Apply each shortcut's details
counter=50
for key in "${!SHORTCUTS[@]}"; do
    details="${SHORTCUTS[$key]}"
    path="custom${counter}/"
    counter=$((counter + 1))
    
    name="${details%%:*}"
    remaining="${details#*:}"
    app_id="${remaining%%:*}"
    remaining="${remaining#*:}"
    
    if [[ "$remaining" == *:* ]]; then
        fallback="${remaining%%:*}"
        binding="${remaining#*:}"
    else
        fallback=""
        binding="$remaining"
    fi
    
    cmd=""
    if [[ "$app_id" == !* ]]; then
        cmd="${app_id:1}"
    else
        cmd="$BIN_DIR/switch-app-window.sh $app_id"
        if [ -n "$fallback" ]; then
            cmd="$cmd $fallback"
        fi
    fi

    dconf write "$BASE_PATH/$path"name "'$name'"
    dconf write "$BASE_PATH/$path"command "'$cmd'"
    dconf write "$BASE_PATH/$path"binding "'$binding'"
done

echosuccess "All custom shortcuts configured non-destructively."
echoinfo "--------------------------------------------------------"
echoinfo "GNOME SETUP COMPLETE!"
echoinfo "1. Please LOG OUT and LOG IN to activate the extension."
echoinfo "2. Ensure you have run 'sudo ./setup-kanata-hardened.sh'."
echoinfo "--------------------------------------------------------"
