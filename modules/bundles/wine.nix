{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.wine;
in
{
  options.bundles.wine = {
    enable = lib.mkEnableOption "Windows app support via Bottles";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bottles
      wine64Packages.stable
    ];
  };
}
