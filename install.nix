{ pkgs }:
let
  # nixpkgs doesn't properly include podman.service for a few reasons, so we need to manage this ourselves
  # see https://github.com/NixOS/nixpkgs/pull/160410#discussion_r856743592 for details
  service = pkgs.runCommand "podman.service" { } ''
    install -Dm644 ${pkgs.podman-unwrapped.src}/contrib/systemd/user/podman.service.in $out/lib/systemd/user/podman.service
    substituteInPlace $out/lib/systemd/user/podman.service --replace "@@PODMAN@@" "${pkgs.podman}/bin/podman"
  '';

  registriesConf = pkgs.writeText "registries.conf" ''
    [registries.search]
    registries = ['docker.io']
    [registries.block]
    registries = []
  '';

  containersConf =
    let
      plugins = pkgs.symlinkJoin {
        name = "cni-plugins";
        paths = with pkgs; [ cni-plugins dnsname-cni ];
      };
    in
      pkgs.writeText "containers.conf" ''
        [containers]
        keyring=false
        pids_limit=-1
        [network]
        cni_plugin_dirs = [
          "${plugins}/bin"
        ]
      '';

  # provides a fake "docker" binary mapping to podman
  dockerCompat = pkgs.runCommandNoCC "docker-podman-compat" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.podman}/bin/podman $out/bin/docker
  '';

  nixEnv = pkgs.buildEnv {
    name = "podman-env";
    paths = with pkgs; [
      podman
      dockerCompat

      (lib.hiPrio service)
      (runCommand "extraConf" {} ''
        install -Dm644 ${containersConf} $out/etc/containers/containers.conf
        install -Dm644 ${registriesConf} $out/etc/containers/registries.conf
        install -Dm644 ${pkgs.skopeo.src}/default-policy.json $out/etc/containers/policy.json
      '')
    ];
  };
in
  pkgs.writeShellScriptBin "install.sh" ''
    if ! which newuidmap > /dev/null; then
      echo "newuidmap command not found"
      echo "please install the uidmap package via 'sudo apt install -y uidmap' and run this script again"

      exit 1
    fi

    nix-env -i ${nixEnv}

    mkdir -p ~/.config/containers ~/.local/share/systemd/user

    ln -fs ~/.nix-profile/etc/containers/containers.conf ~/.config/containers/
    ln -fs ~/.nix-profile/etc/containers/registries.conf ~/.config/containers/
    ln -fs ~/.nix-profile/etc/containers/policy.json ~/.config/containers/

    ln -fs ~/.nix-profile/lib/systemd/user/podman.service ~/.local/share/systemd/user/
    ln -fs ~/.nix-profile/lib/systemd/user/podman.socket ~/.local/share/systemd/user/

    systemctl --user daemon-reload

    systemctl --user enable podman.socket
    systemctl --user restart podman.service
    systemctl --user restart podman.socket
  ''
