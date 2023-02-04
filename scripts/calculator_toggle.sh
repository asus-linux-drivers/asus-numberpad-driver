#!/bin/bash

if [[ $(ps aux | grep io.elementary.calculator | grep -v grep) ]]; then
	flatpak kill io.elementary.calculator &>/dev/null &
else
	flatpak run io.elementary.calculator &>/dev/null &
fi