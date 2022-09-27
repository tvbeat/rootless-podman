{
  description = "A set of janky scripts to aid in the installation of a version pinned rootless podman from nixpkgs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-compat }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      name = "tvbeat.podman-env";
    in
    {
      packages.${system} = {
        install = import ./install.nix { inherit name pkgs; };
        uninstall = import ./uninstall.nix { inherit name pkgs; };
      };
    };
}
