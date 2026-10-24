{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lightcraft = {
      # Pinned to the v0.6.0 tag, not the default branch: main has a commit ahead of this release
      # that adds a git-source cargo dependency (craft-ui) without the matching Nix outputHashes
      # entry, which breaks `nix build` until upstream fixes it. Bump this tag deliberately once a
      # newer release's flake build is confirmed working.
      url = "github:storytold/lightcraft/v0.6.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun = {
      url = "github:anyrun-org/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    overlays = [
      (import ./overlays/rawtherapee-dev.nix)
      (import ./overlays/patool-no-check.nix)
      (import ./overlays/hypr-dynamic-cursors-hl-pin.nix)
      (import ./overlays/openrgb-darkproject-bushido.nix)
      (import ./overlays/gearlever-wrapper-fix.nix)
    ];
    overlayModule = {
      nixpkgs.overlays = overlays;
      # useGlobalPkgs is off, so HM needs the overlays applied again here, or its own packages won't see them.
      home-manager.sharedModules = [ { nixpkgs.overlays = overlays; } ];
    };
  in
  {
    nixosConfigurations = {

      sauron = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; nur = inputs.nur; };
        modules = [
          overlayModule
          ./hosts/sauron/configuration.nix
          inputs.home-manager.nixosModules.default
          inputs.agenix.nixosModules.default
        ];
      };

      saruman = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; nur = inputs.nur; };
        modules = [
          overlayModule
          ./hosts/saruman/configuration.nix
          inputs.home-manager.nixosModules.default
          inputs.agenix.nixosModules.default
        ];
      };
    };
  };
}
