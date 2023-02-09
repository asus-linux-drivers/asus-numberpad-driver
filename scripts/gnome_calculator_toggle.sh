#!/bin/bash

if [[ $(pgrep -lf gnome-calculator) ]]; then
	killall gnome-calculator &>/dev/null &
else
	gnome-calculator &>/dev/null &
fi