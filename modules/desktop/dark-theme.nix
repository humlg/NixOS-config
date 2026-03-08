{ config, lib, pkgs, ... }:

let
  gtkThemeName = "Orchis-Purple-Dark-Compact";

  papirus-purple = pkgs.runCommand "papirus-icon-theme-purple" {
    nativeBuildInputs = [ pkgs.gtk3 ];
  } ''
    mkdir -p $out/share/icons
    cp -r --no-preserve=mode ${pkgs.papirus-icon-theme}/share/icons/* $out/share/icons/
    export HOME=$(mktemp -d)
    export USER_HOME=$HOME
    ${pkgs.papirus-folders}/bin/papirus-folders -o -t $out/share/icons/Papirus-Dark -C violet
  '';
in
{
  home.packages = with pkgs; [
    orchis-theme
    papirus-purple

    qt6Packages.qt6ct
    libsForQt5.qt5ct
    qt6Packages.qtstyleplugin-kvantum
    libsForQt5.qtstyleplugin-kvantum
  ];

  gtk = {
    enable = true;

    theme = {
      name = gtkThemeName;
      package = pkgs.orchis-theme;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = papirus-purple;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = gtkThemeName;
      icon-theme = "Papirus-Dark";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
    style.name = "kvantum";
  };

  home.sessionVariables = {
    GTK_THEME = gtkThemeName;
    QT_QPA_PLATFORMTHEME_QT5 = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
  };
}
