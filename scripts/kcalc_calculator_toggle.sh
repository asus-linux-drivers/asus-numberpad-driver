#!/usr/bin/env bash

if ! pgrep -x kcalc >/dev/null 2>&1; then
  kcalc >/dev/null 2>&1 &
else
  killall kcalc >/dev/null 2>&1 &
fi