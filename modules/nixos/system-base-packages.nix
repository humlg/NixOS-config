{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    openvpn
  ];

  services.udisks2.enable = true;
}
