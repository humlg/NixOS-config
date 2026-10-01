# YG Discover — a colleague-built network discovery tool for YellowGrid products
# (.NET/Avalonia app, prebuilt Linux x86_64 binary, not packaged in nixpkgs and not
# built from source in this repo). It expects a standard FHS layout, so it's run
# through steam-run; steam-run's FHS environment is missing libICE/libSM (X11
# session-management libs Avalonia's X11 backend needs), so those are added via
# LD_LIBRARY_PATH on top of it.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.yg-discover;

  wrapper = pkgs.writeShellScriptBin "yg-discover" ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ pkgs.libice pkgs.libsm ]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec ${pkgs.steam-run}/bin/steam-run "${cfg.binaryPath}" "$@"
  '';
in
{
  options.programs.yg-discover = {
    enable = lib.mkEnableOption "YG Discover network discovery tool wrapper (steam-run + libICE/libSM)";

    binaryPath = lib.mkOption {
      type        = lib.types.str;
      default     = "${config.home.homeDirectory}/YellowGrid/discover/YG-Discover-Linux-x86.Desktop";
      description = "Path to the prebuilt YG-Discover Linux binary. Distributed outside Nix (colleague-provided download), not vendored into this repo.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ wrapper ];

    xdg.desktopEntries.yg-discover = {
      name       = "YG Discover";
      exec       = "yg-discover";
      icon       = "network-wired";
      terminal   = false;
      type       = "Application";
      categories = [ "Network" ];
    };
  };
}
