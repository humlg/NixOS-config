{ config, lib, pkgs, ... }:

{
  services.displayManager.sddm  = {
    package = pkgs.kdePackages.sddm;
    extraPackages = with pkgs; [
      sddm-astronaut
      kdePackages.qt5compat

      kdePackages.qtmultimedia
      kdePackages.qtdeclarative
      kdePackages.qtsvg
    ];
    enable = true;
    wayland.enable = true;
    autoNumlock = true;
    theme = "sddm-astronaut-theme";
    enableHidpi = true;
    settings = {
      General = {
        DisplayServer = "wayland";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    sddm-astronaut
  ];
}