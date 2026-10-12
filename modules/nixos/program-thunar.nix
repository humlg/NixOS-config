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

  services.tumbler.enable = true;
  environment.systemPackages = with pkgs; [
    tumbler            # thumbnail backend
    ffmpegthumbnailer  # video
    libgsf             # ODF
    poppler            # PDF
    freetype           # fonts
  ];

  # gdk-pixbuf loaders.cache must include librsvg for GTK apps (incl.
  # tumbler's gdk-pixbuf thumbnailer) to render SVG previews.
  programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];
}
