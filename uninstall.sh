#!/bin/bash

if [[ $(id -u) != 0 ]]
then
	echo "Please, run this script as root (using sudo for example)"
	exit 1
fi

systemctl stop asus_touchpad_numpad
if [[ $? != 0 ]]
then
	echo "asus_touchpad_numpad.service cannot be stopped correctly..."
	exit 1
fi

systemctl stop asus_touchpad_numpad_suspend
if [[ $? != 0 ]]
then
	echo "asus_touchpad_numpad_suspend.service cannot be stopped correctly..."
	exit 1
fi

systemctl disable asus_touchpad_numpad
if [[ $? != 0 ]]
then
	echo "asus_touchpad_numpad.service cannot be disabled correctly..."
	exit 1
fi

systemctl disable asus_touchpad_numpad_suspend
if [[ $? != 0 ]]
then
	echo "asus_touchpad_numpad_suspend.service cannot be disabled correctly..."
	exit 1
fi

rm -f /lib/systemd/system/asus_touchpad_numpad.service
if [[ $? != 0 ]]
then
	echo "/lib/systemd/system/asus_touchpad_numpad.service cannot be removed correctly..."
	exit 1
fi

rm -f /lib/systemd/system/asus_touchpad_numpad_suspend.service
if [[ $? != 0 ]]
then
	echo "/lib/systemd/system/asus_touchpad_numpad_suspend.service cannot be removed correctly..."
	exit 1
fi

rm -rf /usr/share/asus_touchpad_numpad-driver/
if [[ $? != 0 ]]
then
	echo "/usr/share/asus_touchpad_numpad-driver/ cannot be removed correctly..."
	exit 1
fi

rm -rf /var/log/asus_touchpad_numpad-driver
if [[ $? != 0 ]]
then
	echo "/var/log/asus_touchpad_numpad-driver cannot be removed correctly..."
	exit 1
fi

echo "Asus touchpad python driver uninstalled"
exit 0
