{ pkgs, lib ? pkgs.lib }:
let
  containersConf = (pkgs.formats.toml {}).generate "containers.conf" {
    containers = {    
      keyring = false;
      pids_limit = -1;
    };
    network = {
      cni_plugin_dirs = with pkgs; [ "${cni-plugins}/bin" "${dnsname-cni}/bin" ];
    };
  };

  registriesConf = pkgs.writeText "registries.conf" ''
    [registries.search]
    registries = ['docker.io']
    [registries.block]
    registries = []
  '';

  podmanSupport = pkgs.runCommandLocal "tvbeat.podman-support" { } ''
    mkdir -p $out/bin $out/etc/containers $out/lib/systemd/user $out/lib/systemd/user/sockets.target.wants

    # compatibility layer is helpful
    ln -s ${pkgs.podman}/bin/podman $out/bin/docker

    # bug (missing feature?) in old systemd version from ubuntu 20.04 - `.d/override.conf` overrides
    # are not picked up so we have to directly edit the file
    install -Dm644 ${pkgs.podman}/lib/systemd/user/podman.service $out/lib/systemd/user/podman.service
    sed -i 's|ExecStart=podman|ExecStart=${pkgs.podman}/bin/podman|' $out/lib/systemd/user/podman.service

    # $out/etc/containers needs to be symlinked to /etc/containers
    ln -s ${containersConf} $out/etc/containers/containers.conf
    ln -s ${registriesConf} $out/etc/containers/registries.conf
    ln -s ${pkgs.skopeo.src}/default-policy.json $out/etc/containers/policy.json

    # automatically start podman.socket without any user interaction
    ln -s ${pkgs.podman}/lib/systemd/user/podman.socket $out/lib/systemd/user/sockets.target.wants/podman.socket
  '';
in
  pkgs.buildEnv {
    name = "tvbeat.podman-env";
    paths = [
      podmanSupport
      (lib.lowPrio pkgs.podman)
    ];
  }
