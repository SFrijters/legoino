SHELL=/usr/bin/env bash
# This may need to be changed, based on the output of `arduino-cli board list`.
# Need permission to access this device, you may need to `sudo usermod -a -G dialout <username>`.
SERIAL=/dev/ttyACM0
# This should be in sync with whatever you set in the sketch via `Serial.begin(xxx);` (if you set it at all).
BAUDRATE=115200
FQBN=esp32:esp32:XIAO_ESP32C3

ROOT_DIR:=$(shell pwd)
SKETCH_NAME:=$(shell basename $(ROOT_DIR))

_ARDUINO_ROOT_DIR=/tmp/arduino/
_ARDUINO_PROJECT_DIR=$(_ARDUINO_ROOT_DIR)/$(SKETCH_NAME)

.PHONY: all compile upload monitor clean

all: compile upload

compile:
	arduino-cli compile -v \
	--fqbn "$(FQBN)" \
	--build-property "compiler.cpp.extra_flags=$(EXTRA_FLAGS)" \
	--build-path "$(_ARDUINO_PROJECT_DIR)/build/$(SKETCH_NAME)" \
	--output-dir "$(ROOT_DIR)/output"

upload:
	[ -e $(SERIAL) ] && \
	arduino-cli upload \
	--fqbn "$(FQBN)" \
	--input-dir "$(ROOT_DIR)/output" \
	-p $(SERIAL) \
	-v || \
	{ echo "==> $(SERIAL) is not available"; exit 1; }

# Monitor the serial output.
# The --imap option maps '\n' to '\r\n' so newlines are newlines.
monitor:
	picocom -b $(BAUDRATE) --imap lfcrlf $(SERIAL)

clean:
	rm -rf "$(ROOT_DIR)/output"
	rm -rf "$(_ARDUINO_PROJECT_DIR)/build/$(SKETCH_NAME)"
