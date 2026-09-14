{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.asus-numberpad-driver;

  defaultConfigFile = 
    pkgs.writeText "numberpad_dev" ''
      ; vim: filetype=dosini
      ; Asus NumberPad configuration
      ${lib.generators.toINI { } cfg.defaultConfig}
    '';

  package = cfg.package.override {
    waylandSupport = cfg.wayland;
    x11Support = !cfg.wayland;
  };
in {
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "asus-numberpad-driver" ]
      [ "hardware" "asus-numberpad-driver" ])
  ];

  options.hardware.asus-numberpad-driver = {
    enable = lib.mkEnableOption "Enable the Asus Numberpad Driver service.";

    package = lib.mkPackageOption pkgs "asus-numberpad-driver" { };

    layout = lib.mkOption {
      type = lib.types.str;
      default = "up5401ea";
      description =
        "The layout identifier for the numberpad driver (e.g. up5401ea). This value is required.";
    };

    defaultConfig = lib.mkOption {
      type = with lib.types;
        let
          valueType = nullOr (oneOf [
            bool
            int
            float
            str
            path
            (attrsOf valueType)
            (listOf valueType)
          ]) // {
            description = "Asus NumberPad Driver configuration value";
          };
        in valueType;
      example = {
        main = {
          enabled = true;
          numpad_disables_sys_numlock = 1;
          top_right_icon_coactivator_key = "Shift";
        };
      };
      default = { };
      description = ''
        Default configuration options for the Asus NumberPad Driver on first run.
        It’s recommended to use a user-level configuration manager for this file or manually define with `lib.generators.toINI { } { /* your config */ }`.
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

    dbusSessionBusAddress = lib.mkOption {
      type = lib.types.str;
      default = "unix:path=/run/user/1000/bus";
      description =
        "The DBUS_SESSION_BUS_ADDRESS environment variable, specifying the dbus session bus address.";
    };

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "INFO";
      description = "Logging level.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];

    # Enable i2c
    hardware.i2c.enable = true;

    # Enable uinput
    hardware.uinput.enable = true;

    # Add rest of the groups for numberpad
    users.groups = {
      input = { };
    };

    systemd.user.services.asus-numberpad-driver = {
      description = "Asus NumberPad Driver";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ConfigurationDirectory = "asus-numberpad-driver";
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'test -e %E/asus-numberpad-driver/numberpad_dev || cp ${defaultConfigFile} %E/asus-numberpad-driver/numberpad_dev'";
        ExecStart = "${package}/share/asus-numberpad-driver/numberpad.py ${cfg.layout} %E/asus-numberpad-driver/";
        StandardOutput = "null";
        StandardError = "null";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutSec = 5;
        WorkingDirectory = "${package}/share/asus-numberpad-driver";
        Environment = [
          "LOG=${cfg.logLevel}"
          "XDG_SESSION_TYPE=${if cfg.wayland then "wayland" else "x11"}"
          "XDG_RUNTIME_DIR=${cfg.runtimeDir}"
          "DBUS_SESSION_BUS_ADDRESS=${cfg.dbusSessionBusAddress}"
          "DISPLAY=${cfg.display}"
        ] ++ lib.optional (!cfg.ignoreWaylandDisplayEnv)
          "WAYLAND_DISPLAY=${cfg.waylandDisplay}";
      };
      path = [ pkgs.i2c-tools pkgs.qt6.qttools ];
    };
  };
}
