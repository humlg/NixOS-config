{ ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    NIXPKGS_ALLOW_UNFREE = 1;
  };
}
