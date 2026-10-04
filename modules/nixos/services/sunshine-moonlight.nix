{ config, lib, pkgs, ... }:

let
  cfg = config.custom.sunshine-moonlight;
in
{
  options.custom.sunshine-moonlight = {
    enable = lib.mkEnableOption "Sunshine game streaming server (host side — lets other machines stream from this one)";
    enableMoonlight = lib.mkEnableOption "Moonlight streaming client (connect to other machines running Sunshine)";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether the Sunshine systemd user service starts automatically with the graphical session. Set false to install it but only start it on demand (`systemctl --user start sunshine`).";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.sunshine = {
        enable = true;
        openFirewall = true;
        # CAP_SYS_ADMIN is required for KMS display capture (reads /dev/dri directly,
        # works without an active compositor session — necessary for unattended access).
        capSysAdmin = true;
        autoStart = cfg.autoStart;
        settings = {
          sunshine_name = config.networking.hostName;
        };
      };

      # KMS capture accesses /dev/dri/* devices
      users.users.david.extraGroups = [ "video" "render" ];
    })

    (lib.mkIf cfg.enableMoonlight {
      environment.systemPackages = with pkgs; [
        moonlight-qt
      ];
    })
  ];
}
