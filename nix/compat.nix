{ pkgs }:

{
  xinput =
    if pkgs ? xorg.xinput
    then pkgs.xorg.xinput
    else pkgs.xinput;
}
