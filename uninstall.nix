{ name, pkgs }:

pkgs.writeShellScriptBin "install.sh" ''
  systemctl --user stop podman.service podman.socket
  systemctl --user disable podman.service podman.socket
  systemctl --user daemon-reload

  rm -f ~/.config/containers/containers.conf
  rm -f ~/.config/containers/registries.conf
  rm -f ~/.config/containers/policy.json

  rm -f ~/.config/systemd/user/podman.service
  rm -f ~/.config/systemd/user/podman.socket

  rm -rf ~/.config/cni

  if [[ ! -z "$XDG_RUNTIME_DIR" ]]; then
    rm -rf $XDG_RUNTIME_DIR/containers $XDG_RUNTIME_DIR/crun $XDG_RUNTIME_DIR/libpod $XDG_RUNTIME_DIR/netns $XDG_RUNTIME_DIR/podman
  fi

  # NOTE: this won't work if you have switched your profile to flakes in which case you'll have to use the `nix profile` command instead
  nix-env --uninstall tvbeat.podman-env 
''
