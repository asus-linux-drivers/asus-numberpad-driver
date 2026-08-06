inputs:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.asus-numberpad-driver;
  defaultPackage = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.default;

  package = defaultPackage.override {
    waylandSupport = cfg.wayland;
    x11Support = !cfg.wayland;
  };

  # Function to convert configuration options to string
  toConfigFile = cfg:
    builtins.concatStringsSep "\n" ([ "[main]" ]
      ++ lib.attrsets.mapAttrsToList (key: value: "${key} = ${value}")
      cfg.config);

  # Writable directory for the config file
  configDir = "/etc/asus-numberpad-driver/";
in {
  options.services.asus-numberpad-driver = {
    enable = lib.mkEnableOption "Enable the Asus Numberpad Driver service.";

    layout = lib.mkOption {
      type = lib.types.str;
      default = "up5401ea";
      description =
        "The layout identifier for the numberpad driver (e.g. up5401ea). This value is required.";
    };

    config = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Configuration options for the numberpad driver.
        These options will be written to a configuration file for the driver.
      '';
    };

    display = lib.mkOption {
      type = lib.types.str;
      default = ":0";
      description = "The DISPLAY environment variable. Default is :0.";
    };

    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description =
        "Enable this option to run under Wayland. Disable it for X11.";
    };

    waylandDisplay = lib.mkOption {
      type = lib.types.str;
      default = "wayland-0";
      description =
        "The WAYLAND_DISPLAY environment variable. Default is wayland-0.";
    };

    ignoreWaylandDisplayEnv = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "If true, WAYLAND_DISPLAY will not be set in the service environment.";
    };

    runtimeDir = lib.mkOption {
      type = lib.types.str;
      default = "/run/user/1000/";
      description =
        "The XDG_RUNTIME_DIR environment variable, specifying the runtime directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];

    # Ensure the writable directories exists
    systemd.tmpfiles.rules = [
      "d ${configDir} 0755 root root -"
      "d /var/log/asus-numberpad-driver 0755 root root -"
    ];

    # Write the configuration file to the writable directory
    environment.etc."asus-numberpad-driver/numberpad_dev".text =
      toConfigFile cfg;

    # Enable i2c
    hardware.i2c.enable = true;

    # Enable uinput
    hardware.uinput.enable = true;

    # Add rest of the groups for dialpad
    users.groups = {
      input = { };
    };

    # Add root to the necessary groups
    users.users.root.extraGroups = [ "i2c" "input" "uinput" ];

    systemd.services.asus-numberpad-driver = {
      description = "Asus NumberPad Driver";
      wantedBy = [ "default.target" ];
      startLimitBurst = 20;
      startLimitIntervalSec = 300;
      serviceConfig = {
        Type = "simple";
        ExecStart =
          "${package}/share/asus-numberpad-driver/numberpad.py ${cfg.layout} ${configDir}";
        StandardOutput = "null";
        StandardError = "null";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutSec = 5;
        WorkingDirectory = "${package}";
        Environment = [
          "XDG_SESSION_TYPE=${if cfg.wayland then "wayland" else "x11"}"
          "XDG_RUNTIME_DIR=${cfg.runtimeDir}"
          "DISPLAY=${cfg.display}"
        ] ++ lib.optional (!cfg.ignoreWaylandDisplayEnv)
          "WAYLAND_DISPLAY=${cfg.waylandDisplay}";
      };
      path = [ pkgs.i2c-tools ];
    };
  };
}
