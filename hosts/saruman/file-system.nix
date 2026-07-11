{ ... }:

{
  # NAS (Synology-style) NFS share, mounted on demand.
  # Laptop roams networks, so this must never block boot or hang a shell:
  #  - x-systemd.automount + noauto: no mount at boot; triggers lazily on
  #    first access to ~/nas, so it's a no-op when off the home network.
  #  - x-systemd.mount-timeout=10s + retry=0: a failed mount attempt (NAS
  #    unreachable) fails fast instead of hanging the triggering process.
  #  - x-systemd.idle-timeout=600: auto-unmounts after 10m idle, so a stale
  #    mount doesn't linger once you leave the network.
  #  - soft + timeo=14: NFS ops error out after ~1.4s*retrans instead of
  #    hanging forever if the NAS drops off mid-use (hard mounts would
  #    otherwise freeze any process touching the mount).
  fileSystems."/home/david/nas" = {
    device = "192.168.4.180:/nfs/Public";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
      "x-systemd.mkdir"
      "nofail"
      "soft"
      "timeo=14"
      "retry=0"
    ];
  };
}
