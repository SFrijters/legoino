SHELL=/usr/bin/env bash
# This may need to be changed, based on the output of `arduino-cli board list`.
# Need permission to access this device, you may need to `sudo usermod -a -G dialout <username>`.
SERIAL=/dev/ttyUSB0
# This should be in sync with whatever you set in the sketch via `Serial.begin(xxx);` (if you set it at all).
BAUDRATE=115200
# Set debug level to test log_d macros.
# DebugLevel taken from the output of arduino-cli board details --fqbn <base fqbn>
# See https://forum.arduino.cc/t/example-of-core-log-level-using-compile-sketch-github-action/1036161
FQBN=esp32:esp32:XIAO_ESP32C3:DebugLevel=verbose

VERBOSE=

ROOT_DIR:=$(shell pwd)
SKETCH_NAME:=$(shell basename $(ROOT_DIR))

COMPILER_CPP_EXTRA_FLAGS:=$(shell test -e $(ROOT_DIR)/compiler.cpp.extra_flags && cat $(ROOT_DIR)/compiler.cpp.extra_flags)

_ARDUINO_ROOT_DIR=/tmp/arduino/
_ARDUINO_PROJECT_DIR=$(_ARDUINO_ROOT_DIR)/$(SKETCH_NAME)
_ARDUINO_BUILD_DIR=$(_ARDUINO_PROJECT_DIR)/build/$(SKETCH_NAME)
_ARDUINO_OUTPUT_DIR=$(_ARDUINO_PROJECT_DIR)/bin/$(SKETCH_NAME)

.PHONY: all compile upload monitor clean

all: compile upload

compile:
	arduino-cli compile "$(VERBOSE)" \
	--fqbn "$(FQBN)" \
	--build-property "compiler.cpp.extra_flags=$(COMPILER_CPP_EXTRA_FLAGS)" \
	--build-path "$(_ARDUINO_BUILD_DIR)" \
	--output-dir "$(_ARDUINO_OUTPUT_DIR)"

upload:
	[ -e "$(SERIAL)" ] && \
	arduino-cli upload \
	--fqbn "$(FQBN)" \
	--input-dir "$(_ARDUINO_OUTPUT_DIR)" \
	-p "$(SERIAL)" \
	-v || \
	{ echo "==> $(SERIAL) is not available"; exit 1; }

# Monitor the serial output.
# The --imap option maps '\n' to '\r\n' so newlines are newlines.
monitor:
	picocom -b "$(BAUDRATE)" --imap lfcrlf "$(SERIAL)"

clean:
	rm -rf "$(_ARDUINO_OUTPUT_DIR)"
	rm -rf "$(_ARDUINO_BUILD_DIR)"
