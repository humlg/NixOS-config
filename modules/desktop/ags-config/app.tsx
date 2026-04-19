import { createBinding, For } from "ags"
import { readFile } from "ags/file"
import app from "ags/gtk4/app"
import style from "./style.css"
import Bar from "./Bar"

function loadWalColors(): string {
    try {
        const json = JSON.parse(readFile(`${GLib.get_home_dir()}/.cache/wallust/colors.json`))
        const bg = json.special.background
        const fg = json.special.foreground
        const c = json.colors
        return `
            window > box { color: ${fg}; }
            .workspaces button { color: ${c.color7}; background: alpha(${bg}, 0.55); }
            .workspaces button.focused { background: ${c.color12}; color: ${fg}; }
            .metric { background: alpha(${bg}, 0.55); }
            .metric.charging { color: ${c.color2}; }
            .tray { background: alpha(${bg}, 0.55); }
        `
    } catch {
        return ""
    }
}

import GLib from "gi://GLib"

app.start({
    css: style + loadWalColors(),
    instanceName: "bar",
    main() {
        const monitors = createBinding(app, "monitors")
        return (
            <For each={monitors}>
                {(monitor) => <Bar gdkmonitor={monitor} />}
            </For>
        )
    },
})
