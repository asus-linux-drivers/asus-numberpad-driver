# ASUS Numberpad Driver Installation Guide for BazziteOS

## Quick Start

```bash
# 1. Clone and enter the repository
git clone https://github.com/asus-linux-drivers/asus-numberpad-driver
cd asus-numberpad-driver
git checkout v6.8.6

# 2. Run the installer
INSTALL_DIR_PATH="/home/$USER/.local/share/asus-numberpad-driver" \
INSTALL_UDEV_DIR_PATH="/etc/udev" \
bash install.sh

# 3. Reboot when prompted (required!)
# After reboot, run the installer again:

INSTALL_DIR_PATH="/home/$USER/.local/share/asus-numberpad-driver" \
INSTALL_UDEV_DIR_PATH="/etc/udev" \
bash install.sh

# 4. Reboot one final time
# Your numberpad should now work!
```

---

## Detailed Installation Steps

### Step 1: Free Up Disk Space (If Needed)

If you get a disk space error, run these commands:

```bash
# Clean up old system versions
rpm-ostree cleanup -b
sudo ostree admin cleanup

# Clean up containers (if you use them)
podman system prune -a

# Clean up old logs
sudo journalctl --vacuum-time=3d
```

Check available space:
```bash
df -h /
```

You need at least a few hundred MB free.

---

### Step 2: First Installation Run

The installer will detect BazziteOS and install required system packages.

```bash
cd ~/asus-numberpad-driver

INSTALL_DIR_PATH="/home/$USER/.local/share/asus-numberpad-driver" \
INSTALL_UDEV_DIR_PATH="/etc/udev" \
bash install.sh
```

**What happens:**
- Detects your system as BazziteOS
- Installs development packages (python3-devel, wayland-devel, etc.)
- Prompts you to reboot

**Important:** Answer "yes" when asked to reboot!

---

### Step 3: Reboot

```bash
systemctl reboot
```

**At the GRUB menu:** Select the first option (ostree:0) - this is the default.

---

### Step 4: Second Installation Run

After rebooting, run the installer again to complete the setup:

```bash
cd ~/asus-numberpad-driver

INSTALL_DIR_PATH="/home/$USER/.local/share/asus-numberpad-driver" \
INSTALL_UDEV_DIR_PATH="/etc/udev" \
bash install.sh
```

**What happens:**
- Skips package installation (already done)
- Sets up user groups
- Detects your touchpad
- Creates Python virtual environment
- Installs Python dependencies
- Asks you to select your laptop's numberpad layout
- Installs the systemd service
- Asks about optional features (external keyboard, calculator toggle, power saver)

**Answer the prompts:**
- Select your laptop model from the list
- Choose a co-activator key (or None)
- Say "yes" to install the systemd service
- Choose optional features as desired

---

### Step 5: Final Reboot

```bash
systemctl reboot
```

**Why?** Your user needs to be added to the `input` group, which only takes effect after logging out/rebooting.

---

### Step 6: Verify It's Working

After the final reboot, check the service status:

```bash
systemctl --user status asus_numberpad_driver@$USER.service
```

You should see:
```
● asus_numberpad_driver@[your-username].service - Asus NumberPad Driver
     Active: active (running)
```

If it says "active (running)", you're done! Your numberpad should work.

---

## Troubleshooting

### Service Won't Start

Check the logs:
```bash
journalctl --user -u asus_numberpad_driver@$USER.service -n 50
```

### Permission Denied Errors

If you see "Permission denied: '/dev/input/event3'", you need to add yourself to the input group.

**Option 1: Use BazziteOS's built-in command (try this first)**

```bash
ujust add-user-to-input-group
```

Then reboot:
```bash
systemctl reboot
```

**Note:** This command didn't work for some users (including the author of this guide), but it might work for you. If it doesn't, try Option 2.

**Option 2: Manual method**

```bash
# Check if you're in the input group
id

# If you don't see "104(input)", add yourself manually:
sudo bash -c "echo 'input:x:104:$USER' >> /etc/group"
sudo usermod -aG input $USER

# Then reboot
systemctl reboot
```

After rebooting, verify you're in the group:
```bash
id | grep input
```

You should see `104(input)` in the output.

### Disk Space Issues

```bash
# Clean up old deployments
rpm-ostree cleanup -b
sudo ostree admin cleanup

# Check space
df -h /
```

### Wrong OSTree Deployment

If you accidentally booted into ostree:1 instead of ostree:0:

```bash
# Check which deployment you're on
rpm-ostree status

# Look for the one with a ● (current)
# It should have "LayeredPackages: libxkbcommon-devel python3-devel..."

# If not, reboot and select ostree:0 from GRUB
```

---

## What Gets Installed

**System packages** (via rpm-ostree):
- python3-devel, wayland-devel, wayland-protocols-devel
- libxkbcommon-devel, systemd-devel, python3-systemd
- xinput, pkg-config, libxcb-devel

**Driver files:**
- `/home/$USER/.local/share/asus-numberpad-driver/` - Driver and config
- `~/.config/systemd/user/asus_numberpad_driver@.service` - Systemd service
- `/etc/udev/rules.d/` - udev rules (if you enabled optional features)

**User groups:**
- input, i2c, uinput, numberpad

---

## Uninstalling

```bash
cd ~/asus-numberpad-driver

INSTALL_DIR_PATH="/home/$USER/.local/share/asus-numberpad-driver" \
INSTALL_UDEV_DIR_PATH="/etc/udev/" \
bash uninstall.sh
```

To remove the layered packages:
```bash
rpm-ostree uninstall python3-devel wayland-devel wayland-protocols-devel libxkbcommon-devel systemd-devel python3-systemd xinput pkg-config libxcb-devel
systemctl reboot
```

---

## Why Two Reboots?

BazziteOS is an immutable system:
1. **First reboot:** Activates the newly installed system packages
2. **Second reboot:** Activates the group membership changes

This is normal for immutable distributions like BazziteOS, Fedora Silverblue, etc.

---

## Need Help?

- Check the logs: `journalctl --user -u asus_numberpad_driver@$USER.service`
- View install logs: `ls -la /var/log/asus-numberpad-driver/`
- Open an issue: https://github.com/asus-linux-drivers/asus-numberpad-driver/issues
