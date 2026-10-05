{ config, lib, pkgs, ... }:

let
  cfg = config.custom.lid-undock-hibernate;

  stateFile = "/run/lid-undock-hibernate.external";

  script = pkgs.writeShellScript "lid-undock-hibernate" ''
    set -eu
    export PATH=${lib.makeBinPath [ config.systemd.package pkgs.coreutils ]}

    # --record-only snapshots state without acting (used by the boot-time init unit).
    record_only=0
    [ "''${1-}" = "--record-only" ] && record_only=1

    # Let a DP hotplug renegotiation settle before sampling (docs/architecture.md).
    [ "$record_only" = "1" ] || sleep ${toString cfg.settleSeconds}

    external=0
    for s in /sys/class/drm/card*-*/status; do
      [ -e "$s" ] || continue
      connector=''${s%/status}
      connector=''${connector##*/}   # card1-DP-1
      connector=''${connector#*-}    # DP-1
      case "$connector" in
        ${cfg.internalConnector}|Writeback-*) continue ;;
      esac
      [ "$(cat "$s")" = "connected" ] && external=1
    done

    previous=$(cat ${stateFile} 2>/dev/null || echo 0)
    echo "$external" > ${stateFile}

    [ "$record_only" = "1" ] && exit 0

    # Only act on a real 1->0 edge (prevents a hibernate loop on resume).
    [ "$external" = "0" ] || exit 0
    [ "$previous" = "1" ] || exit 0

    lid=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{ print $2; exit }' || true)
    [ "$lid" = "closed" ] || exit 0

    # Deliberately ignores the swaync sleep-inhibit flag — see docs/architecture.md.
    echo "external display disconnected while lid closed — sleeping"
    exec ${cfg.sleepCommand}
  '';
in
{
  options.custom.lid-undock-hibernate = {
    enable = lib.mkEnableOption ''
      sleeping when the last external display is unplugged while the lid is
      already shut (hibernating by default — see sleepCommand). Complements
      HandleLidSwitchDocked = "ignore": closing the lid while docked keeps the
      machine running on the external monitor, but pulling the monitor
      afterwards (i.e. packing the laptop away) no longer leaves it awake and
      cooking in a bag
    '';

    internalConnector = lib.mkOption {
      type    = lib.types.str;
      default = "eDP-1";
      description = "DRM connector name of the built-in panel, excluded from the external-display count.";
    };

    settleSeconds = lib.mkOption {
      type    = lib.types.int;
      default = 5;
      description = ''
        Seconds to wait after a DRM hotplug before sampling connector state,
        so a mid-renegotiation blip does not read as a disconnect.
      '';
    };

    sleepCommand = lib.mkOption {
      type    = lib.types.str;
      default = "systemctl --no-block hibernate";
      example = "systemctl --no-block suspend-then-hibernate";
      description = ''
        Command run once the last external display goes away with the lid shut.
        Defaults to hibernate because that is safe on any host: it survives a
        flat battery and needs no working suspend path. Hosts whose s2idle is
        trustworthy should point this at suspend-then-hibernate instead, so a
        quick undock-and-walk resumes instantly.

        Must return promptly — it runs from a oneshot unit started by a udev
        rule, hence --no-block in the default.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card[0-9]*", RUN+="${config.systemd.package}/bin/systemctl --no-block start lid-undock-hibernate.service"
    '';

    systemd.services.lid-undock-hibernate = {
      description = "Hibernate when the last external display is unplugged with the lid shut";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${script}";
      };
    };

    # Snapshots state at boot so the first unplug after boot registers as an edge.
    systemd.services.lid-undock-hibernate-init = {
      description = "Record initial external-display state for lid-undock-hibernate";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${script} --record-only";
      };
    };
  };
}
