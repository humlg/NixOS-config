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
      (import ./overlays/dwarfs-nixpkgs-update-fix.nix)
      (import ./overlays/hypr-dynamic-cursors-hl-pin.nix)
    ];
    overlayModule = {
      nixpkgs.overlays = overlays;
      # home-manager.useGlobalPkgs is off (HM instantiates its own pkgs), so
      # the overlays above are invisible to home-manager-installed packages
      # (e.g. gearlever) unless also applied to every user's HM module here.
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

      nixosvm = nixpkgs.lib.nixosSystem{
        specialArgs = { inherit inputs; nur = inputs.nur; };
        modules = [
          overlayModule
          ./hosts/nixosvm/configuration.nix
          inputs.home-manager.nixosModules.default
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
