#!/usr/bin/env bash

source non_sudo_check.sh

# i2cdetect is /usr/sbin/i2cdetect and some distributions do not add sbin to $PATH (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/154)
if [[ $(type i2cdetect 2>/dev/null) ]]; then
    INTERFACES=$(for i in $(i2cdetect -l | grep DesignWare | sed -r "s/^(i2c\-[0-9]+).*/\1/"); do echo $i; done)

    if [ -z "$INTERFACES" ]; then
        echo "No i2c interface can be found. Make sure you have installed libevdev packages"
        exit 1
    fi

    TOUCHPAD_WITH_NUMBERPAD_DETECTED=false
    for INDEX in $INTERFACES; do
        echo -n "Testing interface $INDEX: "

        NUMBER=$(echo -n $INDEX | cut -d'-' -f2)
        NUMBERPAD_OFF_CMD="i2ctransfer -f -y $NUMBER w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"
        I2C_TEST_15=$($NUMBERPAD_OFF_CMD 2>&1)

        # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/161
        NUMBERPAD_OFF_CMD="i2ctransfer -f -y $NUMBER w13@0x38 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"
        I2C_TEST_38=$($NUMBERPAD_OFF_CMD 2>&1)

        if [ -z "$I2C_TEST_15" ]; then
            echo "success (adr 0x15)"
            TOUCHPAD_WITH_NUMBERPAD_DETECTED=true
            break
        elif [ -z "$I2C_TEST_38" ]; then
            echo "success (adr 0x38)"
            TOUCHPAD_WITH_NUMBERPAD_DETECTED=true
            break
        else
            echo "failed"
        fi
    done

    if [ "$TOUCHPAD_WITH_NUMBERPAD_DETECTED" = true ]; then
        echo "The detection was successful. Touchpad with NumberPad found: $INDEX"
    else
        echo "The detection was not successful. Touchpad with NumberPad not found"
        exit 1
    fi
else
    echo "The i2cdetect tool not found to proceed initial test whether any i2c device react like NumberPad"
fi