{ config, pkgs, ... }:

let
  banner = pkgs.runCommand "motd-banner" { nativeBuildInputs = [ pkgs.figlet ]; } ''
    figlet "${config.networking.hostName}" > $out
  '';
in
{
  services.openssh.enable = true;

  users.motd = builtins.readFile banner;

  networking.hosts = {
    "192.168.4.133" = [ "sauron" ];
    "192.168.4.150" = [ "saruman" ];
  };
}
