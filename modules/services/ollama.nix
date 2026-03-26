{ config, lib, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    openFirewall = true;
  };

  environment.systemPackages = [ pkgs.oterm ];
}
