{ config, lib, pkgs, ... }:

let
  cfg = config.programs.btop;
  home = config.home.homeDirectory;
in
{
  config = lib.mkIf cfg.enable {
    programs.btop.settings = {
      color_theme = "pywal";
      theme_background = false;
    };

    # Symlink wallust-generated btop theme
    home.file.".config/btop/themes/pywal.theme".source =
      config.lib.file.mkOutOfStoreSymlink "${home}/.cache/wallust/colors-btop";
  };
}
