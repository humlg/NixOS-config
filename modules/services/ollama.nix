{ config, lib, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    openFirewall = true;
  };

  environment.systemPackages = [
    pkgs.oterm
    (pkgs.makeDesktopItem {
      name = "oterm";
      desktopName = "oterm";
      comment = "Terminal UI for Ollama";
      exec = "kitty -e oterm";
      icon = "utilities-terminal";
      categories = [ "Utility" ];
    })
  ];
}
