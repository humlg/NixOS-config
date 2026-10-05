# Secret Management (agenix)

Secrets are encrypted with [age](https://age-encryption.org/) via [agenix](https://github.com/ryantm/agenix). Encrypted `.age` files are committed to the repo and are safe to be public — decryption requires a private key that never leaves the machine. Decryption happens automatically at NixOS activation, using the host's SSH host private key. Decrypted secrets live in `/run/agenix/` (tmpfs, never written to disk unencrypted).

## How it works

- `secrets/secrets.nix` — maps each `.age` file to its recipient SSH public keys (host keys + david's user key)
- `secrets/*.age` — encrypted secret files committed to the repo
- `modules/nixos/system-secrets.nix` — NixOS module declaring where each secret is placed and with what permissions
- **Shell env vars**: `shell-env.age` decrypts to `/run/agenix/shell-env` and is sourced by zsh at shell start
- **SSH private keys**: declared with a `path =` in `age.secrets` so they land directly at `~/.ssh/<name>`

Not all `age.secrets` live in `modules/nixos/system-secrets.nix` — a host- or bundle-specific secret (like the 1NCE VPN's) can be declared directly inside its own opt-in module (see `modules/nixos/bundle-yg-work.nix`) so it's only decrypted on hosts that enable that module.

## Key locations

| File | Purpose |
|------|---------|
| `secrets/secrets.nix` | Recipient key map — edit when adding/removing hosts |
| `secrets/shell-env.age` | Shell environment variables (API tokens, etc.) |
| `secrets/github-huml-yg.age` | GitHub SSH deploy key (`github-huml-yg` host alias) — desktops (sauron, saruman, david) |
| `secrets/homelab.age` | SSH private key for the homelab server (192.168.5.1, `homelab` host alias, user `david`) — desktops (sauron, saruman, david) |
| `secrets/surface.age` | SSH private key for passwordless access to 192.168.4.148 (`surface` host alias, user `david`) — desktops (sauron, saruman, david) |
| `secrets/1nce-vpn.ovpn.age` | 1NCE cellular IoT OpenVPN client profile (embedded CA/cert/key) — saruman only |
| `secrets/1nce-vpn-credentials.age` | 1NCE VPN auth-user-pass file (username + token) — saruman only |
| `secrets/wg-homelab.age` | Personal WireGuard VPN — full wg-quick config file (private key, peer, full-tunnel AllowedIPs) — saruman only |
| `modules/nixos/system-secrets.nix` | NixOS declarations for secrets shared/common across hosts |
| `/run/agenix/` | Runtime location of decrypted secrets (tmpfs) |

## Adding a new secret (env var or file)

```bash
# 1. Add an entry to secrets/secrets.nix (choose recipients)
#    "my-token.age".publicKeys = desktops;

# 2. Create (or edit) the encrypted file — opens $EDITOR with plaintext
agenix -e secrets/my-token.age

# 3. Declare it in modules/nixos/system-secrets.nix:
#    age.secrets.my-token = {
#      file  = ../../secrets/my-token.age;
#      owner = "david";
#      mode  = "0400";
#      # path = "/home/david/.ssh/myserver";  # only needed for SSH keys / custom paths
#    };

# 4. Stage, commit, rebuild
git add secrets/my-token.age
git commit -m "secrets: add my-token"
sudo nixos-rebuild switch --flake .#<host>
```

For **shell env vars**, put the content in `shell-env.age` (one `export VAR="value"` per line) — they are automatically available in every new shell. For **SSH private keys**, use a dedicated `.age` file with `path = "/home/david/.ssh/..."` and `mode = "0600"`.

## Editing an existing secret

```bash
agenix -e secrets/shell-env.age   # opens decrypted content in $EDITOR, re-encrypts on save
git add secrets/shell-env.age
git commit -m "secrets: update shell-env"
sudo nixos-rebuild switch --flake .#<host>
```

## Removing a secret

```bash
# 1. Remove the age.secrets block from modules/nixos/system-secrets.nix
# 2. Delete the .age file
git rm secrets/my-token.age
# 3. Remove the entry from secrets/secrets.nix
git commit -m "secrets: remove my-token"
sudo nixos-rebuild switch --flake .#<host>
```

## Adding secrets to a new host

```bash
# 1. Get the new host's SSH host public key (run on the new host, or via ssh):
cat /etc/ssh/ssh_host_ed25519_key.pub

# 2. Add it to secrets/secrets.nix:
#    newhost = "ssh-ed25519 AAAA... root@newhost";
#    desktops = [ sauron saruman newhost david ];

# 3. Re-encrypt all existing secrets to include the new host as a recipient:
agenix -r secrets/shell-env.age
agenix -r secrets/ssh_myserver.age   # repeat for each .age file

# 4. Add agenix.nixosModules.default to the new host in flake.nix
# 5. Import modules/nixos/system-secrets.nix in the new host's configuration.nix
# 6. Stage, commit, rebuild on the new host
git add secrets/
git commit -m "secrets: add newhost as recipient, import secrets module"
sudo nixos-rebuild switch --flake .#newhost
```

## Encrypting a secret outside `agenix -e`

(e.g. scripting it, or a generated key): recipients passed to `age -r` must be the raw `ssh-ed25519 AAAA...` public key strings from `secrets/secrets.nix`, not the `age1...` X25519 form from `ssh-to-age`. The two produce different stanza types in the ciphertext header (`ssh-ed25519` vs `X25519`) — the NixOS activation script decrypts using the raw SSH host key files (`-i /etc/ssh/ssh_host_ed25519_key`), which only understands `ssh-ed25519` stanzas, so an `X25519`-recipient file fails at activation with "no identity matched any of the recipients" even though it encrypted without error.

Verify a manually-encrypted secret decrypts before committing: add a throwaway `age-keygen` identity as an extra recipient, decrypt with it locally, diff against the plaintext, then re-encrypt with only the real recipients. Also run `agenix -e`/`-r` from inside the `secrets/` directory — it resolves `./secrets.nix` relative to cwd.

## Security model

To decrypt any secret, an attacker needs one of the recipient private keys: either the host's SSH host key (`/etc/ssh/ssh_host_ed25519_key`, root-only) or your personal SSH private key (`~/.ssh/id_ed25519`). The encrypted `.age` files in the repo are worthless without one of those.
