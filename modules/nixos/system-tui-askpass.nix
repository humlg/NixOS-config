# Whiptail-based initrd disk-unlock prompt (shows keystroke feedback, unlike
# the stock prompt). Protocol + Plymouth mutual-exclusion: docs/architecture.md.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.tuiAskpass;
  replyPassword = "${config.boot.initrd.systemd.package}/lib/systemd/systemd-reply-password";
in
{
  options.custom.tuiAskpass = {
    enable = lib.mkEnableOption ''
      a whiptail-based password prompt for initrd disk unlocks, replacing
      systemd's plain-text ask-password console prompt. Toggle the debug
      key-echo view per-boot (no rebuild) by adding tuiaskpass.debug=1 to
      the kernel command line at the bootloader menu — it switches the
      passwordbox to a plain visible inputbox so you can see exactly what's
      being typed, e.g. to catch a stuck key. Falls back automatically if
      Plymouth is running (checks /run/plymouth/pid), and the stock
      systemd-tty-ask-password-agent binary is still present in the initrd
      as a manual escape hatch (systemd-tty-ask-password-agent --query) if
      this agent ever fails to start.
    '';
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.systemd = {
      # Must suppress both — the .path unit triggers the .service.
      suppressedUnits = [
        "systemd-ask-password-console.path"
        "systemd-ask-password-console.service"
      ];

      storePaths = [ replyPassword ];

      paths.tui-askpass = {
        description = "Watch for pending disk-unlock password requests (TUI agent)";
        wantedBy = [ "sysinit.target" ];
        unitConfig = {
          DefaultDependencies = false;
          ConditionPathExists = "!/run/plymouth/pid";
          Conflicts = [ "emergency.service" "shutdown.target" ];
          Before = [
            "paths.target"
            "cryptsetup.target"
            "emergency.service"
            "shutdown.target"
          ];
        };
        pathConfig = {
          DirectoryNotEmpty = "/run/systemd/ask-password";
          MakeDirectory = true;
        };
      };

      services.tui-askpass = {
        description = "TUI disk-unlock password agent (whiptail)";
        # `path` sets PATH outright, no fallback to the initrd's /bin.
        path = [ pkgs.newt pkgs.coreutils pkgs.gnused ];
        unitConfig = {
          DefaultDependencies = false;
          ConditionPathExists = "!/run/plymouth/pid";
          After = [ "systemd-vconsole-setup.service" ];
          Conflicts = [
            "emergency.service"
            "shutdown.target"
            "initrd-switch-root.target"
          ];
          Before = [
            "emergency.service"
            "shutdown.target"
            "initrd-switch-root.target"
          ];
        };
        serviceConfig = {
          Type = "simple";
          Environment = "TERM=linux";
          StandardInput = "tty";
          StandardOutput = "tty";
          StandardError = "tty";
          TTYPath = "/dev/console";
          TTYReset = true;
          TTYVHangup = true;
          KillMode = "process";
          IgnoreSIGPIPE = false;
          # Never leave the machine with no way to answer a pending
          # password request just because whiptail hiccuped once.
          Restart = "on-failure";
          RestartSec = 1;
        };
        # Polls — the initrd has no inotify-tools.
        script = ''
          set -eu

          debug=0
          for arg in $(cat /proc/cmdline); do
            [ "$arg" = "tuiaskpass.debug=1" ] && debug=1
          done

          handled=""
          while true; do
            for f in /run/systemd/ask-password/ask.*; do
              [ -e "$f" ] || continue
              case " $handled " in
                *" $f "*) continue ;;
              esac
              handled="$handled $f"

              message=$(sed -n 's/^Message=//p' "$f")
              socket=$(sed -n 's/^Socket=//p' "$f")
              [ -n "$socket" ] || continue
              [ -e "$socket" ] || continue

              if [ "$debug" = "1" ]; then
                answer=$(whiptail --title "Disk unlock (DEBUG: keys visible)" \
                  --inputbox "''${message:-Enter passphrase:}" 12 70 \
                  3>&1 1>&2 2>&3) && ok=1 || ok=0
              else
                answer=$(whiptail --title "Disk unlock" \
                  --passwordbox "''${message:-Enter passphrase:}" 12 70 \
                  3>&1 1>&2 2>&3) && ok=1 || ok=0
              fi

              if [ "$ok" = "1" ]; then
                printf '%s\n' "$answer" | ${replyPassword} 1 "$socket"
              else
                ${replyPassword} 0 "$socket"
              fi
              unset answer
            done
            sleep 0.3
          done
        '';
      };
    };
  };
}
