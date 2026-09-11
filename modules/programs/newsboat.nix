{ pkgs, ... }:

{
  # Native Home Manager module. With home.stateVersion "25.11" (>= 21.05) this
  # writes to ~/.config/newsboat/{urls,config} (XDG), not the legacy
  # ~/.newsboat/ — confirmed correct for this repo's newsboat version, which
  # only falls back to ~/.newsboat if that directory already exists on disk.
  programs.newsboat = {
    enable = true;
    package = pkgs.newsboat;

    autoReload = true;
    reloadTime = 60; # minutes
    reloadThreads = 8;

    # browser left at the HM default (xdg-open) — resolves through
    # default-apps.nix's mimeApps, which points http(s) at Zen already.

    urls = [
      # ── World ───────────────────────────────────────────────────────
      { url = "http://feeds.bbci.co.uk/news/world/rss.xml"; title = "BBC World News"; tags = [ "news" "world" ]; }
      { url = "https://www.aljazeera.com/xml/rss/all.xml"; title = "Al Jazeera"; tags = [ "news" "world" ]; }
      { url = "https://feeds.npr.org/1004/rss.xml"; title = "NPR World"; tags = [ "news" "world" ]; }

      # ── Europe ──────────────────────────────────────────────────────
      { url = "https://www.euronews.com/rss?level=theme&name=news"; title = "Euronews"; tags = [ "news" "europe" ]; }
      { url = "https://rss.dw.com/rdf/rss-en-eu"; title = "DW Europe"; tags = [ "news" "europe" ]; }

      # ── Czechia ─────────────────────────────────────────────────────
      { url = "https://www.irozhlas.cz/rss/irozhlas"; title = "iRozhlas"; tags = [ "news" "czechia" ]; }
      { url = "https://ct24.ceskatelevize.cz/rss/hlavni-zpravy"; title = "ČT24"; tags = [ "news" "czechia" ]; }
      { url = "https://www.novinky.cz/rss"; title = "Novinky.cz"; tags = [ "news" "czechia" ]; }

      # ── Tech: Linux ─────────────────────────────────────────────────
      { url = "https://www.phoronix.com/rss.php"; title = "Phoronix"; tags = [ "tech" "linux" ]; }
      { url = "https://lwn.net/headlines/rss"; title = "LWN.net"; tags = [ "tech" "linux" ]; }
      { url = "https://itsfoss.com/feed/"; title = "It's FOSS"; tags = [ "tech" "linux" ]; }

      # ── Tech: AI ────────────────────────────────────────────────────
      { url = "https://www.theverge.com/rss/ai-artificial-intelligence/index.xml"; title = "The Verge — AI"; tags = [ "tech" "ai" ]; }
      { url = "https://simonwillison.net/atom/everything/"; title = "Simon Willison"; tags = [ "tech" "ai" ]; }

      # ── Gaming ──────────────────────────────────────────────────────
      { url = "https://www.pcgamer.com/rss/"; title = "PC Gamer"; tags = [ "gaming" ]; }
      { url = "https://www.rockpapershotgun.com/feed"; title = "Rock Paper Shotgun"; tags = [ "gaming" ]; }
      { url = "https://kotaku.com/rss"; title = "Kotaku"; tags = [ "gaming" ]; }
    ];

    queries = {
      world = ''tags # "world"'';
      europe = ''tags # "europe"'';
      czechia = ''tags # "czechia"'';
      tech = ''tags # "tech"'';
      gaming = ''tags # "gaming"'';
    };
  };
}
