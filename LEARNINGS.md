# Learnings: GNOME Custom Shortcuts & Kanata on Wayland

Undocumented quirks and gotchas hit while getting Kanata + GNOME working on Wayland. All of these were verified on Ubuntu 26.04 / GNOME 50.

### 1. GNOME Custom Keybinding Paths (`gsd-media-keys`)
When programmatically setting custom shortcuts via `gsettings` or `dconf`, the path **must** follow the `customX` naming convention (e.g., `custom50`, `custom51`).
- **Pitfall:** `gsettings` will happily accept and store shortcuts under arbitrary paths like `.../custom-keybindings/kanata-terminal/`.
- **Reality:** `gsd-media-keys` strictly ignores any path that doesn't match its hardcoded `custom[0-9]+` regex. Arbitrary names get stored in the database but never trigger — and `gsettings get` still shows them as if they're active.

### 2. GSettings vs DConf in Background Execution
`gsettings set` behaves unpredictably when invoked from non-interactive shells, SSH sessions, or background daemons.
- **Pitfall:** Background processes typically lack the `DBUS_SESSION_BUS_ADDRESS` environment variable. Without it, `gsettings set` silently writes to a volatile in-memory cache instead of the real dconf database. `gsettings get` reads from that same cache, so it reflects the "new" value — but the GNOME shell never sees the change. Everything looks correct. Nothing actually works.
- **Fix:** Bypass `gsettings` entirely and use `dconf write` for any shortcut automation. `dconf` writes directly to the on-disk GVDB file (`~/.config/dconf/user`), and GNOME Shell picks up the change instantly via inotify — regardless of the calling process's D-Bus session state.

### 3. Wayland Focus Stealing Prevention
Background shell scripts cannot force an existing application window to the front on Wayland.
- **Pitfall:** `wmctrl`, `xdotool`, and similar X11 tools don't work on Wayland. A background script that tries to bring an app to the foreground will get a silent "Window is ready" notification instead of an actual focus switch.
- **Fix:** Focus changes must happen *inside* the compositor. The `WindowCycler` GNOME Shell Extension in this repo exposes a D-Bus method that calls `window.activate(global.get_current_time())` from within the shell process itself — giving the background script the authority it needs to actually raise windows.
