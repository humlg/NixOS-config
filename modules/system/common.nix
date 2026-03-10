{ config, lib, pkgs, ... }:

{
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

  services.udisks2.enable = true;

  users.users.david = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  users.users.root.shell = pkgs.zsh;
}
