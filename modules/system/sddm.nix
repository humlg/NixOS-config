{ config, lib, pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.displayManager.sddm.theme = "sugar-dark";
  themePackages = [ pkgs.sddm-sugar-dark ];
}