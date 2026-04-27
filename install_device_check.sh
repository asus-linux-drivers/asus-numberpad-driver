#!/usr/bin/env bash

source non_sudo_check.sh

send_test_activation() {
    local number=$1
    local addr=$2

    sudo /usr/sbin/i2ctransfer -f -y "$number" w13@0x"$addr" \
        0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x01 0xad \
    && sudo /usr/sbin/i2ctransfer -f -y "$number" w13@0x"$addr" \
        0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x60 0xad
}

send_test_deactivation() {
    local number=$1
    local addr=$2

    sudo /usr/sbin/i2ctransfer -f -y "$number" w13@0x"$addr" \
    0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad
}

# i2cdetect is /usr/sbin/i2cdetect and some distributions do not add sbin to $PATH (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/154)
# https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/218
if command -v /usr/sbin/i2cdetect >/dev/null 2>&1 && command -v /usr/sbin/i2ctransfer >/dev/null 2>&1; then

    INTERFACES=$(grep -A5 -i touchpad /proc/bus/input/devices | grep -o 'i2c-[0-9]\+' | sort -u)

    if [ -z "$INTERFACES" ]; then
        echo "No i2c interface can be found. Make sure you have installed libevdev packages"
        exit 1
    fi

    TOUCHPAD_WITH_NUMBERPAD_DETECTED=

    for INDEX in $INTERFACES; do
        echo -n "Testing interface $INDEX: "

        NUMBER=$(echo -n $INDEX | cut -d'-' -f2)

        second_try_addr=

        # OFF test 0x15 
        if send_test_deactivation "$NUMBER" 15 >/dev/null 2>&1; then
            first_try_addr=15

            # OFF test 0x38
            if send_test_deactivation "$NUMBER" 38 >/dev/null 2>&1; then
                second_try_addr=38
            fi
        # OFF test 0x38
        elif send_test_deactivation "$NUMBER" 38 >/dev/null 2>&1; then
            first_try_addr=38
        else
            echo "failed"
            continue
        fi

        send_test_activation "$NUMBER" "$first_try_addr"
        echo
        read -p "Did NumberPad light up? (0x$first_try_addr) [y/N]: " OK_FIRST

        if [[ "$OK_FIRST" =~ ^[Yy]$ ]]; then
            DEVICE_ADDRESS=$first_try_addr
            TOUCHPAD_WITH_NUMBERPAD_DETECTED=true
            send_test_deactivation "$NUMBER" "$first_try_addr"
            break
        fi

        if [ -n "$second_try_addr" ]; then

            send_test_activation "$NUMBER" "$second_try_addr"
            read -p "Did NumberPad light up? (0x$second_try_addr) [y/N]: " OK_SECOND

            if [[ "$OK_SECOND" =~ ^[Yy]$ ]]; then
                DEVICE_ADDRESS=$second_try_addr
                TOUCHPAD_WITH_NUMBERPAD_DETECTED=true
                send_test_deactivation "$NUMBER" "$second_try_addr"
                break
            fi
        fi

        echo "failed"
    done

    if [ -z "$TOUCHPAD_WITH_NUMBERPAD_DETECTED" ]; then
        echo "The detection was not successful. Touchpad with NumberPad not found. Check whether your touchpad has integrated NumberPad (e.g. on product websites) and in case it has then eventually create an issue here https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/new/choose."
        
        read -p "Do you want try to continue anyway? [y/N]: " CONTINUE

        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo "The i2cdetect or i2ctransfer tool not found to proceed initial test whether any i2c device react like NumberPad"
fi