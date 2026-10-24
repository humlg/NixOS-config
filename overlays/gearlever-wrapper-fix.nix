# gearlever's package.nix passes dontWrapGApps = true plus makeWrapperArgs =
# [ "${gappsWrapperArgs[@]}" "--prefix PATH : <path>" ], relying on the old
# eval-based wrapProgram to re-expand that literal string and to word-split a
# single multi-word "--prefix PATH : <path>" element. buildPythonApplication's
# wrap hook now defaults to makeBinaryWrapper's compiled C wrapper, which does
# neither: it fails with "makeCWrapper: Unknown argument ${gappsWrapperArgs[@]}".
# Fix: pass makeWrapperArgs as properly split elements, and append the real
# gappsWrapperArgs array at build time (preFixup, after gappsWrapperArgsHook
# has populated it) instead of via the broken string-interpolation trick.
# TODO: remove once nixpkgs updates gearlever's package.nix for this.
final: prev: {
  gearlever = prev.gearlever.overrideAttrs (old: {
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${final.lib.makeBinPath [
        final.file
        final._7zz
        final.which
        final.appimage-run
        final.desktop-file-utils
        final.gtk4.dev
        final.bintools
        final.libnotify
        final.dwarfs
        final.squashfs-tools
      ]}"
    ];
    preFixup = (old.preFixup or "") + ''
      makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
    '';
  });
}
