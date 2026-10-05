{ config, lib, pkgs, ... }:

let
  cfg = config.custom.amdgpu-s2idle-patch;
in
{
  options.custom.amdgpu-s2idle-patch = {
    enable = lib.mkEnableOption ''
      a locally-patched kernel that drops the DCN3.5+ "enter IPS before D3cold"
      step from amdgpu's dm_suspend(), which wedges this iGPU on resume from any
      s2idle long enough to reach hardware sleep. See
      patches/amdgpu-no-idle-opt-on-s2idle.patch for the full rationale and
      maintenance.md for the removal condition.

      Note this makes every kernel version bump compile the kernel locally
      (~15-25 min), and reduces but does NOT eliminate the hang (confirmed
      2026-08-18: recurred on two consecutive unattended sleeps after a
      short watched soak looked clean). Do not pair this with
      suspend-then-hibernate — that specific sequence (s2idle, then a
      delayed silent internal resume before converting to hibernate) is what
      triggered a separate hibernate-resume TTM crash on this machine. See
      maintenance.md item 7.
    '';

    fasterHibernateCompression = lib.mkOption {
      type    = lib.types.bool;
      default = true;
      description = ''
        Also build in LZ4 hibernation image compression and make it the default.
        Stock nixpkgs kernels ship CONFIG_HIBERNATION_COMP_LZ4=n, so the
        hibernate.compressor= kernel parameter can only select LZO there. LZ4
        decompresses several times faster than LZO, which shortens the resume
        path that remains after this patch — hibernate is still the fallback for
        long absences. Free to enable here because the kernel is already being
        built from source for the patch above.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPatches = [
      ({
        name  = "amdgpu-no-idle-opt-on-s2idle";
        patch = ../../patches/amdgpu-no-idle-opt-on-s2idle.patch;
      } // lib.optionalAttrs cfg.fasterHibernateCompression {
        # HIBERNATION_COMP_{LZO,LZ4} are a Kconfig "choice", so LZO has to be
        # turned off explicitly rather than just switching LZ4 on — otherwise
        # the base nixpkgs config and this one both claim the choice.
        #
        # CRYPTO_LZ4/LZ4_COMPRESS are forced built-in rather than left as the
        # modules stock nixpkgs ships. The compressor is needed again on the
        # *resume* path, where the image is decompressed early from the initrd;
        # depending on request_module() succeeding there would make the
        # hibernate fallback — the safety net for this whole arrangement — rely
        # on modprobe being reachable at exactly the wrong moment.
        structuredExtraConfig = {
          HIBERNATION_COMP_LZO = lib.kernel.no;
          HIBERNATION_COMP_LZ4 = lib.kernel.yes;
          CRYPTO_LZ4           = lib.kernel.yes;
          LZ4_COMPRESS         = lib.kernel.yes;
        };
      })
    ];

    # Selecting the compressor explicitly rather than relying on
    # CONFIG_HIBERNATION_DEF_COMP, so the intent survives a kernel config change.
    boot.kernelParams = lib.mkIf cfg.fasterHibernateCompression [ "hibernate.compressor=lz4" ];
  };
}
