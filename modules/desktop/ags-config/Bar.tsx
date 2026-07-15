import { createBinding, createConnection, For, onCleanup } from "ags"
import { createPoll } from "ags/time"
import { readFile } from "ags/file"
import { execAsync } from "ags/process"
import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import GLib from "gi://GLib"
import Hyprland from "gi://AstalHyprland"
import Tray from "gi://AstalTray"
import Wp from "gi://AstalWp"

function getIconName(windowClass: string): string {
    const lower = windowClass.toLowerCase()
    // Some apps need manual mapping
    const overrides: Record<string, string> = {
        "code": "visual-studio-code",
        "code - oss": "visual-studio-code",
        "teams-for-linux": "teams",
    }
    return overrides[lower] ?? lower
}

function Workspaces({ monitor }: { monitor: string }) {
    const hyprland = Hyprland.get_default()
    const { accent: accentColor } = getWalColors()
    const workspaces = createBinding(hyprland, "workspaces")
    // The "clients" property only notifies on add/remove, not on moves between
    // workspaces. Re-read the list on client-moved too so workspace icons
    // follow windows across workspaces.
    const clients = createConnection<Hyprland.Client[]>(
        hyprland.get_clients(),
        [hyprland, "client-added", () => hyprland.get_clients()],
        [hyprland, "client-removed", () => hyprland.get_clients()],
        [hyprland, "client-moved", () => hyprland.get_clients()],
    )

    return (
        <box class="workspaces">
            <For each={workspaces((ws) => ws.filter((w) => w.get_id() > 0).sort((a, b) => a.get_id() - b.get_id()))}>
                {(ws) => {
                    const wsClasses = clients((cls) =>
                        [...new Set(
                            cls.filter((c) => c.get_workspace()?.get_id() === ws.get_id())
                               .map((c) => c.get_class())
                        )]
                    )
                    // Both class and css must react to workspace-moved events, since
                    // ws.get_monitor() is live state that changes when the workspace
                    // is moved between monitors.
                    const getClass = () => {
                        if (hyprland.focusedWorkspace?.get_id() === ws.get_id()) return "focused"
                        if (ws.get_monitor()?.get_name() !== monitor) return "other-monitor"
                        return ""
                    }
                    const getCSS = () => ws.get_monitor()?.get_name() === monitor
                        ? `border-color: ${accentColor};`
                        : ""
                    return (
                        <button
                            class={createConnection(
                                getClass(),
                                [hyprland, "notify::focused-workspace", getClass],
                                [hyprland, "notify::workspaces",        getClass],
                                [hyprland, "notify::monitors",          getClass],
                            )}
                            css={createConnection(
                                getCSS(),
                                [hyprland, "notify::workspaces", getCSS],
                                [hyprland, "notify::monitors",   getCSS],
                            )}
                            onClicked={() => hyprland.message(`dispatch hl.dsp.focus({ workspace = ${ws.get_id()} })`)}
                        >
                            <box>
                                <label label={wsClasses((c) => c.length > 0 ? `${ws.get_id()}` : ws.get_id().toString())} />
                                <For each={wsClasses}>
                                    {(cls) => <image class="ws-icon" iconName={getIconName(cls)} />}
                                </For>
                            </box>
                        </button>
                    )
                }}
            </For>
        </box>
    )
}

// Wraps the workspace widget in a Gtk.Overlay and places a full-width
// indicator on top whenever a special workspace is active on this monitor.
function WorkspacesWithSpecialOverlay({ monitor }: { monitor: string }) {
    const hyprland = Hyprland.get_default()
    const { accent: accentColor } = getWalColors()

    const getSpecialName = (): string | null => {
        const mon = hyprland.get_monitors().find((m) => m.get_name() === monitor)
        if (!mon) return null
        // Monitor.specialWorkspace is a Workspace GObject; name="" when none active
        const sw = (mon as any).specialWorkspace as { name: string } | null | undefined
        const name = sw?.name ?? ""
        return name.startsWith("special:") ? name.replace("special:", "") : null
    }

    const getSpecialClasses = (): string[] => {
        const name = getSpecialName()
        if (!name) return []
        const wsName = `special:${name}`
        return [...new Set(
            hyprland.get_clients()
                .filter((c) => (c.get_workspace() as any)?.name === wsName)
                .map((c) => c.get_class())
        )]
    }

    // "event" fires for every raw Hyprland IPC event, including "activespecial"
    // which triggers on special workspace toggle regardless of whether the
    // workspace is empty (notify::focused-workspace misses the empty case).
    const specialName    = createConnection<string | null>(getSpecialName(),    [hyprland, "event", () => getSpecialName()])
    const specialClasses = createConnection<string[]>     (getSpecialClasses(), [hyprland, "event", () => getSpecialClasses()])

    return (
        <overlay
            $={(self: Gtk.Overlay) => {
                const indicator = (
                    <box
                        class="special-ws-indicator"
                        halign={Gtk.Align.FILL}
                        valign={Gtk.Align.FILL}
                        visible={specialName((n) => n !== null)}
                        css={`background: alpha(${accentColor}, 0.85); border: 1px solid alpha(${accentColor}, 0.55);`}
                    >
                        <box halign={Gtk.Align.CENTER} hexpand spacing={4}>
                            <label label={specialName((n) => n ?? "")} />
                            <For each={specialClasses}>
                                {(cls) => <image class="ws-icon" iconName={getIconName(cls)} />}
                            </For>
                        </box>
                    </box>
                ) as Gtk.Widget
                self.add_overlay(indicator)
            }}
        >
            <Workspaces monitor={monitor} />
        </overlay>
    )
}

function CpuLabel({ accentColor }: { accentColor: string }) {
    let prevCpuIdle = 0
    let prevCpuTotal = 0
    const cpu = createPoll("--", 2000, () => {
        const line = readFile("/proc/stat").split("\n")[0]
        const parts = line.split(/\s+/).slice(1).map(Number)
        const idle = parts[3]
        const total = parts.reduce((a, b) => a + b, 0)
        const dIdle = idle - prevCpuIdle
        const dTotal = total - prevCpuTotal
        prevCpuIdle = idle
        prevCpuTotal = total
        if (dTotal === 0) return "--"
        return Math.round(((dTotal - dIdle) / dTotal) * 100).toString()
    })
    return (
        <box class={cpu((v) => parseInt(v) >= 90 ? "metric critical" : "metric")}
             css={`border-color: ${accentColor};`}>
            <label label="󰍛" />
            <label class="metric-value" xalign={1} label={cpu((v) => `${v}%`)} />
        </box>
    )
}

function RamLabel({ accentColor }: { accentColor: string }) {
    const ram = createPoll("--", 2000, ["bash", "-c",
        "free -m | awk '/Mem:/ {printf \"%d\", $3*100/$2}'"])
    return (
        <box class={ram((v) => parseInt(v) >= 90 ? "metric critical" : "metric")}
             css={`border-color: ${accentColor};`}>
            <label label="" />
            <label class="metric-value" xalign={1} label={ram((v) => `${v}%`)} />
        </box>
    )
}

function DiskLabel({ accentColor }: { accentColor: string }) {
    const disk = createPoll("--", 10000, ["bash", "-c",
        "df -h / | awk 'NR==2 {print $5}'"])
    return (
        <box class={disk((v) => parseInt(v) >= 90 ? "metric critical" : "metric")}
             css={`border-color: ${accentColor};`}>
            <label label="󰋊" />
            <label class="metric-value" xalign={1} label={disk((v) => `${v}`)} />
        </box>
    )
}

function getWalColors(): { bg: string, accent: string, fg: string } {
    try {
        const json = JSON.parse(readFile(`${GLib.get_home_dir()}/.cache/wallust/colors.json`))
        return {
            bg: json.special.background ?? "#2a2a2a",
            accent: json.colors.color12 ?? "#6b8f5e",
            fg: json.special.foreground ?? "#e6e6e6",
        }
    } catch { return { bg: "#2a2a2a", accent: "#6b8f5e", fg: "#e6e6e6" } }
}

function BatteryLabel() {
    if (!GLib.file_test("/sys/class/power_supply/BAT0/capacity", GLib.FileTest.EXISTS))
        return <box visible={false} />

    const { bg: bgColor, accent: accentColor, fg: fgColor } = getWalColors()
    const bat = createPoll("--", 5000, () => {
        const cap = readFile("/sys/class/power_supply/BAT0/capacity").trim()
        const status = readFile("/sys/class/power_supply/BAT0/status").trim()
        return JSON.stringify({ percent: parseInt(cap), charging: status === "Charging" })
    })
    return (
        <box
            visible
            class={bat((v) => { try { const d = JSON.parse(v); if (d.charging) return "battery charging"; if (d.percent <= 10) return "battery low"; return "battery" } catch { return "battery" } })}
            css={bat((v) => {
                try {
                    const { percent } = JSON.parse(v)
                    const fill = percent <= 10 ? "#bf616a" : accentColor
                    return `color: ${fgColor}; background: linear-gradient(to right, ${fill} ${percent}%, alpha(${bgColor}, 0.55) ${percent}%); border-color: ${accentColor};`
                } catch { return "" }
            })}
        >
            <label label={bat((v) => {
                try {
                    const d = JSON.parse(v)
                    if (d.charging) return "󰂄"
                    if (d.percent <= 10) return "󰁺"
                    if (d.percent <= 40) return "󰁻"
                    if (d.percent <= 60) return "󰁽"
                    if (d.percent <= 80) return "󰂀"
                    return "󰁹"
                } catch { return "󰂎" }
            })} />
            <label class="metric-value" xalign={1} label={bat((v) => {
                try { return `${JSON.parse(v).percent}%` } catch { return "--%" }
            })} />
        </box>
    )
}

function Clock() {
    const { accent: accentColor } = getWalColors()
    const time = createPoll("--:--", 1000, () =>
        GLib.DateTime.new_now_local()!.format("%Y-%m-%d %H:%M:%S")!
    )
    return <label class="metric" css={`border-color: ${accentColor};`} label={time} />
}

function SysTrayItem({ item }: { item: Tray.TrayItem }) {
    const initMenuButton = (btn: Gtk.MenuButton, item: Tray.TrayItem) => {
        btn.menuModel = item.menuModel
        btn.insert_action_group("dbusmenu", item.actionGroup)
        item.connect("notify::action-group", () => {
            btn.insert_action_group("dbusmenu", item.actionGroup)
        })
    }

    return (
        <menubutton $={(self) => initMenuButton(self, item)}>
            <image gicon={createBinding(item, "gicon")} />
        </menubutton>
    )
}

function SysTray() {
    const { accent: accentColor } = getWalColors()
    const tray = Tray.get_default()
    const items = createBinding(tray, "items")

    return (
        <box class="tray" css={`color: ${accentColor}; border-color: ${accentColor};`}>
            <For each={items}>
                {(item) => <SysTrayItem item={item} />}
            </For>
        </box>
    )
}

function AudioDeviceMenu({ menuWindow }: { menuWindow: { current: Astal.Window | null } }) {
    const wp = Wp.get_default()
    const speakers = createBinding(wp.audio, "speakers")
    const microphones = createBinding(wp.audio, "microphones")
    const defaultSpeaker = createBinding(wp.audio, "defaultSpeaker")
    const defaultMicrophone = createBinding(wp.audio, "defaultMicrophone")

    return (
        <window
            $={(self) => {
                menuWindow.current = self
                const keyCtrl = new Gtk.EventControllerKey()
                keyCtrl.connect("key-pressed", (_ctrl: any, keyval: number) => {
                    if (keyval === Gdk.KEY_Escape) {
                        self.visible = false
                        return true
                    }
                    return false
                })
                self.add_controller(keyCtrl)
            }}
            name="audio-device-menu"
            visible={false}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
            exclusivity={Astal.Exclusivity.NORMAL}
            keymode={Astal.Keymode.ON_DEMAND}
            application={app}
        >
            <box class="audio-menu" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    <label class="audio-menu-header" label="Output Device" halign={Gtk.Align.START} />
                    <For each={speakers}>
                        {(speaker) => (
                            <button
                                class={defaultSpeaker((def) => def?.id === speaker.id ? "audio-device-item active" : "audio-device-item")}
                                onClicked={() => {
                                    wp.audio.defaultSpeaker = speaker
                                    if (menuWindow.current) menuWindow.current.visible = false
                                }}
                            >
                                <box spacing={8}>
                                    <label label={defaultSpeaker((def) => def?.id === speaker.id ? "󰄮" : "󰄯")} />
                                    <label label={speaker.description || speaker.name || "Unknown"} halign={Gtk.Align.START} />
                                </box>
                            </button>
                        )}
                    </For>
                </box>
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    <label class="audio-menu-header" label="Input Device" halign={Gtk.Align.START} />
                    <For each={microphones}>
                        {(mic) => (
                            <button
                                class={defaultMicrophone((def) => def?.id === mic.id ? "audio-device-item active" : "audio-device-item")}
                                onClicked={() => {
                                    wp.audio.defaultMicrophone = mic
                                    if (menuWindow.current) menuWindow.current.visible = false
                                }}
                            >
                                <box spacing={8}>
                                    <label label={defaultMicrophone((def) => def?.id === mic.id ? "󰄮" : "󰄯")} />
                                    <label label={mic.description || mic.name || "Unknown"} halign={Gtk.Align.START} />
                                </box>
                            </button>
                        )}
                    </For>
                </box>
            </box>
        </window>
    )
}

function Volume({ menuWindow }: { menuWindow: { current: Astal.Window | null } }) {
    const { fg: fgColor, accent: accentColor } = getWalColors()
    const wp = Wp.get_default()
    const speaker = wp.audio.get_default_speaker()!
    const volume = createBinding(speaker, "volume")
    const mute = createBinding(speaker, "mute")

    const toggleMenu = () => {
        if (menuWindow.current) {
            menuWindow.current.visible = !menuWindow.current.visible
        }
    }

    return (
        <button
            $={(self) => {
                const rightClick = new Gtk.GestureClick({ button: Gdk.BUTTON_SECONDARY })
                rightClick.connect("released", () => { toggleMenu() })
                self.add_controller(rightClick)

                const scroll = new Gtk.EventControllerScroll({ flags: Gtk.EventControllerScrollFlags.VERTICAL })
                scroll.connect("scroll", (_ctrl: any, _dx: number, dy: number) => {
                    const current = speaker.volume
                    speaker.volume = Math.min(1, Math.max(0, current - dy * 0.05))
                    return true
                })
                self.add_controller(scroll)
            }}
            class={mute((m) => m ? "metric muted" : "metric")}
            css={`color: ${fgColor}; border-color: ${accentColor};`}
            onClicked={() => { speaker.mute = !speaker.mute }}
        >
            <box>
                <label label={mute((m) => m ? "󰝟" : "󰕾")} />
                <label class="metric-value" visible={mute((m) => m)} xalign={1} label="--%" />
                <label class="metric-value" visible={mute((m) => !m)} xalign={1} label={volume((v) =>
                    `${Math.round(v * 100)}%`
                )} />
            </box>
        </button>
    )
}

interface WifiNetwork {
    active: boolean
    ssid: string
    signal: number
    security: string
}

function parseWifiList(raw: string): WifiNetwork[] {
    const seen = new Set<string>()
    const networks: WifiNetwork[] = []
    for (const line of raw.trim().split("\n")) {
        if (!line.trim()) continue
        // nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list
        // fields separated by ":"
        const parts = line.split(":")
        if (parts.length < 4) continue
        const active = parts[0].trim() === "*"
        const ssid = parts[1].trim()
        const signal = parseInt(parts[2].trim()) || 0
        const security = parts.slice(3).join(":").trim()
        if (!ssid || ssid === "--") continue
        if (seen.has(ssid)) continue
        seen.add(ssid)
        networks.push({ active, ssid, signal, security })
    }
    // active network first, then by signal strength
    return networks.sort((a, b) => {
        if (a.active !== b.active) return a.active ? -1 : 1
        return b.signal - a.signal
    })
}

function signalIcon(signal: number): string {
    if (signal >= 80) return "󰤨"
    if (signal >= 60) return "󰤥"
    if (signal >= 40) return "󰤢"
    if (signal >= 20) return "󰤟"
    return "󰤯"
}

function WifiMenu({ menuWindow }: { menuWindow: { current: Astal.Window | null } }) {
    // Poll the network list every 10 s; we also trigger a manual refresh
    let forceRefresh = 0
    // GLib.spawn_command_line_sync blocks the GTK main loop until nmcli returns
    // (can take seconds), freezing the whole bar. execAsync runs it off-thread.
    const networksRaw = createPoll("", 10000, () => {
        void forceRefresh  // read so the closure captures the var (unused warning suppressed)
        return execAsync("nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list").catch(() => "")
    })

    const networks = networksRaw((raw) => parseWifiList(raw))

    const rescan = () => {
        execAsync(["nmcli", "device", "wifi", "rescan"]).catch(() => {})
        // Give the scan ~2 s then force a list refresh
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
            forceRefresh++
            return false  // don't repeat
        })
    }

    return (
        <window
            $={(self) => {
                menuWindow.current = self
                const keyCtrl = new Gtk.EventControllerKey()
                keyCtrl.connect("key-pressed", (_ctrl: any, keyval: number) => {
                    if (keyval === Gdk.KEY_Escape) {
                        self.visible = false
                        return true
                    }
                    return false
                })
                self.add_controller(keyCtrl)
                const focusCtrl = new Gtk.EventControllerFocus()
                focusCtrl.connect("leave", () => { self.visible = false })
                self.add_controller(focusCtrl)
            }}
            name="wifi-menu"
            visible={false}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
            exclusivity={Astal.Exclusivity.NORMAL}
            keymode={Astal.Keymode.ON_DEMAND}
            application={app}
        >
            <box class="wifi-menu" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                <For each={networks}>
                    {(net) => (
                        <button
                            class={net.active ? "wifi-network-item active" : "wifi-network-item"}
                            onClicked={() => {
                                if (!net.active) {
                                    execAsync(["nmcli", "device", "wifi", "connect", net.ssid]).catch(() => {})
                                }
                                if (menuWindow.current) menuWindow.current.visible = false
                            }}
                        >
                            <box spacing={6}>
                                <label label={signalIcon(net.signal)} />
                                <label label={net.ssid} halign={Gtk.Align.START} hexpand />
                                <label label={net.security || "Open"} css="color: #888;" />
                            </box>
                        </button>
                    )}
                </For>
                <button class="metric" onClicked={rescan} tooltipText="Rescan networks" halign={Gtk.Align.FILL}>
                    <box spacing={6} halign={Gtk.Align.CENTER}>
                        <label label="󰑐" />
                        <label label="Rescan" />
                    </box>
                </button>
            </box>
        </window>
    )
}

function Wifi({ menuWindow }: { menuWindow: { current: Astal.Window | null } }) {
    const { fg: fgColor, accent: accentColor } = getWalColors()

    // Returns "wired:<ip>" when ethernet is active, "wifi:<signal>:<ssid>" otherwise
    const netInfo = createPoll("wifi:0:--", 5000, ["bash", "-c",
        "d=$(nmcli -t -f device,type,state dev 2>/dev/null | grep ':ethernet:connected' | cut -d: -f1 | head -1); if [ -n \"$d\" ]; then ip=$(ip -4 addr show \"$d\" 2>/dev/null | grep -oP '(?<=inet )[^/]+' | head -1); echo \"wired:$ip\"; else sig=$(nmcli -t -f active,signal dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 | head -1); ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2- | head -1); echo \"wifi:${sig:-0}:$ssid\"; fi"
    ])

    const parseInfo = (raw: string) => {
        if (raw.startsWith("wired:")) {
            return { wired: true, ip: raw.slice(6) || "--", signal: 0, ssid: "" }
        }
        const first = raw.indexOf(":")
        const second = raw.indexOf(":", first + 1)
        const signal = parseInt(raw.slice(first + 1, second)) || 0
        const ssid = raw.slice(second + 1) || "--"
        return { wired: false, ip: "", signal, ssid }
    }

    const toggleMenu = () => {
        if (menuWindow.current) menuWindow.current.visible = !menuWindow.current.visible
    }

    return (
        <button class="metric" css={`color: ${fgColor}; border-color: ${accentColor};`} onClicked={toggleMenu}
            tooltipText={netInfo((raw) => parseInfo(raw).wired ? "Wired connection" : "Click to manage Wi-Fi")}>
            <box spacing={4}>
                <label label={netInfo((raw) => {
                    const { wired, signal } = parseInfo(raw)
                    return wired ? "󰈀" : signalIcon(signal)
                })} />
                <label css="margin-left: 4px;" label={netInfo((raw) => {
                    const { wired, ip, ssid } = parseInfo(raw)
                    return wired ? ip : ssid
                })} />
            </box>
        </button>
    )
}

// Shared reference for the audio device menu window
export const audioMenuWindow = { current: null as Astal.Window | null }

export const wifiMenuWindow = { current: null as Astal.Window | null }

export function BatteryWarningPopup() {
    if (!GLib.file_test("/sys/class/power_supply/BAT0/capacity", GLib.FileTest.EXISTS))
        return <box visible={false} />

    let win: Astal.Window
    let dismissed = false
    let prevPercent = 100
    let prevCharging = false

    const check = () => {
        const cap = parseInt(readFile("/sys/class/power_supply/BAT0/capacity").trim())
        const charging = readFile("/sys/class/power_supply/BAT0/status").trim() === "Charging"

        if ((charging && !prevCharging) || (cap > 15 && prevPercent <= 15))
            dismissed = false
        prevPercent = cap
        prevCharging = charging

        if (!win) return
        if (cap <= 10 && !charging && !dismissed)
            win.visible = true
        else if (charging || cap > 15)
            win.visible = false
    }

    return (
        <window
            $={(self) => {
                win = self
                check()
                GLib.timeout_add(GLib.PRIORITY_DEFAULT, 30000, () => { check(); return true })
            }}
            name="battery-warning"
            visible={false}
            anchor={Astal.WindowAnchor.TOP}
            exclusivity={Astal.Exclusivity.NORMAL}
            keymode={Astal.Keymode.NONE}
            application={app}
        >
            <box class="battery-warning" orientation={Gtk.Orientation.VERTICAL} spacing={12}>
                <box spacing={10} halign={Gtk.Align.CENTER}>
                    <label class="battery-warning-icon" label="󰁺" />
                    <label class="battery-warning-title" label="Battery Low" />
                </box>
                <label label="Please plug in your laptop" halign={Gtk.Align.CENTER} />
                <button
                    class="battery-warning-dismiss"
                    onClicked={() => { dismissed = true; win.visible = false }}
                    halign={Gtk.Align.FILL}
                >
                    <label label="Dismiss" halign={Gtk.Align.CENTER} />
                </button>
            </box>
        </window>
    )
}

export { AudioDeviceMenu, WifiMenu }

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
    let win: Astal.Window
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
    const { accent: accentColor } = getWalColors()

    onCleanup(() => {
        win.destroy()
    })

    return (
        <window
            $={(self) => (win = self)}
            visible
            name={`bar-${gdkmonitor.connector}`}
            gdkmonitor={gdkmonitor}
            exclusivity={Astal.Exclusivity.EXCLUSIVE}
            anchor={TOP | LEFT | RIGHT}
            application={app}
        >
            <centerbox>
                <box $type="start" css="background: transparent; border-radius: 10px; padding: 2px;" spacing={4} halign={Gtk.Align.START}>
                    <CpuLabel accentColor={accentColor} />
                    <RamLabel accentColor={accentColor} />
                    <DiskLabel accentColor={accentColor} />
                    <BatteryLabel />
                </box>
                <box $type="center">
                    <WorkspacesWithSpecialOverlay monitor={gdkmonitor.connector!} />
                </box>
                <box $type="end" class="group" spacing={4}>
                    <SysTray />
                    <Wifi menuWindow={wifiMenuWindow} />
                    <Volume menuWindow={audioMenuWindow} />
                    <Clock />
                </box>
            </centerbox>
        </window>
    )
}
