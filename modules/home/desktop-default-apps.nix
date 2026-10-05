{ ... }:

{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Images — Gwenview
      "image/png" = "org.kde.gwenview.desktop";
      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/gif" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";
      "image/bmp" = "org.kde.gwenview.desktop";
      "image/svg+xml" = "org.kde.gwenview.desktop";
      "image/tiff" = "org.kde.gwenview.desktop";

      # Web browser — Zen
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "x-scheme-handler/about" = "zen.desktop";
      "x-scheme-handler/unknown" = "zen.desktop";
      "text/html" = "zen.desktop";
      "application/xhtml+xml" = "zen.desktop";

      # PDF — Zen
      "application/pdf" = "zen.desktop";

      # Teams meetings
      "x-scheme-handler/msteams" = "teams-for-linux.desktop";
    };
  };
}
