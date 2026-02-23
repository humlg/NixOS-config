{ config, lib, pkgs, ... }:

let
  gtkThemeName = "Orchis-Purple-Dark-Compact";
in
{
  programs.dconf.enable = true;

  # Nudge apps/toolkits system-wide
  environment.sessionVariables = {
    GTK_THEME = gtkThemeName;

    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_QPA_PLATFORMTHEME_QT5 = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
  };

  # Apply to all Home Manager users
  home-manager.sharedModules = [
    ({ pkgs, ... }: {
      home.packages = with pkgs; [
        orchis-theme
        adwaita-icon-theme

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
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
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
          icon-theme = "Adwaita";
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
    })
  ];
}
