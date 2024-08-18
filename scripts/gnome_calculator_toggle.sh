#!/usr/bin/env bash

if [[ $(pgrep -xlf gnome-calculator &>/dev/null ; echo $?) != 0 ]]; then
  if [[ $(flatpak list | grep org.gnome.Calculator) ]]; then
    flatpak run org.gnome.Calculator &>/dev/null &
  else
    gnome-calculator &>/dev/null &
  fi
else
	killall gnome-calculator &>/dev/null &
fi