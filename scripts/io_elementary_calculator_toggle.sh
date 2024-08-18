#!/usr/bin/env bash

if [[ $(pgrep -xlf io.elementary.calculator &>/dev/null ; echo $?) != 0 ]]; then
	flatpak run io.elementary.calculator &>/dev/null &
else
  killall io.elementary.calculator &>/dev/null &
fi