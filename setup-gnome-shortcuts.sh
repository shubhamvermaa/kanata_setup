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

# Helper to find existing desktop files across distros (Fedora RPM, Flatpak, Snap, Debian/Ubuntu)
find_desktop_file() {
    local candidates=("$@")
    for candidate in "${candidates[@]}"; do
        for dir in "$HOME/.local/share/applications" "/usr/share/applications" "/var/lib/flatpak/exports/share/applications" "/var/lib/snapd/desktop/applications"; do
            if [ -f "$dir/$candidate" ]; then
                echo "$candidate"
                return 0
            fi
        done
    done
    # Try searching by Name= in desktop files
    if [ ${#candidates[@]} -gt 0 ]; then
        local search_name="${candidates[0]}"
        for dir in "$HOME/.local/share/applications" "/usr/share/applications"; do
            if [ -d "$dir" ]; then
                local matched_file
                matched_file=$(grep -l -i "^Name=${search_name}$" "$dir"/*.desktop 2>/dev/null | head -n 1 || true)
                if [ -n "$matched_file" ]; then
                    basename "$matched_file"
                    return 0
                fi
            fi
        done
    fi
    # Fallback to the first candidate if none found on disk
    echo "${candidates[0]}"
}

FIREFOX_DESKTOP=$(find_desktop_file "org.mozilla.firefox.desktop" "firefox.desktop" "firefox_firefox.desktop")
TERMINAL_DESKTOP=$(find_desktop_file "org.gnome.Ptyxis.desktop" "org.gnome.Terminal.desktop")
VSCODE_DESKTOP=$(find_desktop_file "code.desktop" "com.visualstudio.code.desktop" "code_code.desktop")
GHOSTTY_DESKTOP=$(find_desktop_file "com.mitchellh.ghostty.desktop" "ghostty.desktop")
NAUTILUS_DESKTOP=$(find_desktop_file "org.gnome.Nautilus.desktop")
ANTIGRAVITY_DESKTOP=$(find_desktop_file "antigravity-ide.desktop" "antigravity.desktop")
GEMINI_DESKTOP=$(find_desktop_file "com.google.Chrome.flextop.chrome-gdfaincndogidkdcdkhapmbffkckdkhn-Default.desktop" "chrome-gdfaincndogidkdcdkhapmbffkckdkhn-Default.desktop" "Gemini")
CHATGPT_DESKTOP=$(find_desktop_file "com.google.Chrome.flextop.chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default.desktop" "chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default.desktop" "ChatGPT")
NOTION_DESKTOP=$(find_desktop_file "com.google.Chrome.flextop.chrome-dcokohelbbehjlcjjfmhfbpdgfjcoopf-Default.desktop" "chrome-dcokohelbbehjlcjjfmhfbpdgfjcoopf-Default.desktop" "chrome-eggdienekcmbialeignhkgeiiikhchco-Default.desktop" "Notion")

if [ "$TERMINAL_DESKTOP" = "org.gnome.Terminal.desktop" ]; then
    TERMINAL_FALLBACK="gnome-terminal"
else
    TERMINAL_FALLBACK="ptyxis --new-window"
fi

declare -A SHORTCUTS=(
    ["kanata-gemini"]="Switch to Gemini:${GEMINI_DESKTOP}:<Super><Shift>g"
    ["kanata-chatgpt"]="Switch to ChatGPT:${CHATGPT_DESKTOP}:<Super><Shift>c"
    ["kanata-firefox"]="Switch to Firefox:${FIREFOX_DESKTOP}:<Super><Shift>f"
    ["kanata-nautilus"]="Switch to Files:${NAUTILUS_DESKTOP}:nautilus:<Super><Shift>e"
    ["kanata-antigravity"]="Switch to Antigravity:${ANTIGRAVITY_DESKTOP}:<Super><Shift>a"
    ["kanata-vscode"]="Switch to VS Code:${VSCODE_DESKTOP}:<Super><Shift>v"
    ["kanata-ghostty"]="Switch to Ghostty:${GHOSTTY_DESKTOP}:<Super><Shift>t"
    ["kanata-notion"]="Switch to Notion:${NOTION_DESKTOP}:<Super><Shift>n"
    ["kanata-terminal"]="Switch to Terminal:${TERMINAL_DESKTOP}:${TERMINAL_FALLBACK}:<Super><Shift>r"
)

# Read the current custom bindings list safely
CURRENT_BINDINGS=$(dconf read /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings || echo "@as []")

# Remove existing custom50-custom59 bindings to prevent duplicates
CLEANED_BINDINGS=$(echo "$CURRENT_BINDINGS" | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/[^']*'" 2>/dev/null | grep -v 'custom5[0-9]' | tr '\n' ',' | sed 's/,$//' || true)

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

# Ensure window switching includes windows from all workspaces
gsettings set org.gnome.shell.window-switcher current-workspace-only false || true

echosuccess "All custom shortcuts configured non-destructively."
echoinfo "--------------------------------------------------------"
echoinfo "GNOME SETUP COMPLETE!"
echoinfo "1. Please LOG OUT and LOG IN to activate the extension."
echoinfo "2. Ensure you have run 'sudo ./setup-kanata-hardened.sh'."
echoinfo "--------------------------------------------------------"
