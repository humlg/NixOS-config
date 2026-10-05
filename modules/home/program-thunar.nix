{ pkgs, ... }:
{
  imports = [ ./program-thunar-vault.nix ];

  home.packages = with pkgs; [ gocryptfs zenity thunar ];
}
