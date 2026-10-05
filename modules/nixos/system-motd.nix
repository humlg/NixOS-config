{ config, pkgs, ... }:

let
  banner = pkgs.runCommand "motd-banner" { nativeBuildInputs = [ pkgs.figlet ]; } ''
    figlet "${config.networking.hostName}" > $out
  '';
in
{
  users.motd = builtins.readFile banner;
}
