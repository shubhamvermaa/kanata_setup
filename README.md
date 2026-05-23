# Kanata GNOME Setup

Hardened Kanata setup with a dedicated service and custom GNOME window switching/cycling.

**Verified Working Environment:**
- **OS**: Ubuntu 26.04 (Rolling)
- **Display Server**: Wayland Only
- **Desktop Environment**: GNOME 50.1

---

## ✨ How It Works

Think of `Capslock` as a **"leader key"** (similar to Vim or tmux).

- Press `Caps + F` → Jump to Firefox
- Press it again → Cycle through Firefox windows
- If Firefox is closed → It launches automatically

It behaves like a **smart app switcher**, not just a shortcut.

---

## 🧠 Architecture Overview

This setup removes the "black box" by combining two distinct layers:

1. **Kanata (Keyboard Layer)**:
   - Captures `Capslock + key` at the kernel level.
   - Translates it into a virtual shortcut (e.g., `Super + Shift + F`).
2. **GNOME Layer (Window Logic)**:
   - GNOME intercepts the virtual shortcut.
   - Triggers a script + extension that:
     - Detects existing app windows (even sandboxed Snaps).
     - Decides whether to focus, cycle, or launch.

---

## 🔒 Security (Why "Hardened"?)

- **Restricted User**: The `kanata` service runs as a non-login, restricted system user.
- **Isolation**: It has no access to your home directory or personal files.
- **Principle of Least Privilege**: It only has permissions to read input devices and emit virtual keys.
- **Why?**: Keyboard remappers run with high privileges. This setup minimizes the attack surface by isolating the remapper from your main user session.

---

## 🚀 Customize with AI

The application bindings provided are part of my personal configuration. **You are encouraged to customize them!**

1. **Clone the repo**.
2. **Open the workspace** with an AI-assisted tool (Cursor, Zed, or Gemini CLI).
3. **Ask the AI**: *"Add a new Capslock binding for [App Name] in the Kanata config and the GNOME setup script."*

---

## ✍️ Manual Customization (Alternative)

If you prefer to do it yourself:
1. Find the `.desktop` file: `ls /usr/share/applications | grep -i <app>`
2. Update `kanata-config.kbd` to emit a unique shortcut.
3. Update `setup-gnome-shortcuts.sh` with the new ID and shortcut.
4. Apply changes and restart the service.

---

## 📋 Pre-requisites

This setup relies on **Kanata**, a software keyboard remapper.

1. **Kanata Installation**: The `setup-kanata-hardened.sh` script will attempt to install version `v1.7.0` for you.
2. **Documentation**: Refer to the [Official Kanata Documentation](https://github.com/jtroo) for config syntax.

---

## 🛠 Installation

The setup is split into two scripts. **Order matters for the best experience**:

### 1. GNOME UI Setup (User Level)
Installs the window-cycling extension and configures all 7 custom keyboard shortcuts.
```bash
chmod +x setup-gnome-shortcuts.sh switch-app-window.sh
./setup-gnome-shortcuts.sh
```
**IMPORTANT**: You MUST **Log Out and Log In** after this step to activate the GNOME extension.

### 2. Kanata Service Setup (System Level)
Downloads Kanata and starts the background service.
```bash
chmod +x setup-kanata-hardened.sh
sudo ./setup-kanata-hardened.sh
```

---

## ✅ Verify Installation

Run:
```bash
systemctl status kanata.service
```
**Expected**: Service is `active (running)`.

**Test**: Press `Capslock + F`. Firefox should open, focus, or cycle immediately.

---

## 🏷 Active Shortcuts (Default Config)

| Key | Application | GNOME Shortcut |
| :--- | :--- | :--- |
| **F** | Firefox | `Super+Shift+F` |
| **E** | Files (Nautilus) | `Super+Shift+E` |
| **G** | Gemini (Chrome App) | `Super+Shift+G` |
| **C** | ChatGPT (Chrome App) | `Super+Shift+C` |
| **A** | Antigravity IDE | `Super+Shift+A` |
| **V** | VS Code | `Super+Shift+V` |
| **T** | Ghostty | `Super+Shift+Y`* |

*\*Ghostty uses Y to avoid system screenshot conflicts.*

---

## 🐛 Troubleshooting

- **Wayland Limitation**: Wayland restricts background window focus. This is why the **GNOME Extension** included in this repo is mandatory.
- **Keys not detected**: Run `sudo kanata -d` to see live key events for debugging.
- **App not focusing**: Ensure the `.desktop` ID in `setup-gnome-shortcuts.sh` exactly matches the app's internal ID.

---

## 🤝 Contributing & Support
I am open to **suggestions**, **feature requests**, and **issue reports**! Please feel free to open an issue.

**If you find this setup helpful, please give it a ⭐ on GitHub!**

---

## 🗑 Removal
To revert all system changes:
```bash
sudo ./remove-kanata.sh
```
