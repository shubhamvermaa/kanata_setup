import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';

const DBUS_IFACE_XML = `
<node>
  <interface name="org.gnome.Shell.Extensions.WindowCycler">
    <method name="CycleAppWindows">
      <arg type="s" name="app_id" direction="in"/>
      <arg type="i" name="result" direction="out"/>
    </method>
  </interface>
</node>`;

export default class WindowCyclerExtension {
  constructor() {
    this._connection = null;
    this._regId = null;
    this._lastAppWindows = {};
  }

  _onCycleAppWindows(connection, sender, objectPath, interfaceName, methodName, params, invocation) {
    try {
      const appId = params.deepUnpack()[0];
      const display = global.get_display();
      const workspaceManager = global.get_workspace_manager();
      const windows = [];

      for (let ws = workspaceManager.get_n_workspaces() - 1; ws >= 0; ws--) {
        const workspace = workspaceManager.get_workspace_by_index(ws);
        for (const win of workspace.list_windows()) {
          if (win.skip_taskbar || win.get_window_type() === Meta.WindowType.DOCK || win.get_window_type() === Meta.WindowType.DESKTOP)
            continue;
          const app = Shell.WindowTracker.get_default().get_window_app(win);
          
          let isMatch = false;
          if (app && app.get_id() === appId) {
            isMatch = true;
          } else if (app && (app.get_id() === appId + '.desktop' || app.get_id() + '.desktop' === appId)) {
            isMatch = true;
          } else if (appId.toLowerCase().includes('firefox') && app && app.get_id().toLowerCase().includes('firefox')) {
            isMatch = true;
          } else {
            const title = win.get_title() ? win.get_title().toLowerCase() : '';
            const wmClass = win.get_wm_class() ? win.get_wm_class().toLowerCase() : '';
            const appIdLower = appId.toLowerCase();

            if (appIdLower.includes('notion') || appIdLower.includes('dcokohelbbehjlcjjfmhfbpdgfjcoopf') || appIdLower.includes('eggdienek')) {
              if (title.includes('notion') || wmClass.includes('dcokohelbbehjlcjjfmhfbpdgfjcoopf') || wmClass.includes('eggdienek')) {
                isMatch = true;
              }
            } else if (appIdLower.includes('gemini') || appIdLower.includes('gdfaincndogidkdcdkhapmbffkckdkhn')) {
              if (title.includes('gemini') || wmClass.includes('gdfaincndogidkdcdkhapmbffkckdkhn')) {
                isMatch = true;
              }
            } else if (appIdLower.includes('chatgpt') || appIdLower.includes('cadlkienfkclaiaibeoongdcgmdikeeg')) {
              if (title.includes('chatgpt') || wmClass.includes('cadlkienfkclaiaibeoongdcgmdikeeg')) {
                isMatch = true;
              }
            }
          }
          
          if (isMatch)
            windows.push(win);
        }
      }

      const count = windows.length;
      let result;

      if (count === 0) {
        result = 0;
      } else if (count === 1) {
        windows[0].activate(global.get_current_time());
        result = 1;
      } else {
        const activeWin = display.get_focus_window();
        let activeIdx = -1;
        for (let i = 0; i < windows.length; i++) {
          if (windows[i] === activeWin) { activeIdx = i; break; }
        }
        const prev = this._lastAppWindows[appId] || -1;
        let nextIdx = (prev >= 0 && prev < count && prev !== activeIdx) ? prev : (activeIdx + 1) % count;
        this._lastAppWindows[appId] = nextIdx;
        windows[nextIdx].activate(global.get_current_time());
        result = count;
      }

      invocation.return_value(new GLib.Variant('(i)', [result]));
    } catch (e) {
      log('WindowCycler error: ' + e.message);
      invocation.return_dbus_error('org.gnome.Shell.Extensions.WindowCycler.Error', e.message);
    }
  }

  enable() {
    const nodeInfo = Gio.DBusNodeInfo.new_for_xml(DBUS_IFACE_XML);
    this._connection = Gio.DBus.session;
    this._regId = this._connection.register_object(
      '/org/gnome/shell/extensions/WindowCycler',
      nodeInfo.interfaces[0],
      (conn, sender, path, iface, method, params, invocation) => {
          this._onCycleAppWindows(conn, sender, path, iface, method, params, invocation);
      },
      null,
      null
    );
    log('WindowCycler: D-Bus interface registered');
  }

  disable() {
    if (this._regId !== null && this._connection) {
      this._connection.unregister_object(this._regId);
      this._regId = null;
    }
    this._lastAppWindows = {};
    log('WindowCycler: D-Bus interface removed');
  }
}
