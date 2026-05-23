# Kanata GNOME Setup

Hardened Kanata setup with a dedicated service and custom GNOME window switching/cycling.

## Features
- **Capslock + Key**: Focus application, cycle through windows, or launch if not running.
- **Hardened Service**: Runs as a restricted `kanata` user for maximum security.
- **Wayland Support**: Uses a custom GNOME extension to bypass Snap sandboxing (Firefox/Chrome).

## Installation

The setup is split into two scripts. You can run them in any order, but the order below is recommended.

### 1. GNOME UI Setup (User Level)
This installs the window-cycling extension and configures all 7 custom keyboard shortcuts.
```bash
./setup-gnome-shortcuts.sh
```
**IMPORTANT**: You MUST **Log Out and Log In** after running this script to activate the GNOME extension.

### 2. Kanata Service Setup (System Level)
This downloads Kanata, sets up the restricted user, and starts the background service.
```bash
sudo ./setup-kanata-hardened.sh
```

## Active Shortcuts (Capslock Layer)

| Key | Application | GNOME Shortcut |
| :--- | :--- | :--- |
| **F** | Firefox | `Super+Shift+F` |
| **E** | Files (Nautilus) | `Super+Shift+E` |
| **G** | Gemini (Chrome App) | `Super+Shift+G` |
| **C** | ChatGPT (Chrome App) | `Super+Shift+C` |
| **A** | Antigravity IDE | `Super+Shift+A` |
| **V** | VS Code | `Super+Shift+V` |
| **T** | Ghostty | `Super+Shift+Y`* |

*\*Ghostty uses Super+Shift+Y to avoid system-level screenshot conflicts.*

## Troubleshooting

- **Delay or New Windows opening**: 
    1. Ensure the `Window Cycler` extension is enabled in the GNOME "Extensions" app.
    2. Ensure you logged out/in after running the setup script.
- **Shortcut not working**: Ensure you have restarted the Kanata service after any config changes:
  ```bash
  sudo systemctl restart kanata.service
  ```

## Removal
To revert all system changes:
```bash
sudo ./remove-kanata.sh
```
