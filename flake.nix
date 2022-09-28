{
  description = "Support for installing rootless podman via nix on a regular GNU/Linux distribution";

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
    in
    {
      packages.${system}.podman-env = import ./podman-env.nix { pkgs = nixpkgs.legacyPackages.${system}; };
    };
}
