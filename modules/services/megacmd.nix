{ config, lib, pkgs, ... }:

let
  cfg = config.services.megacmd;

  # Build the sync-setup script from declared sync pairs
  syncScript = pkgs.writeShellScript "mega-sync-setup" ''
    # Exit gracefully if not logged in
    if ! ${pkgs.megacmd}/bin/mega-whoami &>/dev/null; then
      echo "MEGAcmd: not logged in — skipping sync setup"
      exit 0
    fi

    # Use pipe-separated output so paths are never truncated
    existing=$(${pkgs.megacmd}/bin/mega-sync --col-separator="|" 2>/dev/null | awk -F'|' '{print $2}' || true)

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (local: remote: ''
      if echo "$existing" | grep -qF "${local}"; then
        echo "MEGAcmd: sync already exists for ${local} — skipping"
      else
        echo "MEGAcmd: adding sync ${local} -> ${remote}"
        ${pkgs.megacmd}/bin/mega-sync "${local}" "${remote}"
      fi
    '') cfg.syncs)}
  '';

in
{
  options.services.megacmd = {
    enable = lib.mkEnableOption "MEGAcmd cloud sync daemon";

    syncs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "/home/david/Documents" = "/Documents";
        "/home/david/Pictures" = "/Pictures";
      };
      description = "Mapping of local paths to MEGA remote paths to sync.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.megacmd
    ];

    # Long-running MEGAcmd server daemon
    systemd.user.services.mega-cmd-server = {
      Unit = {
        Description = "MEGAcmd server daemon";
        After = [ "default.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.megacmd}/bin/mega-cmd-server";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };

    # Oneshot service to configure declared sync pairs
    systemd.user.services.mega-sync-setup = {
      Unit = {
        Description = "Configure MEGAcmd sync pairs";
        # After-only (no Requires) so this doesn't restart when mega-cmd-server restarts;
        # MEGAcmd persists sync state itself, so we only need to run this once at boot.
        After = [ "mega-cmd-server.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
        ExecStart = "${syncScript}";
        RemainAfterExit = true;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
