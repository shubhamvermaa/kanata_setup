#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script to set up Kanata with a dedicated user and hardened systemd service
# ==============================================================================

# CONFIGURATION

# System location where the kanata config file will be placed
# (DO NOT EDIT)
SYSTEM_KANATA_CONFIG_DST="/etc/kanata/kanata-config.kbd"

# Kanata version to download
KANATA_VERSION="v1.11.0"
KANATA_ZIP_SHA256="d9f634afb4c7f078cc2aacf3998fd65b432d4d83296cc48a89f941525459b4e2"

# Dedicated user/group names
KANATA_USER="kanata"
UINPUT_GROUP="uinput"

# FUNCTION TO PRINT MESSAGES
echoinfo() {
    echo "[INFO] $1"
}
echoerror() {
    echo "[ERROR] $1" >&2
}

# CHECK FOR ROOT/SUDO
if [ "$(id -u)" -ne 0 ]; then
  echoerror "This script must be run with sudo or as root."
  exit 1
fi

# DETERMINE SOURCE CONFIG FILE PATH
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_KANATA_CONFIG_SRC="$SCRIPT_DIR/kanata-config.kbd"

if [ ! -f "$USER_KANATA_CONFIG_SRC" ]; then
    echoerror "Kanata config file not found at: $USER_KANATA_CONFIG_SRC"
    exit 1
fi

echoinfo "Using source config file: $USER_KANATA_CONFIG_SRC"

echoinfo "Starting Kanata hardened setup..."

#========================
# STEP 1: Create User/Group
#========================
echoinfo "Creating group '$UINPUT_GROUP' (if it doesn't exist)..."
if ! getent group "$UINPUT_GROUP" >/dev/null; then
    groupadd "$UINPUT_GROUP"
else
    echoinfo "Group '$UINPUT_GROUP' already exists."
fi

echoinfo "Creating user '$KANATA_USER' (if it doesn't exist)..."
if ! id -u "$KANATA_USER" >/dev/null 2>&1; then
    useradd --system --no-create-home --groups input,"$UINPUT_GROUP" --shell /bin/false --user-group "$KANATA_USER"
else
    echoinfo "User '$KANATA_USER' already exists."
fi

#========================
# STEP 2: Prepare Config Directory & Copy Config
#========================
echoinfo "Creating directory /etc/kanata..."
mkdir -p /etc/kanata

echoinfo "Copying Kanata config from $USER_KANATA_CONFIG_SRC to $SYSTEM_KANATA_CONFIG_DST..."
if ! cp "$USER_KANATA_CONFIG_SRC" "$SYSTEM_KANATA_CONFIG_DST"; then
    echoerror "Failed to copy config file. Please check permissions and paths."
    exit 1
fi

#========================
# STEP 3: Set Config Permissions
#========================
echoinfo "Setting permissions on $SYSTEM_KANATA_CONFIG_DST..."
chown root:"$KANATA_USER" "$SYSTEM_KANATA_CONFIG_DST"
chmod 640 "$SYSTEM_KANATA_CONFIG_DST"

#========================
# STEP 4: Create udev Rule
#========================
echoinfo "Creating udev rule for /dev/uinput..."
echo "KERNEL==\"uinput\", MODE=\"0660\", GROUP=\"$UINPUT_GROUP\", OPTIONS+=\"static_node=uinput\"" > /etc/udev/rules.d/50-kanata.rules

#========================
# STEP 5: Download and Install Kanata
#========================
KANATA_ZIP_URL="https://github.com/jtroo/kanata/releases/download/${KANATA_VERSION}/linux-binaries-x64.zip"
KANATA_BIN_PATH="/usr/local/bin/kanata"
TEMP_ZIP="/tmp/kanata-linux-binaries.zip"

echoinfo "Stopping kanata.service (if running) before download..."
systemctl stop kanata.service > /dev/null 2>&1 || true # Stop the service, ignore errors

# Ensure unzip is installed
if ! command -v unzip &> /dev/null; then
    echoinfo "'unzip' command not found. Attempting to install it..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y unzip
    elif command -v dnf &> /dev/null; then
        dnf install -y unzip
    elif command -v pacman &> /dev/null; then
        pacman -Sy --noconfirm unzip
    else
        echoerror "unzip is missing and no supported package manager was found. Please install unzip manually."
        exit 1
    fi
fi

echoinfo "Downloading Kanata ${KANATA_VERSION} from ${KANATA_ZIP_URL}..."
if ! curl -fSL -o "$TEMP_ZIP" "$KANATA_ZIP_URL"; then
    echoerror "Failed to download Kanata zip. Check URL or network connection."
    exit 1
fi

echoinfo "Verifying SHA256 checksum..."
echo "$KANATA_ZIP_SHA256  $TEMP_ZIP" | sha256sum -c -

echoinfo "Extracting Kanata binary..."
if ! unzip -o "$TEMP_ZIP" kanata_linux_x64 -d /usr/local/bin/; then
    echoerror "Failed to extract Kanata binary from zip."
    rm -f "$TEMP_ZIP"
    exit 1
fi

mv /usr/local/bin/kanata_linux_x64 "$KANATA_BIN_PATH"
rm -f "$TEMP_ZIP"

echoinfo "Setting permissions on ${KANATA_BIN_PATH}..."
chown root:"$KANATA_USER" "$KANATA_BIN_PATH"
chmod 754 "$KANATA_BIN_PATH"

#========================
# STEP 6: Create Systemd Service Unit
#========================
echoinfo "Creating systemd service file /etc/systemd/system/kanata.service..."
# Use cat with EOF for cleaner multi-line definition
cat << EOF > /etc/systemd/system/kanata.service
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata
Wants=modprobe@uinput.service
After=modprobe@uinput.service

[Service]
Type=simple
User=$KANATA_USER
Group=$KANATA_USER
ExecStart=$KANATA_BIN_PATH --quiet --cfg $SYSTEM_KANATA_CONFIG_DST
Restart=no
# Security
CapabilityBoundingSet=
DeviceAllow=/dev/uinput rw
DeviceAllow=char-input
DeviceAllow=/dev/stdin
DevicePolicy=strict
PrivateDevices=true
BindPaths=/dev/uinput
BindReadOnlyPaths=/dev/stdin
BindReadOnlyPaths=/dev/input/
InaccessiblePaths=/dev/shm
LockPersonality=true
NoNewPrivileges=true
PrivateTmp=true
PrivateNetwork=true
PrivateUsers=true
#ProtectClock=true # Disabled as per original example notes
ProtectHome=true
ProtectHostname=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectSystem=strict
ProtectControlGroups=true
# Allow only Unix sockets, deny others like network
RestrictAddressFamilies=AF_UNIX
RestrictNamespaces=true
SystemCallArchitectures=native
SystemCallErrorNumber=EPERM
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources
RemoveIPC=true
IPAddressDeny=any
RestrictSUIDSGID=true
RestrictRealtime=true
MemoryDenyWriteExecute=true
UMask=0077

[Install]
WantedBy=multi-user.target
EOF

#========================
# STEP 7: Reload Systemd, Apply udev, Enable & Start Service
#========================
echoinfo "Reloading systemd daemon..."
systemctl daemon-reload

echoinfo "Applying udev rules and device permissions immediately..."
udevadm control --reload-rules && udevadm trigger || echoinfo "Unable to trigger udevadm (often normal inside containers)."
if [ -c /dev/uinput ]; then
    chgrp "$UINPUT_GROUP" /dev/uinput && chmod 0660 /dev/uinput
    echoinfo "/dev/uinput permissions updated successfully."
else
    echoinfo "/dev/uinput device node not found. It will be initialized on next boot."
fi

echoinfo "Enabling kanata.service..."
systemctl enable kanata.service

echoinfo "Starting/Restarting kanata.service..."
systemctl restart kanata.service

echoinfo "-----------------------------------------------------"
echoinfo "Kanata setup script finished!"
echoinfo "The background service has been started and is active."
echoinfo "You should be able to use Kanata immediately!"
echoinfo "Check status with: systemctl status kanata.service"
echoinfo "(If shortcuts aren't active immediately, a quick reboot is recommended.)"
echoinfo "-----------------------------------------------------"

exit 0
