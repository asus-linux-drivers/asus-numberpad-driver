{ pkgs }:

{
  # test first if the new package name "xinput" is available, otherwise revert to the legacy package name "xorg.xinput".
  xinput =
    if pkgs ? xinput
    then pkgs.xinput
    else pkgs.xorg.xinput;
}
