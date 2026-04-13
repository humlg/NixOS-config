{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Use AGS v1 (the old version with GJS API)
      # The new AGS v2 uses a different TypeScript-based API
      (ags.overrideAttrs (old: {
        version = "1.8.2";
        src = pkgs.fetchFromGitHub {
          owner = "Aylur";
          repo = "ags";
          rev = "v1.8.2";
          hash = "sha256-3GwwVQyLF2LDwIFJKzF+W+HQFmuVYZCVCGYzUQNnRBw=";
        };
      }))
      libdbusmenu-gtk3
    ];

    xdg.configFile."ags/config.js".text = ''
      import App from 'resource:///com/github/Aylur/ags/app.js';
      import Widget from 'resource:///com/github/Aylur/ags/widget.js';
      import Utils from 'resource:///com/github/Aylur/ags/utils.js';
      import Service from 'resource:///com/github/Aylur/ags/service.js';

      const hyprland = await Service.import('hyprland');
      const systemtray = await Service.import('systemtray');
      const battery = await Service.import('battery');

      const dispatch = ws => hyprland.messageAsync(`dispatch workspace ''${ws}`);

      const Workspaces = () => Widget.EventBox({
          onScrollUp: () => dispatch('+1'),
          onScrollDown: () => dispatch('-1'),
          child: Widget.Box({
              class_name: 'workspaces',
              children: Array.from({ length: 10 }, (_, i) => i + 1).map(i => Widget.Button({
                  attribute: i,
                  label: `''${i}`,
                  onClicked: () => dispatch(i),
                  class_name: hyprland.active.workspace.bind('id').as(id => id === i ? 'focused' : ""),
              })),
              setup: self => self.hook(hyprland, () => self.children.forEach(btn => {
                  const exists = hyprland.workspaces.some(ws => ws.id === btn.attribute);
                  btn.visible = exists;
                  btn.toggleClassName('occupied', exists);
              })),
          }),
      });

      const CpuLabel = () => Widget.Label({ class_name: 'metric', label: 'CPU --%' })
          .poll(2000, self => {
              const usage = Utils.exec('bash -c "read cpu u n s i w x y z < /proc/stat; sleep 0.1; read cpu u2 n2 s2 i2 w2 x2 y2 z2 < /proc/stat; t=$((u2+n2+s2+i2+w2+x2+y2+z2)); p=$((u+n+s+i+w+x+y+z)); d=$((t-p)); id=$((i2-i)); echo $(( (100*(d-id))/d ))"');
              self.label = `CPU ''${usage}%`;
          });

      const RamLabel = () => Widget.Label({ class_name: 'metric', label: 'RAM --%' })
          .poll(2000, self => {
              const used = Utils.exec('bash -c "free -m | awk \'/Mem:/ {printf \\\"%d\\\", $3*100/$2}\'"');
              self.label = `RAM ''${used}%`;
          });

      const DiskLabel = () => Widget.Label({ class_name: 'metric', label: 'DISK --%' })
          .poll(10000, self => {
              const used = Utils.exec('bash -c "df -h / | awk \'NR==2 {print $5}\'"');
              self.label = `DISK ''${used}`;
          });

      const BatteryLabel = () => Widget.Label({
          class_name: battery.bind('charging').as(ch => ch ? 'metric charging' : 'metric'),
          visible: battery.bind('available'),
          label: battery.bind('percent').as(p => `BAT ''${p}%`),
      });

      const Clock = () => Widget.Label({ class_name: 'metric', label: '--:--' })
          .poll(1000, self => {
              self.label = Utils.exec('date "+%Y-%m-%d %H:%M:%S"');
          });

      const SysTrayItem = item => Widget.Button({
          child: Widget.Icon().bind('icon', item, 'icon'),
          tooltipMarkup: item.bind('tooltip_markup'),
          onPrimaryClick: (_, event) => item.activate(event),
          onSecondaryClick: (_, event) => item.openMenu(event),
      });

      const SysTray = () => Widget.Box({
          class_name: 'tray',
          children: systemtray.bind('items').as(items => items.map(SysTrayItem)),
      });

      const Right = () => Widget.Box({
          class_name: 'right',
          spacing: 8,
          children: [
              CpuLabel(),
              RamLabel(),
              DiskLabel(),
              BatteryLabel(),
              SysTray(),
              Clock(),
          ],
      });

      const Bar = (monitor = 0) => Widget.Window({
          name: `bar-''${monitor}`,
          class_name: 'bar',
          monitor,
          anchor: ['top', 'left', 'right'],
          exclusivity: 'exclusive',
          layer: 'top',
          child: Widget.CenterBox({
              startWidget: Widget.Box({}),
              centerWidget: Workspaces(),
              endWidget: Right(),
          }),
      });

      App.config({
          style: `''${App.configDir}/style.css`,
          windows: [Bar(0)],
      });
    '';

    xdg.configFile."ags/style.css".text = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 12px;
      }

      .bar {
        background: rgba(20, 20, 20, 0.85);
        color: #e6e6e6;
        padding: 6px 10px;
      }

      .workspaces button {
        background: transparent;
        border-radius: 10px;
        padding: 2px 6px;
        margin: 0 2px;
        color: #c0c0c0;
      }

      .workspaces button.focused {
        background: #5e81ac;
        color: #ffffff;
      }

      .workspaces button.occupied {
        color: #d8dee9;
      }

      .metric {
        background: #2a2a2a;
        border-radius: 10px;
        padding: 2px 8px;
      }

      .metric.charging {
        color: #a3be8c;
      }

      .tray {
        background: #2a2a2a;
        border-radius: 10px;
        padding: 2px 6px;
      }
    '';
  };
}
