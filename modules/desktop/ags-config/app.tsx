import { createBinding, For } from "ags"
import app from "ags/gtk4/app"
import style from "./style.css"
import Bar from "./Bar"

app.start({
    css: style,
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
