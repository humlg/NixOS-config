# Replaces the stock initrd disk-unlock prompt (a single unmasked line with
# zero feedback while typing) with a whiptail box that shows dots per
# keystroke, so a dead/sticking key is visible instead of silently vanishing
# into "wrong passphrase, try again". Requires boot.initrd.systemd.enable
# (systemd stage-1 initrd) — this hooks into systemd's password-agent
# protocol (see https://systemd.io/PASSWORD_AGENTS/), the same mechanism
# Plymouth itself uses to grab password prompts, so Plymouth and this module
# are mutually exclusive by design (see the ConditionPathExists guards
# below) — enabling this only makes sense with Plymouth off, since the point
# is to see full boot output with no splash covering it.
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
      # Must suppress both: the .path unit is what actually triggers the
      # .service, so disabling only the .service leaves the trigger armed.
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
        path = [ pkgs.newt ];
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
        # Polls instead of using inotify: the initrd has no inotify-tools,
        # and a 0.3s poll is invisible next to how long it takes a human to
        # read a prompt and type a passphrase.
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
