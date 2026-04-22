# Override davinci-resolve to use locally downloaded 21.0 beta .run file.
# The .run file must be placed at the path below (or use `nix-store --add-fixed`).
# TODO: Remove this overlay once nixpkgs updates davinci-resolve to 21.x.
final: prev:
let
  lib = prev.lib;
  version = "21.0b1";
  pname = "davinci-resolve";

  src = prev.requireFile {
    name = "DaVinci_Resolve_${version}_Linux.run";
    url = "https://www.blackmagicdesign.com/products/davinciresolve";
    sha256 = "38df600c905a1fce522ef61162eef1dc6ac3dd28293326933e4036401a84c448";
  };

  davinci = prev.stdenv.mkDerivation {
    inherit pname version;

    nativeBuildInputs = with prev; [
      appimageTools.appimage-exec
      addDriverRunpath
      copyDesktopItems
    ];

    buildInputs = with prev; [
      libGLU
      libxxf86vm
    ];

    inherit src;
    sourceRoot = ".";

    unpackPhase = ''
      cp $src DaVinci_Resolve_${version}_Linux.run
      chmod +x DaVinci_Resolve_${version}_Linux.run
    '';

    installPhase = ''
      runHook preInstall

      export HOME=$PWD/home
      mkdir -p $HOME

      mkdir -p $out
      appimage-exec.sh -x $out DaVinci_Resolve_${version}_Linux.run

      mkdir -p $out/{"Apple Immersive/Calibration",configs,DolbyVision,easyDCP,Extras,Fairlight,GPUCache,logs,Media,"Resolve Disk Database",.crashreport,.license,.LUT}
      runHook postInstall
    '';

    dontStrip = true;

    postFixup = ''
      for program in $out/bin/*; do
        isELF "$program" || continue
        addDriverRunpath "$program"
      done

      for program in $out/libs/*; do
        isELF "$program" || continue
        if [[ "$program" != *"libcudnn_cnn_infer"* ]]; then
          addDriverRunpath "$program"
        fi
      done
      ln -s $out/libs/libcrypto.so.1.1 $out/libs/libcrypt.so.1
    '';

    desktopItems = [
      (prev.makeDesktopItem {
        name = "davinci-resolve";
        desktopName = "Davinci Resolve";
        genericName = "Video Editor";
        exec = "davinci-resolve";
        icon = "davinci-resolve";
        comment = "Professional video editing, color, effects and audio post-processing";
        categories = [ "AudioVideo" "AudioVideoEditing" "Video" "Graphics" ];
        startupWMClass = "resolve";
      })
    ];
  };
in
{
  davinci-resolve = prev.buildFHSEnv {
    inherit pname version;

    targetPkgs = pkgs: with pkgs; [
      alsa-lib
      aprutil
      bzip2
      davinci
      dbus
      expat
      fontconfig
      freetype
      glib
      libGL
      libGLU
      libarchive
      libcap
      librsvg
      libtool
      libuuid
      libxcrypt
      libxkbcommon
      nspr
      ocl-icd
      opencl-headers
      rocmPackages.clr.icd
      python3
      python3.pkgs.numpy
      udev
      xdg-utils
      libice
      libsm
      libx11
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxinerama
      libxrandr
      libxrender
      libxt
      libxtst
      libxxf86vm
      libxcb
      libxcb-util
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm
      xkeyboard-config
      zlib
    ];

    runScript = "${prev.bash}/bin/bash ${prev.writeText "davinci-wrapper" ''
      export QT_XKB_CONFIG_ROOT="${prev.xkeyboard_config}/share/X11/xkb"
      export QT_PLUGIN_PATH="${davinci}/libs/plugins:$QT_PLUGIN_PATH"
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/usr/lib32:${davinci}/libs
      # RDNA 3.5 (Radeon 880M/890M) may need GFX version override for ROCm compatibility
      export HSA_OVERRIDE_GFX_VERSION=''${HSA_OVERRIDE_GFX_VERSION:-11.0.0}
      ${davinci}/bin/resolve
    ''}";

    extraInstallCommands = ''
      mkdir -p $out/share/applications $out/share/icons/hicolor/128x128/apps
      ln -s ${davinci}/share/applications/*.desktop $out/share/applications/
      ln -s ${davinci}/graphics/DV_Resolve.png $out/share/icons/hicolor/128x128/apps/davinci-resolve.png
    '';

    passthru = { inherit davinci; };

    meta = {
      description = "Professional video editing, color, effects and audio post-processing";
      homepage = "https://www.blackmagicdesign.com/products/davinciresolve";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      mainProgram = "davinci-resolve";
    };
  };
}
