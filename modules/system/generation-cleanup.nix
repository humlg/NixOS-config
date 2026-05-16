{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.generation-cleanup;

  cleanupScript = pkgs.writeShellApplication {
    name = "nixos-cleanup-generations";
    runtimeInputs = [ pkgs.coreutils pkgs.nix ];
    text = ''
      PROFILE=/nix/var/nix/profiles/system
      KEEP="${toString cfg.keepGenerations}"

      # All generation numbers, newest first
      mapfile -t all_gens < <(
        nix-env -p "$PROFILE" --list-generations \
          | awk '{print $1}' \
          | sort -rn
      )

      if [ "''${#all_gens[@]}" -eq 0 ]; then
        echo "No generations found, nothing to do."
        exit 0
      fi

      # Kernel store path of the currently deployed profile
      current_kernel=$(readlink -f "$PROFILE/kernel")

      # Find the most recent generation whose kernel differs from the current one.
      # This is the "previous kernel" rollback anchor.
      prev_kernel_gen=""
      for gen in "''${all_gens[@]}"; do
        gen_path="''${PROFILE}-''${gen}-link"
        if [ -L "$gen_path" ] && [ -e "$gen_path/kernel" ]; then
          gen_kernel=$(readlink -f "$gen_path/kernel")
          if [ "$gen_kernel" != "$current_kernel" ]; then
            prev_kernel_gen="$gen"
            break
          fi
        fi
      done

      # Build keep-set: N most recent + previous-kernel anchor
      declare -A keep_set
      count=0
      for gen in "''${all_gens[@]}"; do
        if [ "$count" -lt "$KEEP" ]; then
          keep_set[$gen]=1
          (( count++ )) || true
        fi
      done

      if [ -n "$prev_kernel_gen" ]; then
        if [ -z "''${keep_set[$prev_kernel_gen]+_}" ]; then
          keep_set[$prev_kernel_gen]=1
          echo "Anchoring generation $prev_kernel_gen (last generation with a different kernel)"
        fi
      fi

      # Delete anything outside the keep-set
      deleted=0
      for gen in "''${all_gens[@]}"; do
        if [ -z "''${keep_set[$gen]+_}" ]; then
          echo "Deleting generation $gen"
          nix-env -p "$PROFILE" --delete-generations "$gen"
          (( deleted++ )) || true
        fi
      done

      if [ "$deleted" -eq 0 ]; then
        echo "Nothing to delete (''${#all_gens[@]} generations, all within policy)."
      else
        echo "Deleted $deleted generation(s). Running garbage collection..."
        nix-collect-garbage
      fi
    '';
  };
in
{
  options.system.generation-cleanup = {
    enable = mkEnableOption "automatic NixOS generation cleanup";

    keepGenerations = mkOption {
      type = types.ints.positive;
      default = 10;
      description = ''
        Number of most-recent system generations to keep.
        In addition, the most recent generation whose kernel differs from the
        current profile's kernel is always preserved as a rollback anchor.
      '';
    };

    dates = mkOption {
      type = types.str;
      default = "weekly";
      description = ''
        Systemd calendar expression controlling how often the cleanup runs.
        See systemd.time(7) for the format.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Keep the bootloader menu in sync with the generation limit.
    # Add 2 as a small buffer for the anchor entry + any in-flight builds.
    boot.loader.systemd-boot.configurationLimit = cfg.keepGenerations + 2;

    systemd.services.nixos-generation-cleanup = {
      description = "NixOS generation cleanup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cleanupScript}/bin/nixos-cleanup-generations";
      };
    };

    systemd.timers.nixos-generation-cleanup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.dates;
        # Run the cleanup shortly after boot if it was missed while offline.
        Persistent = true;
      };
    };
  };
}
