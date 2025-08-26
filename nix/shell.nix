{
  python313Packages,
  ...
}:
let
  mainPkg = python313Packages.callPackage ./default.nix {};
in
mainPkg.overrideAttrs (oa: {
    nativeBuildInputs =
      [
        python313Packages.pip
      ]
      ++ (oa.nativeBuildInputs or []);
})
