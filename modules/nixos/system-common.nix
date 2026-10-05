{ ... }:

{
  imports = [
    ./system-nix-settings.nix
    ./system-boot.nix
    ./system-console.nix
    ./system-networking.nix
    ./system-unfree.nix
    ./system-base-packages.nix
    ./system-users.nix
    ./system-ssh.nix
    ./system-motd.nix
    ./system-lan-hosts.nix
    ./system-network-tools.nix
    ./system-generation-cleanup.nix
    ./system-locale.nix
    ./system-sddm.nix
    ./system-secrets.nix
    ./desktop-hyprland.nix
    ./program-zsh.nix
    ./program-mkrepo.nix
    ./service-bluetooth.nix
    ./service-tailscale.nix
  ];
  system.network-tools.enable = true;
  system.generation-cleanup.enable = true;
  custom.bluetooth.enable = true;
  custom.tailscale.enable = true;
}
