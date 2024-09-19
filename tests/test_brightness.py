#!/bin/python3

import re
import os

from time import sleep

keyboard_detected = 0
touchpad_detected = 0
device_addr = 0x00

with open('/proc/bus/input/devices', 'r') as f:

	lines = f.readlines()
	for line in lines:

		# Look for the touchpad #
		# https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver/issues/87
		# https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/95
		# https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/110
		if (touchpad_detected == 0 and ("Name=\"ASUE" in line or "Name=\"ELAN" in line or "Name=\"ASUP" or "Name=\"ASUF" in line) and "Touchpad" in line and not "9009" in line):

			touchpad_detected = 1

			# https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/161
			if ("ASUF1416" in line or "ASUF1205" in line or "ASUF1204" in line):
				device_addr = 0x38
			else:
				device_addr = 0x15

		if touchpad_detected == 1:
			if "S: " in line:
				# search device id
				device_id=re.sub(r".*i2c-(\d+)/.*$", r'\1', line).replace("\n", "")
			if "H: " in line:
				touchpad = line.split("event")[1]
				touchpad = touchpad.split(" ")[0]
				touchpad_detected = 2

		# Look for the keyboard (numlock) # AT Translated Set OR Asus Keyboard
		if keyboard_detected == 0 and ("Name=\"AT Translated Set 2 keyboard" in line or (("Name=\"ASUE" in line or "Name=\"Asus" in line or "Name=\"ASUP" in line or "Name=\"ASUF" in line) and "Keyboard" in line)):
		  keyboard_detected = 1

		if keyboard_detected == 1:
			if "H: " in line:
				keyboard = line.split("event")[1]
				keyboard = keyboard.split(" ")[0]
				keyboard_detected = 2

				# Do not stop looking if touchpad and keyboard have been found
				# because more drivers can be installed
				# https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver/issues/87
				# https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/95
				# https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/110
				#if keyboard_detected == 2 and touchpad_detected == 2:
				#	break

for i in range(2, 255):
	value = str(hex(i))
	valueLowestBrightness = "0x41"
	cmdOn = "i2ctransfer -f -y " + device_id + " w13@" + str(device_addr) + " 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 " + "0x01" + " 0xad"
	print("0x01")
	os.system(cmdOn)
	sleep(1)
	cmdLowestBrightness = "i2ctransfer -f -y " + device_id + " w13@" + str(device_addr) + " 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 " + valueLowestBrightness + " 0xad"
	print(valueLowestBrightness)
	os.system(cmdLowestBrightness)
	sleep(1)
	print("Tested value of registr: " + str(i) + " (hex: " + value + ")")
	cmdNewValue = "i2ctransfer -f -y " + device_id + " w13@" + str(device_addr) + " 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 " + value + " 0xad"
	os.system(cmdNewValue)
	input("Press Enter to continue...")

cmdoff = "i2ctransfer -f -y " + device_id + " w13@" + str(device_addr) + " 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"
os.system(cmdoff)
