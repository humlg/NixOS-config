{ config, lib, pkgs, ... }:

let
  cfg = config.custom.moonlight;
in
{
  options.custom.moonlight.enable = lib.mkEnableOption "Moonlight streaming client (connect to other machines running Sunshine)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      moonlight-qt
    ];
  };
}
