{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
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
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    overlays = [
      (import ./overlays/rawtherapee-dev.nix)
    ];
    overlayModule = { nixpkgs.overlays = overlays; };
  in
  {
    nixosConfigurations = {

      sauron = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          overlayModule
          ./hosts/sauron/configuration.nix

          inputs.home-manager.nixosModules.default
        ];
      };

      nixosvm = nixpkgs.lib.nixosSystem{
        specialArgs = {inherit inputs;};
        modules = [
          overlayModule
          ./hosts/nixosvm/configuration.nix
   	      inputs.home-manager.nixosModules.default
        ];
      };

      saruman = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          overlayModule
          ./hosts/saruman/configuration.nix
          inputs.home-manager.nixosModules.default
        ];
      };
    };
  };
}
