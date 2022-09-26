{
  description = "A nix flake to help install a rootless podman from nixpkgs";

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
    in
    {
      apps.${system}.install = {
        type = "app";
        program = "${import ./install.nix { inherit pkgs; }}/bin/install.sh";
      };
    };
}
