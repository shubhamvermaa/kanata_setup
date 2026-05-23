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

let _connection = null;
let _regId = null;
let _lastAppWindows = {};

function onCycleAppWindows(connection, sender, objectPath, interfaceName, methodName, params, invocation) {
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
        if (app && app.get_id() === appId)
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
      const prev = _lastAppWindows[appId] || -1;
      let nextIdx = (prev >= 0 && prev < count && prev !== activeIdx) ? prev : (activeIdx + 1) % count;
      _lastAppWindows[appId] = nextIdx;
      windows[nextIdx].activate(global.get_current_time());
      result = count;
    }

    invocation.return_value(new GLib.Variant('(i)', [result]));
  } catch (e) {
    log('WindowCycler error: ' + e.message);
    invocation.return_dbus_error('org.gnome.Shell.Extensions.WindowCycler.Error', e.message);
  }
}

export default class WindowCyclerExtension {
  enable() {
    const nodeInfo = Gio.DBusNodeInfo.new_for_xml(DBUS_IFACE_XML);
    _connection = Gio.DBus.session;
    _regId = _connection.register_object(
      '/org/gnome/shell/extensions/WindowCycler',
      nodeInfo.interfaces[0],
      (conn, sender, path, iface, method, params, invocation) => {
          onCycleAppWindows(conn, sender, path, iface, method, params, invocation);
      },
      null,
      null
    );
    log('WindowCycler: D-Bus interface registered');
  }

  disable() {
    if (_regId !== null && _connection) {
      _connection.unregister_object(_regId);
      _regId = null;
    }
    _lastAppWindows = {};
    log('WindowCycler: D-Bus interface removed');
  }
}
