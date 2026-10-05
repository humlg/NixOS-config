{ config, lib, pkgs, ... }:

let
  cfg = config.custom.amdgpu-s2idle-patch;
in
{
  options.custom.amdgpu-s2idle-patch = {
    enable = lib.mkEnableOption ''
      a locally-patched kernel dropping amdgpu's DCN3.5+ "IPS before D3cold"
      s2idle step (wedges this iGPU on resume). Compiles the kernel locally on
      every version bump. Full rationale, effectiveness, and removal
      condition: docs/maintenance.md item 7.
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
        # LZO/LZ4 are a Kconfig "choice" — must turn LZO off explicitly.
        # LZ4/LZ4_COMPRESS forced built-in (not modules): needed early on the
        # resume path, before modprobe is reliably reachable.
        structuredExtraConfig = {
          HIBERNATION_COMP_LZO = lib.kernel.no;
          HIBERNATION_COMP_LZ4 = lib.kernel.yes;
          CRYPTO_LZ4           = lib.kernel.yes;
          LZ4_COMPRESS         = lib.kernel.yes;
        };
      })
    ];

    boot.kernelParams = lib.mkIf cfg.fasterHibernateCompression [ "hibernate.compressor=lz4" ];
  };
}
