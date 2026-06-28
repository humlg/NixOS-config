{ config, lib, pkgs, ... }:

let
  cfg = config.custom.sunshine-moonlight;
in
{
  options.custom.sunshine-moonlight = {
    enable = lib.mkEnableOption "Sunshine game streaming server + Moonlight client";
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      openFirewall = true;
      # CAP_SYS_ADMIN is required for KMS display capture (reads /dev/dri directly,
      # works without an active compositor session — necessary for unattended access).
      capSysAdmin = true;
      settings = {
        sunshine_name = config.networking.hostName;
      };
    };

    # KMS capture accesses /dev/dri/* devices
    users.users.david.extraGroups = [ "video" "render" ];

    environment.systemPackages = with pkgs; [
      moonlight-qt
    ];
  };
}
