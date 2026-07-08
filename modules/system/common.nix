{ config, lib, pkgs, ... }:

{
  imports = [
    ./ssh.nix
    ./network-tools.nix
    ./generation-cleanup.nix
  ];
  system.network-tools.enable = true;
  system.generation-cleanup.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;

  networking.firewall.allowedTCPPorts = [ 46687 ];

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

  # Prevent inotify watch exhaustion (VS Code, MEGAcmd, etc. consume many watches)
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;

  services.udisks2.enable = true;

  users.users.david = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "render" ];
    shell = pkgs.zsh;
  };
  users.users.root.shell = pkgs.zsh;
}
