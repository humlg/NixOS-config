{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {

      sauron = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/sauron/configuration.nix

          inputs.home-manager.nixosModules.default
        ];
      };

      "saruman-nixos" = nixpkgs.lib.nixosSystem{
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/sauron-nixos/configuration.nix
   	  inputs.home-manager.nixosModules.default
        ];
      };
    };
  };
}
