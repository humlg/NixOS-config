{ config, lib, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    openFirewall = true;
  };

  environment.systemPackages = [ pkgs.oterm ];
}
