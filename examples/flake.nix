{
  description = "Wrapper for Legoino tests using nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    arduino-nix.url = "github:bouk/arduino-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      arduino-nix,
    }:
    let
      inherit (nixpkgs) lib;

      overlays = [
        arduino-nix.overlay
        # https://downloads.arduino.cc/packages/package_index.json
        (arduino-nix.mkArduinoPackageOverlay ./package-index/package_index.json)
        # https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
        (arduino-nix.mkArduinoPackageOverlay ./package-index/package_esp32_index.json)
        # https://downloads.arduino.cc/libraries/library_index.json
        (arduino-nix.mkArduinoLibraryOverlay ./package-index/library_index.json)
      ];

      forAllSystems =
        function:
        lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-darwin"
          ]
          (
            system:
            function (
              import nixpkgs {
                inherit system overlays;
              }
            )
          );

      arduinoCliShell =
        pkgs:
        let
          # https://github.com/SFrijters/legoino -> https://github.com/corneliusmunz/legoino
          Legoino = pkgs.fetchFromGitHub {
            name = "legoino-sfrijters";
            owner = "SFrijters";
            repo = "legoino";
            tag = "1.2.1";
            hash = "sha256-+EMk5Lga+gpmXiNKzV1UH9MdloBqS0jWNzsO5HQlDIg=";
            postFetch = ''
              mkdir -p $out/libraries/Legoino/
              mv $out/* $out/libraries/Legoino/ || true
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
              pkgs.arduinoPackages.platforms.esp32.esp32."3.1.3"
            ];
          };

          name = "legoino-examples-esp32c3-arduino-cli";
        in
        pkgs.mkShell {
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
      devShells = forAllSystems (pkgs: {
        default = arduinoCliShell pkgs;
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
