#!/usr/bin/env bash

pgrep -lf io.elementary.calculator
WHE=$(pgrep -xlf io.elementary.calculator &>/dev/null ; echo $?)
echo $WHE
if [[ $WHE != 0 ]]; then
	flatpak run io.elementary.calculator &>/dev/null &
else
  flatpak kill io.elementary.calculator &>/dev/null &
fi