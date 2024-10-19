inputs: { config, lib, pkgs, ... }:

let
  cfg = config.services.asus-numberpad-driver;
  defaultPackage = inputs.self.packages.${pkgs.system}.default;

  # Function to convert configuration options to string
  toConfigFile = cfg: builtins.concatStringsSep "\n" (
    [ "[main]" ] ++ lib.attrsets.mapAttrsToList (key: value: "${key} = ${value}") cfg.config
  );

  # Writable directory for the config file
  configDir = "/etc/asus-numberpad-driver";
in {
  options.services.asus-numberpad-driver = {
    enable = lib.mkEnableOption "Enable the Asus Numberpad Driver service.";

    layout = lib.mkOption {
      type = lib.types.str;
      default = "up5401ea";
      description = "The layout identifier for the numberpad driver (e.g. up5401ea). This value is required.";
    };

    config = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = ''
        Configuration options for the numberpad driver.
        These options will be written to a configuration file for the driver.
      '';
    };

    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable this option to run under Wayland. Disable it for X11.";
    };

    runtimeDir = lib.mkOption {
      type = lib.types.str;
      default = "/run/user/1000/";
      description = "The XDG_RUNTIME_DIR environment variable, specifying the runtime directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ defaultPackage ];

    # Ensure the writable directories exists
    systemd.tmpfiles.rules = [
      "d ${configDir} 0755 root root -"
      "d /var/log/asus-numberpad-driver 0755 root root -"
    ];

    # Write the configuration file to the writable directory
    environment.etc."asus-numberpad-driver/numberpad_dev".text = toConfigFile cfg;

    # Enable i2c
    hardware.i2c.enable = true;

    # Add groups for numpad
    users.groups = {
      uinput = { };
      input = { };
      i2c = { };
    };

    # Add root to the necessary groups
    users.users.root.extraGroups = [ "i2c" "input" "uinput" ];

    # Add the udev rule to set permissions for uinput and i2c-dev
    services.udev.extraRules = ''
      # Set uinput device permissions
      KERNEL=="uinput", GROUP="uinput", MODE="0660"
      # Set i2c-dev permissions
      SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
    '';

    # Load specific kernel modules
    boot.kernelModules = [ "uinput" "i2c-dev" ];

    systemd.services.asus-numberpad-driver = {
      description = "Asus Numberpad Driver";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${defaultPackage}/share/asus-numberpad-driver/numberpad.py ${cfg.layout} ${configDir}";
        StandardOutput = "append:/var/log/asus-numberpad-driver/error.log";
        StandardError = "append:/var/log/asus-numberpad-driver/error.log";
        Restart = "on-failure";
	RestartSec = 1;
	TimeoutSec = 5;
        WorkingDirectory = "${defaultPackage}";
        Environment = [
          ''XDG_SESSION_TYPE=${if cfg.wayland then "wayland" else "x11"}''
          ''XDG_RUNTIME_DIR=${cfg.runtimeDir}''
        ];
      };
    };

  };
}
