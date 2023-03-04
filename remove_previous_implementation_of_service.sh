# < for removing "old" variant of systemd service of this driver (when was not used user template with @)
echo "Attempt to stop, disable and remove service from previous implementation (without using user templates @)"
systemctl stop asus_touchpad_numpad.service
if [[ $? = 0 ]]
then
	systemctl disable asus_touchpad_numpad.service
	if [[ $? != 0 ]]
	then
		echo "asus_touchpad_numpad.service cannot be disabled correctly..."
		exit 1
	else
		rm -f /etc/systemd/system/asus_touchpad_numpad.service
		if [[ $? != 0 ]]
		then
			echo "/etc/systemd/system/asus_touchpad_numpad.service cannot be removed correctly..."
			exit 1
		fi
	fi
fi
# />