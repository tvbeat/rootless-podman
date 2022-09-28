# Installing a rootless `podman` using `nixpkgs` on a server

This `flake` can help you install and configure `podman` software which can be
run in rootless mode by any user on the server.

Additional to installing `podman` you will configure user level `systemd` instances
pickup units provided by the `nix` package manager.

## Configure user level `systemd` to pickup units provided by `nix`

We will utilize [SYSTEMD_UNIT_PATH](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Unit%20File%20Load%20Path)
to configure user level `systemd` instances to pickup units provided by the `nix` package manager.

Edit the `user@.service` unit via `systemctl edit`:
```
sudo systemctl edit user@.service
```

Copy and paste the following text:
```
[Service]
Environment="SYSTEMD_UNIT_PATH=/nix/var/nix/profiles/default/lib/systemd/user:"
```

At this point it is easiest to simply restart the server. If this isn't an option
you can fiddle with with `sudo systemctl daemon-reload`, `sudo systemctl restart user@$UID.service`,
`sudo loginctl terminate-user $USER`, etc... The idea being that the user level `systemd`
instances need to be restarted. Again, much simpler to reboot the server as that
will take care of **all** users on the server.

## Install and configure the `podman` environment

To install the software and configuration provided by this `flake`:

```
sudo /nix/var/nix/profiles/default/bin/nix-env -if default.nix -A packages.x86_64-linux.podman-env
```

Symlink required configuration in place:
```
sudo ln -s /nix/var/nix/profiles/default/etc/containers /etc/containers
```

From here when users login to the server they should find that `podman` is up and
running for them.
