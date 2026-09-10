{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, self, ... } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "i686-linux" "aarch64-linux"];

    pkgsForEach = forAllSystems (system: nixpkgs.legacyPackages.${system}.appendOverlays [
      self.overlays.default
    ]);
  in {
    packages = forAllSystems (system: 
      let pkgs = pkgsForEach.${system}; in
      {
        default = pkgs.asus-numberpad-driver;
      });

    devShells = forAllSystems (system: {
      default = pkgsForEach.${system}.callPackage ./nix/shell.nix {};
    });

    overlays.default = final: _: {
      asus-numberpad-driver = final.callPackage ./nix/default.nix {};
    };

    nixosModules.default = ./nix/module.nix;
  };
}