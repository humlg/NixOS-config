# YG Discover / Netio Discover — same .NET/Avalonia binary, two brand names, run
# via steam-run (its FHS env lacks libICE/libSM, added via LD_LIBRARY_PATH).
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.yg-discover;

  extraLibs = lib.makeLibraryPath [ pkgs.libice pkgs.libsm ];

  mkWrapper = name: binaryPath: pkgs.writeShellScriptBin name ''
    export LD_LIBRARY_PATH="${extraLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec ${pkgs.steam-run}/bin/steam-run "${binaryPath}" "$@"
  '';

  mkDesktopEntry = displayName: exec: {
    name       = displayName;
    inherit exec;
    icon       = "network-wired";
    terminal   = false;
    type       = "Application";
    categories = [ "Network" ];
  };
in
{
  options.programs.yg-discover = {
    enable = lib.mkEnableOption "YG Discover network discovery tool wrapper (steam-run + libICE/libSM)";

    binaryPath = lib.mkOption {
      type        = lib.types.str;
      default     = "${config.home.homeDirectory}/YellowGrid/discover/YG-Discover-Linux-x86.Desktop";
      description = "Path to the prebuilt YG-Discover Linux binary. Distributed outside Nix (colleague-provided download), not vendored into this repo.";
    };

    netio = {
      enable = lib.mkEnableOption "Netio Discover network discovery tool wrapper (same fix as yg-discover, differently branded binary from the same app family)";

      binaryPath = lib.mkOption {
        type        = lib.types.str;
        default     = "${config.home.homeDirectory}/YellowGrid/discover/Netio/NetioDiscover.Desktop";
        description = "Path to the prebuilt Netio Discover Linux binary. Distributed outside Nix (colleague-provided download), not vendored into this repo.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ (mkWrapper "yg-discover" cfg.binaryPath) ];
      xdg.desktopEntries.yg-discover = mkDesktopEntry "YG Discover" "yg-discover";
    })
    (lib.mkIf cfg.netio.enable {
      home.packages = [ (mkWrapper "netio-discover" cfg.netio.binaryPath) ];
      xdg.desktopEntries.netio-discover = mkDesktopEntry "Netio Discover" "netio-discover";
    })
  ];
}
