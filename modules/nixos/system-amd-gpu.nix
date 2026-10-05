{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Early KMS — needed for Wayland compositors and Plymouth
  boot.initrd.kernelModules = [ "amdgpu" ];

  # Latest AMD GPU firmware (includes RDNA 4 blobs)
  hardware.enableRedistributableFirmware = true;

  # Unlocks all AMDGPU power management features (voltage/clock curves in corectrl)
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  # ROCm OpenCL (for GPU-accelerated apps like DaVinci Resolve)
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    libglvnd
  ];

  # RDNA 4 (RX 9070 XT) is not yet officially supported by ROCm.
  # Override GFX version to treat it as the closest supported architecture.
  # Verify the right value once ROCm adds native RDNA 4 support.
  environment.variables = {
    HSA_OVERRIDE_GFX_VERSION = "12.0.0";
    LIBVA_DRIVER_NAME        = "radeonsi";  # VA-API hardware video decode
  };

  # GPU performance tuning (requires ppfeaturemask unlock above)
  programs.corectrl.enable = true;
}
