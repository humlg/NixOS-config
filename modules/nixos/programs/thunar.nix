{ config, lib, pkgs, ... }:

{
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
    ];
  };

  services.gvfs.enable = true;

  # Thumbnail generation
  services.tumbler.enable = true;
  environment.systemPackages = with pkgs; [
    tumbler            # thumbnail backend
    ffmpegthumbnailer  # video
    libgsf             # ODF
    poppler            # PDF
    freetype           # fonts
  ];
}
