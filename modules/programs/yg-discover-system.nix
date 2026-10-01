# NixOS-level half of yg-discover.nix: makes the GitHub token available to
# nix-daemon so fetchzip can authenticate against the private
# davidsebesta1/NetioDiscover repo when building the YG Discover / Netio
# Discover packages declared there.
#
# fetchurl/fetchzip's custom-header path (needed for the GitHub API's
# `Accept: application/octet-stream` asset-download convention) can't use
# Nix's global `netrc-file` setting — that's only read by Nix's builtin
# fetcher, which gets bypassed as soon as curlOptsList is set. Instead the
# derivation builds its own netrc file at build time from an impure env var
# (netrcImpureEnvVars/netrcPhase — the mechanism Nix provides specifically
# for passing secrets into fixed-output derivations without poisoning the
# output hash). That env var has to be present in nix-daemon's own
# environment, since nix-daemon (not the calling shell) is what actually
# runs the build on a multi-user NixOS install.
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.yg-discover-fetch;
in
{
  options.custom.yg-discover-fetch = {
    enable = lib.mkEnableOption "GitHub token plumbing for declaratively fetching YG/Netio Discover from the private davidsebesta1/NetioDiscover repo";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.github-netrc = {
      file  = ../../secrets/github-netrc.age;
      owner = "root";
      mode  = "0400";
    };

    # "-" prefix: don't fail to start if the secret isn't decrypted yet (first
    # switch that introduces this option, before agenix has run).
    systemd.services.nix-daemon.serviceConfig.EnvironmentFile = [
      "-/run/agenix/github-netrc"
    ];
  };
}
