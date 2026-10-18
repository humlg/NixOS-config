{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
    ../../modules/nixos/system-common.nix
    ../../modules/nixos/system-amd-gpu.nix
    ../../modules/nixos/bundle-photography.nix
    ../../modules/nixos/bundle-3d-printing.nix
    ../../modules/nixos/bundle-wine.nix
    ../../modules/nixos/bundle-gaming.nix
    ../../modules/nixos/bundle-ham-radio.nix
    ../../modules/nixos/bundle-workstation.nix
    ../../modules/nixos/service-wivrn.nix
  ];

  networking.hostName = "sauron";

  # Kernel resets WoL on every boot otherwise; also requires BIOS WoL/PCI-E Power On enabled.
  networking.interfaces.enp9s0.wakeOnLan.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelModules = [ "nct6775" "i2c-dev" ];
  boot.kernelParams = [ "amd_pstate=passive" ];

  powerManagement.cpuFreqGovernor = "performance";

  boot.loader.systemd-boot.consoleMode = "max";  # HiDPI: larger TTY console/boot-menu font
  #console.packages = [ pkgs.terminus_font ];    # fallback if consoleMode=max isn't enough
  #console.font = "ter-132b";

  # Docker — used to run GPU-accelerated (ROCm) containers, e.g. Stable
  # Diffusion UIs, without declaring each one as a Nix module. See
  # docker-compose files kept outside this repo for the actual workloads.
  virtualisation.docker.enable = true;
  users.users.david.extraGroups = [ "docker" ];

  # ComfyUI (running in Docker above) — opened for LAN access from saruman.
  networking.firewall.allowedTCPPorts = [ 8188 ];

  # Ollama (enabled via bundles.workstation) defaults to binding 127.0.0.1 regardless of
  # openFirewall, so it's unreachable from the LAN unless the host is widened too. Needed
  # for the hermes server to reach models running here.
  services.ollama.host = "0.0.0.0";

  # Default Ollama context window (2048-4096 depending on model) is too small for
  # Hermes' tool-use loop, which requires >=64k. 65536 is Hermes' documented
  # known-good starting point.
  services.ollama.environmentVariables = {
    OLLAMA_CONTEXT_LENGTH = "65536";
  };

  custom.wivrn.enable = true;

  programs.coolercontrol.enable = true;
  bundles.workstation.enable = true;
  custom.noctalia.enable = true;  # full replacement here, unlike saruman's staged pilot — docs/maintenance.md #19
  bundles.photography.enable = true;
  bundles."3d-printing".enable = true;
  bundles.wine.enable = true;
  bundles.gaming.enable = true;
  bundles.ham-radio.enable = true;

  home-manager = {
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; nur = inputs.nur; };
    users = {
      "david" = import ./home.nix;
    };
  };

  environment.systemPackages = with pkgs; [
    gtk3
    xterm
    alacritty
    wofi
    spice-vdagent
    quickshell
    lm_sensors
    stress
    cava
    usbutils
    bs-manager
  ];

  system.stateVersion = "25.11";
}
