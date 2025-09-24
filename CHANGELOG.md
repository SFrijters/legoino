# Changelog

## 1.2.4

* Re-release of 1.2.3 with updated Nix support and removal of large package-index files from the repository.

## 1.2.3

[[ Release pulled due to large committed files ]]

* Fix compilation errors at high values of `CORE_DEBUG_LEVEL`. (@carlalldis)
* Tweak Nix support

## 1.2.2

[[ Release pulled due to large committed files ]]

* Add [Nix](https://nixos.org) support to the examples and add it to CI.

## 1.2.1

* Fix esp32:esp32:m5stack_atom tests
* Minor CI / code / README cleanups.

## 1.2.0

* Add support for [NimBLE-Arduino versions 2.x](https://github.com/h2zero/NimBLE-Arduino/releases/tag/2.1.0), which has some breaking API changes.
* Fix missing header for ESP 3.x .
* Fix int type mismatch for esp32:esp32:XIAO_ESP32C3 platform.
* Integrate changes from https://github.com/Rbel12b/legoino fork.
