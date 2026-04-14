import { createBinding, For, onCleanup } from "ags"
import { createPoll } from "ags/time"
import { readFile } from "ags/file"
import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import GLib from "gi://GLib"
import Hyprland from "gi://AstalHyprland"
import Tray from "gi://AstalTray"

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
    const workspaces = createBinding(hyprland, "workspaces")
    const focused = createBinding(hyprland, "focusedWorkspace")
    const clients = createBinding(hyprland, "clients")

    return (
        <box class="workspaces">
            <For each={workspaces((ws) => ws.filter((w) => w.get_id() > 0).sort((a, b) => a.get_id() - b.get_id()))}>
                {(ws) => {
                    const onOtherMonitor = ws.get_monitor()?.get_name() !== monitor
                    const wsClasses = clients((cls) =>
                        [...new Set(
                            cls.filter((c) => c.get_workspace()?.get_id() === ws.get_id())
                               .map((c) => c.get_class())
                        )]
                    )
                    return (
                        <button
                            class={focused((fw) => {
                                if (fw?.get_id() === ws.get_id()) return "focused"
                                if (onOtherMonitor) return "other-monitor"
                                return ""
                            })}
                            onClicked={() => ws.focus()}
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

let prevCpuIdle = 0
let prevCpuTotal = 0

function readCpuUsage(): string {
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
}

function CpuLabel() {
    const cpu = createPoll("--", 2000, () => readCpuUsage())
    return (
        <box class={cpu((v) => parseInt(v) >= 90 ? "metric critical" : "metric")}>
            <label label="󰍛" />
            <label class="metric-value" xalign={1} label={cpu((v) => `${v}%`)} />
        </box>
    )
}

function RamLabel() {
    const ram = createPoll("--", 2000, ["bash", "-c",
        "free -m | awk '/Mem:/ {printf \"%d\", $3*100/$2}'"])
    return (
        <box class={ram((v) => parseInt(v) >= 90 ? "metric critical" : "metric")}>
            <label label="" />
            <label class="metric-value" xalign={1} label={ram((v) => `${v}%`)} />
        </box>
    )
}

function DiskLabel() {
    const disk = createPoll("--", 10000, ["bash", "-c",
        "df -h / | awk 'NR==2 {print $5}'"])
    return (
        <box class={disk((v) => parseInt(v) >= 90 ? "metric critical" : "metric")}>
            <label label="󰋊" />
            <label class="metric-value" xalign={1} label={disk((v) => `${v}`)} />
        </box>
    )
}

function getWalColors(): { bg: string, accent: string } {
    try {
        const json = JSON.parse(readFile(`${GLib.get_home_dir()}/.cache/wal/colors.json`))
        return {
            bg: json.colors.color8 ?? "#2a2a2a",
            accent: json.colors.color2 ?? "#6b8f5e",
        }
    } catch { return { bg: "#2a2a2a", accent: "#6b8f5e" } }
}

function BatteryLabel() {
    const { bg: bgColor, accent: accentColor } = getWalColors()
    const bat = createPoll("--", 5000, () => {
        const cap = readFile("/sys/class/power_supply/BAT0/capacity").trim()
        const status = readFile("/sys/class/power_supply/BAT0/status").trim()
        return JSON.stringify({ percent: parseInt(cap), charging: status === "Charging" })
    })
    return (
        <box
            visible
            class={bat((v) => { try { return JSON.parse(v).charging ? "battery charging" : "battery" } catch { return "battery" } })}
            css={bat((v) => {
                try {
                    const { percent } = JSON.parse(v)
                    const fill = percent <= 20 ? "#bf616a" : accentColor
                    return `background: linear-gradient(to right, ${fill} ${percent}%, alpha(${bgColor}, 0.6) ${percent}%);`
                } catch { return "" }
            })}
        >
            <label label={bat((v) => {
                try {
                    const d = JSON.parse(v)
                    if (d.charging) return "󰂄"
                    if (d.percent <= 20) return "󰁺"
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
    const time = createPoll("--:--", 1000, () =>
        GLib.DateTime.new_now_local()!.format("%Y-%m-%d %H:%M:%S")!
    )
    return <label class="metric" label={time} />
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
    const tray = Tray.get_default()
    const items = createBinding(tray, "items")

    return (
        <box class="tray">
            <For each={items}>
                {(item) => <SysTrayItem item={item} />}
            </For>
        </box>
    )
}

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
    let win: Astal.Window
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

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
                <box $type="start" css="background: rgba(30,30,30,0.3); border-radius: 10px; padding: 2px;" spacing={4} halign={Gtk.Align.START}>
                    <CpuLabel />
                    <RamLabel />
                    <DiskLabel />
                    <BatteryLabel />
                </box>
                <box $type="center">
                    <Workspaces monitor={gdkmonitor.connector!} />
                </box>
                <box $type="end" class="group" spacing={4}>
                    <SysTray />
                    <Clock />
                </box>
            </centerbox>
        </window>
    )
}
