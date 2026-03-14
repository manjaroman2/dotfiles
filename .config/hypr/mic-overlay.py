#!/usr/bin/env python3
import gi, subprocess, signal
gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, GtkLayerShell, GLib, Pango
import threading

class MicOverlay(Gtk.Window):
    def __init__(self):
        super().__init__()
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 10)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 10)
        GtkLayerShell.set_exclusive_zone(self, -1)  # don't push other windows
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)

        self.label = Gtk.Label()
        self.label.set_markup('<span size="20000">🎤</span>')
        self.add(self.label)

        css = Gtk.CssProvider()
        css.load_from_data(b"""
            window { background: rgba(30,30,30,0.75); border-radius: 12px; padding: 6px 10px; }
            label { color: white; }
        """)
        Gtk.StyleContext.add_provider_for_screen(
            self.get_screen(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.update_status()
        threading.Thread(target=self.watch_pactl, daemon=True).start()
        # self.update_status()
        # GLib.timeout_add(500, self.update_status)  # poll every 500ms

    def update_status(self):
        try:
            src = subprocess.check_output(
                ["pactl", "get-default-source"], text=True
            ).strip()
            mute = subprocess.check_output(
                ["pactl", "get-source-mute", src], text=True
            ).strip()
            is_muted = "yes" in mute
        except Exception:
            is_muted = False

        if is_muted:
            self.label.set_markup('<span size="20000">🔇</span>')
        else:
            self.label.set_markup('<span size="20000">🎤</span>')
        return True

    def watch_pactl(self):
        proc = subprocess.Popen(
            ["pactl", "subscribe"], stdout=subprocess.PIPE, text=True
        )
        for line in proc.stdout:
            if "source" in line:
                GLib.idle_add(self.update_status)

signal.signal(signal.SIGINT, signal.SIG_DFL)
win = MicOverlay()
win.show_all()
Gtk.main()
