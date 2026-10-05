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
  ];
  system.network-tools.enable = true;
  system.generation-cleanup.enable = true;
}
