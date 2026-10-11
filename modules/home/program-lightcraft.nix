{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.lightcraft;
in
{
  options.programs.lightcraft = {
    enable = lib.mkEnableOption "LightCraft (open-source Lightroom-alike photo editor/culler)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.lightcraft.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
