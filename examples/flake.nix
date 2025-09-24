{
  description = "Wrapper for Legoino tests using nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    arduino-nix.url = "github:bouk/arduino-nix";
    arduino-indexes = {
      url = "github:bouk/arduino-indexes";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      arduino-nix,
      arduino-indexes,
    }:
    let
      inherit (nixpkgs) lib;

      # Boilerplate to make the rest of the flake more readable
      # Do not inject system into these attributes
      flatAttrs = [
        "overlays"
        "nixosModules"
      ];
      # Inject a system attribute if the attribute is not one of the above
      injectSystem =
        system:
        lib.mapAttrs (name: value: if lib.elem name flatAttrs then value else { ${system} = value; });
      # Combine the above for a list of 'systems'
      forSystems =
        systems: f:
        lib.attrsets.foldlAttrs (
          acc: system: value:
          lib.attrsets.recursiveUpdate acc (injectSystem system value)
        ) { } (lib.genAttrs systems f);
    in
    # Maybe other systems work as well, but they have not been tested
    forSystems
      [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs { inherit system overlays; };

          overlays = [
            arduino-nix.overlay
            # https://downloads.arduino.cc/packages/package_index.json
            (arduino-nix.mkArduinoPackageOverlay "${arduino-indexes}/index/package_index.json")
            # https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
            (arduino-nix.mkArduinoPackageOverlay "${arduino-indexes}/index/package_esp32_index.json")
            # https://downloads.arduino.cc/libraries/library_index.json
            (arduino-nix.mkArduinoLibraryOverlay "${arduino-indexes}/index/library_index.json")
          ];

          arduinoCliShell =
            let
              Legoino = pkgs.stdenv.mkDerivation {
                name = "Legoino";
                src = lib.fileset.toSource {
                  root = ../.;
                  fileset = lib.fileset.unions [
                    ./../LICENSE
                    ./../platformio.ini
                    ./../keywords.txt
                    ./../library.properties
                    ./../README.md
                    ./../src
                  ];
                };

                postInstall = ''
                  mkdir -p $out/libraries/Legoino/
                  mv * $out/libraries/Legoino/
                '';
              };

              # https://github.com/h2zero/NimBLE-Arduino
              NimBLE-Arduino = pkgs.fetchFromGitHub {
                name = "nimble-arduibo-h2zero-patched";
                owner = "h2zero";
                repo = "NimBLE-Arduino";
                tag = "2.2.3";
                hash = "sha256-FXAj3E/u1ZvzU1rxeDQ5xZLOIz00bkniJ35YAXTNOG8=";
                postFetch = ''
                  # Allow more connections
                  substituteInPlace $out/src/nimconfig.h \
                    --replace-fail "// #define CONFIG_BT_NIMBLE_MAX_CONNECTIONS 3" "#define CONFIG_BT_NIMBLE_MAX_CONNECTIONS 8"

                  mkdir -p $out/libraries/NimBLE-Arduino/
                  mv $out/* $out/libraries/NimBLE-Arduino/ || true
                '';
              };

              gnumake-wrapper = pkgs.writeShellApplication {
                name = "make";
                text = ''
                  ${lib.getExe pkgs.gnumake} --file=${./Makefile} "$@"
                '';
              };

              arduino-cli-with-packages = pkgs.wrapArduinoCLI {
                libraries = [
                  Legoino
                  NimBLE-Arduino
                ];

                packages = [
                  pkgs.arduinoPackages.platforms.esp32.esp32."3.3.0"
                ];
              };

              name = "legoino-examples-esp32c3-arduino-cli";
            in
            pkgs.mkShellNoCC {
              inherit name;

              packages = with pkgs; [
                arduino-cli-with-packages
                gnumake-wrapper
                picocom # To monitor the serial output
                python3
              ];

              # The variables starting with underscores are custom and not used by arduino-cli directly
              # The _ARDUINO_PROJECT_DIR variable is passed to arduino-cli via the Makefile.
              shellHook = ''
                if [ -z "''${_ARDUINO_PROJECT_DIR:-}" ]; then
                  if [ -n "''${_ARDUINO_ROOT_DIR:-}" ]; then
                    export _ARDUINO_PROJECT_DIR="''${_ARDUINO_ROOT_DIR}/${name}"
                  elif [ -n "''${XDG_CACHE_HOME:-}" ]; then
                    export _ARDUINO_PROJECT_DIR="''${XDG_CACHE_HOME}/arduino/${name}"
                  else
                    export _ARDUINO_PROJECT_DIR="''${HOME}/.arduino/${name}"
                  fi
                fi
              '';
            };
        in
        {
          devShells.default = arduinoCliShell;

          formatter = pkgs.nixfmt-tree;
        }
      );
}
