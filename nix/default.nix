{ lib
, python313Packages
, pkgs
}:

let
  # Define the Python packages required
  pythonPackages = pkgs.python313.withPackages (ps: with ps; [
    numpy
    libevdev
    xlib
    pyinotify
    pyasyncore
    pywayland
    xkbcommon
    systemd-python
    xcffib
    python-periphery
  ]);
in
python313Packages.buildPythonPackage {
  pname = "asus-numberpad-driver";
  version = "6.8.1";
  src = ../.;

  format = "other";

  propagatedBuildInputs = with pkgs; [
    ibus
    libevdev
    curl
    xorg.xinput
    i2c-tools
    libxml2
    libxkbcommon
    libgcc
    gcc
    pythonPackages  # Python dependencies already include python313
  ];

  doCheck = false;

  # Skip build and just focus on copying files, no setuptools required
  buildPhase = ''
    echo "Skipping build phase since there's no setup.py"
  '';

  # Install files for driver and layouts
  installPhase = ''
    mkdir -p $out/share/asus-numberpad-driver

    # Copy the driver script
    cp numberpad.py $out/share/asus-numberpad-driver/

    # Copy layouts directory if it exists, and remove __pycache__ if present
    if [ -d layouts ]; then
      cp -r layouts $out/share/asus-numberpad-driver/
      rm -rf $out/share/asus-numberpad-driver/layouts/__pycache__
    fi
  '';

  meta = {
    homepage = "https://github.com/asus-linux-drivers/asus-numberpad-driver";
    description = "Linux driver for NumberPad(2.0) on Asus laptops.";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [asus-linux-drivers];
    mainProgram = "numberpad.py";
  };
}
