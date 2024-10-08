{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "i686-linux" "aarch64-linux"];
    pkgsForEach = nixpkgs.legacyPackages;
  in {
    packages = forAllSystems (system: {
      default = pkgsForEach.${system}.python311Packages.callPackage ./nix/default.nix {};
    });

    devShells = forAllSystems (system: {
      default = pkgsForEach.${system}.callPackage ./nix/shell.nix {};
    });

    overlays.default = final: _: {
      asus-numberpad-driver = final.callPackage ./nix/default.nix {};
    };

    nixosModules.default = import ./nix/module.nix inputs;
  };
}
