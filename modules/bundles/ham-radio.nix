{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.ham-radio;
in
{
  options.bundles.ham-radio = {
    enable = lib.mkEnableOption "Amateur (ham) radio bundle: SDR receiving and FT8/digital-mode software";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sdrpp   # SDR++ — SDR receiver GUI (waterfall/spectrum, decoders, recording)
      wsjtx   # FT8/FT4/JT65/... weak-signal digital mode suite
      hamlib  # rig-control library/CLI (rigctl, rigctld) — CAT control backend used by wsjtx and others

      # --- other apps worth considering, uncomment as needed ---
      # gqrx        # alternative SDR receiver GUI (simpler than sdrpp, also GNU Radio-based)
      # gnuradio    # SDR signal-processing toolkit for custom flowgraphs
      # cubicsdr    # another SDR receiver GUI option
      # js8call     # JS8 — FT8-like weak-signal mode with free-text keyboard-to-keyboard messaging
      # fldigi      # PSK31/RTTY/other classic digital modes
      # flrig       # rig-control GUI, commonly paired with fldigi
      # direwolf    # software TNC/digipeater for APRS over a soundcard
      # xastir      # APRS mapping/tracking client
      # chirp       # radio programming software for handheld/mobile transceivers
      # gpredict    # satellite tracking/pass prediction, useful for ham satellite ops
      # qsstv       # slow-scan television (SSTV) send/receive
    ];

    # RTL-SDR dongle udev rules (grants non-root USB access via the plugdev group).
    services.udev.packages = [ pkgs.rtl-sdr ];
    users.groups.plugdev = { };
    users.users.david.extraGroups = [ "plugdev" "dialout" ]; # plugdev: RTL-SDR USB access; dialout: CAT-control serial ports
  };
}
