# Kanata GNOME Setup

Hardened Kanata setup with a dedicated service and custom GNOME window switching/cycling.

**Verified Working Environment:**
- **OS**: Ubuntu 26.04 (Rolling)
- **Display Server**: Wayland Only
- **Desktop Environment**: GNOME 50.1

## Features
- **Capslock + Key**: Focus application, cycle through windows, or launch if not running.
- **Hardened Service**: Runs as a restricted `kanata` user for maximum security.
- **Wayland Support**: Uses a custom GNOME extension to bypass Snap sandboxing (Firefox/Chrome).

## 🚀 Customize with AI

The application bindings provided in this repository are part of my personal configuration. **You are encouraged to customize them for your own workflow!**

The easiest way to add your own apps:
1. **Clone the repo**.
2. **Open the workspace** with an AI-assisted tool (like Cursor, Zed, or Gemini CLI).
3. **Ask the AI** to: *"Add a new Capslock binding for [Your App Name] in the Kanata config and the GNOME setup script."*

The AI can automatically find your `.desktop` IDs and update the scripts for you.

## Pre-requisites

This setup relies on **Kanata**, a software keyboard remapper. 

1. **Kanata Installation**: You should have Kanata installed on your system. If not, the `setup-kanata-hardened.sh` script in this repo will attempt to download and install version `v1.7.0` for you.
2. **Knowledge Base**: For detailed information on how Kanata works, its configuration syntax, and advanced features, refer to the official documentation:
   - [Official Kanata Documentation](https://github.com/jtroo/kanata)

---

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

## Contributing & Support
I am open to **suggestions**, **feature requests**, and **issue reports**! Please feel free to open an issue on GitHub if you find a bug or have an idea for improvement.

## Removal
To revert all system changes:
```bash
sudo ./remove-kanata.sh
```
