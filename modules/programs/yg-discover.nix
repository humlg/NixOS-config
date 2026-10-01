# YG Discover / Netio Discover — colleague-built network discovery tools for
# YellowGrid products (.NET/Avalonia app, same build shared under two brand
# names/binaries). Source + releases: the private GitHub repo
# davidsebesta1/NetioDiscover — see modules/programs/yg-discover-system.nix
# for the NixOS-level half (GitHub token plumbing for nix-daemon).
#
# Both Linux builds are fetched declaratively (fetchzip, pinned by release
# asset id + sha256 — NOT a mutable tag/branch URL) rather than relying on a
# manually-placed file:
#   - YG Discover:    v2.0.0.5-yg   (asset id 353171009)
#   - Netio Discover: v2.0.0.4beta  (asset id 303854414 — the newer
#     v2.0.0.5-netio release never got a Linux build published; this is the
#     same binary byte-for-byte as what was previously run from a manual copy)
# To bump either: find the new release's asset id (`gh api
# repos/davidsebesta1/NetioDiscover/releases/tags/<tag> --jq '.assets[]'`)
# and its sha256 (`gh ... --jq '.assets[].digest'`, or `nix hash convert
# --hash-algo sha256 --to sri <hex digest>`), then update the two values
# below.
#
# They expect a standard FHS layout, so they're run through steam-run;
# steam-run's FHS environment is missing libICE/libSM (X11 session-management
# libs Avalonia's X11 backend needs), so those are added via LD_LIBRARY_PATH
# on top of it.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.yg-discover;

  extraLibs = lib.makeLibraryPath [ pkgs.libice pkgs.libsm ];

  # Both zips contain a single file at the archive root, internally named
  # NetioDiscover.Desktop regardless of brand (confirmed via `unzip -l` on
  # both release assets) — not a directory, so stripRoot must be off.
  fetchDiscoverRelease = { assetId, sha256 }: pkgs.fetchzip {
    url = "https://api.github.com/repos/davidsebesta1/NetioDiscover/releases/assets/${toString assetId}";
    inherit sha256;
    stripRoot    = false;
    curlOptsList = [ "-H" "Accept: application/octet-stream" ];

    # See yg-discover-system.nix — nix-daemon's own environment supplies this.
    netrcImpureEnvVars = [ "GITHUB_NETRC_TOKEN" ];
    netrcPhase = ''
      echo "machine api.github.com login x-access-token password $GITHUB_NETRC_TOKEN" > netrc
    '';
  };

  ygDiscoverSrc = fetchDiscoverRelease {
    assetId = 353171009; # v2.0.0.5-yg : YGDiscover-Linux.zip
    sha256  = "sha256-YNroQAWr661y8WsEyS+k6o5puEPcgp+EObocnGHDHlo=";
  };

  netioDiscoverSrc = fetchDiscoverRelease {
    assetId = 303854414; # v2.0.0.4beta : NetioDiscover-Linux.zip
    sha256  = "sha256-NAlWLyqzSJOy36luzgle79lqrcYlknT7J5qDAeFX7uU=";
  };

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
      type        = lib.types.nullOr lib.types.str;
      default     = null;
      description = "Override: run this binary instead of the one fetched declaratively from GitHub releases (e.g. a manually-placed local build).";
    };

    netio = {
      enable = lib.mkEnableOption "Netio Discover network discovery tool wrapper (same fix as yg-discover, differently branded binary from the same app family)";

      binaryPath = lib.mkOption {
        type        = lib.types.nullOr lib.types.str;
        default     = null;
        description = "Override: run this binary instead of the one fetched declaratively from GitHub releases (e.g. a manually-placed local build).";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        (mkWrapper "yg-discover" (
          if cfg.binaryPath != null then cfg.binaryPath else "${ygDiscoverSrc}/NetioDiscover.Desktop"
        ))
      ];
      xdg.desktopEntries.yg-discover = mkDesktopEntry "YG Discover" "yg-discover";
    })
    (lib.mkIf cfg.netio.enable {
      home.packages = [
        (mkWrapper "netio-discover" (
          if cfg.netio.binaryPath != null then cfg.netio.binaryPath else "${netioDiscoverSrc}/NetioDiscover.Desktop"
        ))
      ];
      xdg.desktopEntries.netio-discover = mkDesktopEntry "Netio Discover" "netio-discover";
    })
  ];
}
