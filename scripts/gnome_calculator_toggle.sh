#!/usr/bin/env bash

if [[ $(flatpak list | grep org.gnome.Calculator) ]]; then
  if [[ $(pgrep -lfx org.gnome.Calculator) ]]; then
  	flatpak run org.gnome.Calculator &>/dev/null &
  else
    flatpak kill org.gnome.Calculator &>/dev/null &
  fi
else
  if [[ $(pgrep -lfx gnome-calculator) ]]; then
  	killall gnome-calculator &>/dev/null &
  else
  	gnome-calculator &>/dev/null &
  fi
fi