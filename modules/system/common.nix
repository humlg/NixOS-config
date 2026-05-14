{ config, lib, pkgs, ... }:

{
  imports = [
    ./ssh.nix
    ./network-tools.nix
    ../programs/fastfetch.nix
  ];
  system.network-tools.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "cz";
  };

  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    NIXPKGS_ALLOW_UNFREE = 1;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
  ];

  services.udisks2.enable = true;

  users.users.david = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "render" ];
    shell = pkgs.zsh;
  };
  users.users.root.shell = pkgs.zsh;
}
