# Adds OpenRGB support for the Dark Project Bushido 87 (GSKY-branded PCB, VID 0x342D /
# PID 0xE40F). Not upstream — OpenRGB's existing Controllers/DarkProject driver only
# covers the older KD3B V2 board (VID 0x195D, a completely different protocol); this PCB
# generation has no OpenRGB support at all. Reverse-engineered locally by capturing USB
# traffic (usbmon/Wireshark) between the vendor's web configurator and the keyboard, then
# confirmed by replaying the captured bytes directly via hidraw, independent of the
# browser. Only whole-keyboard "Direct" solid color is implemented — see the comment at
# the top of openrgb-darkproject-bushido/DarkProjectBushidoController.cpp for protocol
# details, and maintenance.md for how to remove this once/if it's upstreamed.
final: prev:
{
  openrgb = prev.openrgb.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      mkdir -p Controllers/DarkProjectBushido
      cp ${./openrgb-darkproject-bushido}/*.h Controllers/DarkProjectBushido/
      cp ${./openrgb-darkproject-bushido}/*.cpp Controllers/DarkProjectBushido/
    '';
  });
}
