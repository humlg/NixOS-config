{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/locale.nix
    ../../modules/system/sddm.nix
    ../../modules/services/bluetooth.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # LUKS encryption (swap partition)
  boot.initrd.luks.devices."luks-01b4b8c5-f250-4434-b00a-86d91e74ce05".device = "/dev/disk/by-uuid/01b4b8c5-f250-4434-b00a-86d91e74ce05";

  networking.hostName = "saruman";
  networking.networkmanager.enable = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "cz";
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  security.polkit.enable = true;

  environment.variables = {
    NIXPKGS_ALLOW_UNFREE = 1;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL          = "1";
  };

  services.xserver.xkb.layout = "cz";

  services.printing.enable = true;
  services.colord.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  services.libinput.enable = true;

  users.users.david = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  users.users.root.shell = pkgs.zsh;

  home-manager = {
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
    users = {
      "david" = import ./home.nix;
    };
  };

  programs.firefox.enable = true;
  programs.thunar.enable = true;
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "agnoster";
    };
    interactiveShellInit = ''
      if command -v fastfetch >/dev/null 2>&1; then
        fastfetch
      fi
    '';
  };
  programs.kdeconnect.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    htop
    btop
    kitty
    gtk3
    rofi
    waybar
    git
    unzip
    pywal16
    waypaper
    chromium
    swww
    fastfetch
    discord
    vscode
    steam
    kdePackages.kate
    mpv
    ffmpeg
    pywalfox-native
    pavucontrol
    kdePackages.kdeconnect-kde
    cliphist
    wl-clipboard
    hyprlock
    hypridle
    hyprshot
    swaynotificationcenter
    obsidian
    blueman
    udiskie
    librewolf
    tree
    spotify
    lazygit
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  services.openssh.enable = true;

  system.stateVersion = "25.11";
}
