{ config, lib, pkgs, ... }:

let
  gtkThemeName = "WhiteSur-Dark-solid-purple";

  # Replaces Orchis-Purple-Dark-Compact (removed from nixpkgs, gtk-engine-murrine dependency unmaintained).
  gtkTheme = pkgs.whitesur-gtk-theme.override {
    colorVariants = [ "dark" ];
    themeVariants = [ "purple" ];
    opacityVariants = [ "solid" ];
  };

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
    gtkTheme
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
      package = gtkTheme;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = papirus-purple;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    # Explicit null (not omitted) to actually drop GTK4 theming — docs/architecture.md.
    gtk4 = {
      theme = null;
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
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
    # Deliberately no GTK_THEME — same GTK4 stub-import problem as above, see docs/architecture.md.
    QT_QPA_PLATFORMTHEME_QT5 = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
  };
}
