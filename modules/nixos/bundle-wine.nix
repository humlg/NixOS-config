{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.wine;
in
{
  options.bundles.wine = {
    enable = lib.mkEnableOption "Windows app support via Bottles";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable32Bit = true;

    environment.systemPackages = with pkgs; [
      bottles
    ];
  };
}
