import { createBinding, For, onCleanup } from "ags"
import { createPoll } from "ags/time"
import { readFile } from "ags/file"
import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import GLib from "gi://GLib"
import Hyprland from "gi://AstalHyprland"
import Battery from "gi://AstalBattery"
import Tray from "gi://AstalTray"

function Workspaces() {
    const hyprland = Hyprland.get_default()
    const workspaces = createBinding(hyprland, "workspaces")
    const focused = createBinding(hyprland, "focusedWorkspace")

    return (
        <box class="workspaces">
            <For each={workspaces((ws) => ws.filter((w) => w.get_id() > 0).sort((a, b) => a.get_id() - b.get_id()))}>
                {(ws) => (
                    <button
                        class={focused((fw) => fw?.get_id() === ws.get_id() ? "focused" : "")}
                        onClicked={() => ws.focus()}
                    >
                        <label label={ws.get_id().toString()} />
                    </button>
                )}
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
    return <label
        class={cpu((v) => parseInt(v) >= 90 ? "metric critical" : "metric")}
        label={cpu((v) => `CPU ${v}%`)}
    />
}

function RamLabel() {
    const ram = createPoll("--", 2000, ["bash", "-c",
        "free -m | awk '/Mem:/ {printf \"%d\", $3*100/$2}'"])
    return <label
        class={ram((v) => parseInt(v) >= 90 ? "metric critical" : "metric")}
        label={ram((v) => `RAM ${v}%`)}
    />
}

function DiskLabel() {
    const disk = createPoll("--", 10000, ["bash", "-c",
        "df -h / | awk 'NR==2 {print $5}'"])
    return <label
        class={disk((v) => parseInt(v) >= 90 ? "metric critical" : "metric")}
        label={disk((v) => `DISK ${v}`)}
    />
}

function BatteryLabel() {
    const battery = Battery.get_default()
    const percent = createBinding(battery, "percentage")
    const charging = createBinding(battery, "charging")

    return (
        <label
            visible
            class={charging((ch) => ch ? "metric charging" : "metric")}
            label={percent((p) => `BAT ${Math.floor(p <= 1 ? p * 100 : p)}%`)}
        />
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
                <box $type="start" spacing={8}>
                    <CpuLabel />
                    <RamLabel />
                    <DiskLabel />
                    <BatteryLabel />
                </box>
                <box $type="center">
                    <Workspaces />
                </box>
                <box $type="end" spacing={8}>
                    <SysTray />
                    <Clock />
                </box>
            </centerbox>
        </window>
    )
}
