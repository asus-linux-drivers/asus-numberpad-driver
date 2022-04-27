#!/bin/python3

import re
import os

from time import sleep

tries = 5

# Look into the devices file #
while tries > 0:

	keyboard_detected = 0
	touchpad_detected = 0

	with open('/proc/bus/input/devices', 'r') as f:

		lines = f.readlines()
		for line in lines:
			# Look for the touchpad #
			if touchpad_detected == 0 and ("Name=\"ASUE" in line or "Name=\"ELAN" in line) and "Touchpad" in line:
				touchpad_detected = 1

			if touchpad_detected == 1:
				if "S: " in line:
					# search device id
					device_id=re.sub(r".*i2c-(\d+)/.*$", r'\1', line).replace("\n", "")
				if "H: " in line:
					touchpad = line.split("event")[1]
					touchpad = touchpad.split(" ")[0]
					touchpad_detected = 2

			# Look for the keyboard (numlock) # AT Translated Set OR Asus Keyboard
			if keyboard_detected == 0 and ("Name=\"AT Translated Set 2 keyboard" in line or "Name=\"Asus Keyboard" in line):
				keyboard_detected = 1

			if keyboard_detected == 1:
				if "H: " in line:
					keyboard = line.split("event")[1]
					keyboard = keyboard.split(" ")[0]
					keyboard_detected = 2

			# Stop looking if both have been found #
			if keyboard_detected == 2 and touchpad_detected == 2:
				tries-=1
				break

s1 = [1, 11,  81, 131, 161, 181, 231, 241]
s2 = [21, 41, 51, 61, 71, 91, 101, 111, 121, 141, 151, 171, 201]
s3 = [31]

print("Hight bright")
for i in range(len(s1)):
	print(s1[i], hex(s1[i]))
	cmdon = "i2ctransfer -f -y " + device_id + " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 " + str(hex(s1[i])) + " 0xad"
	os.system(cmdon)
	sleep(10)

print("middle bright")
for i in range(len(s2)):
	print(s2[i], hex(s2[i]))
	cmdon = "i2ctransfer -f -y " + device_id + " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 " + str(hex(s2[i])) + " 0xad"
	os.system(cmdon)
	sleep(10)

print("low bright")
for i in range(len(s3)):
	print(s3[i], hex(s3[i]))
	cmdon = "i2ctransfer -f -y " + device_id + " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 " + str(hex(s3[i])) + " 0xad"
	os.system(cmdon)
	sleep(10)


cmdoff = "i2ctransfer -f -y " + device_id + " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"
os.system(cmdoff)
