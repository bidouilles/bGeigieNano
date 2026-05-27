# bGeigie Nano - thin wrapper around arduino-cli.
# Target: Arduino Fio (ATmega328P @ 3.3V/8MHz).
#
# Usage:
#   make deps     - one-time: install the arduino:avr core
#   make build    - compile sketch into ./build/
#   make upload   - compile + flash (auto-detects /dev/cu.usbserial-*)
#   make monitor  - serial monitor at 9600 baud
#   make hex      - copy bGeigieNano.ino.hex to ./bGeigieNano.hex (legacy name)
#   make clean    - delete ./build/
#
# Override the port:  make upload PORT=/dev/cu.usbserial-XXXX
# Override the cli:   make build  ARDUINO_CLI=/path/to/arduino-cli
#
# Libraries: the Adafruit_GFX and Adafruit_SSD1306 vendored under libraries/
# carry local mods (Safecast splash bitmap, reduced font set to fit flash) and
# are loaded via --libraries. SoftwareSerial.h/.cpp are vendored at the sketch
# root with _SS_MAX_RX_BUFF=128 so TinyGPS NMEA sentences don't overflow.

SKETCH      := bGeigieNano.ino
BUILD_DIR   := build

FQBN  := arduino:avr:fio
LIBS  := libraries

# Bump SoftwareSerial RX buffer so TinyGPS NMEA sentences don't overflow.
# The system header guards the default with #ifndef, so this -D is honored.
EXTRA_FLAGS := -D_SS_MAX_RX_BUFF=128

# Auto-detect serial port; override with PORT=... on the make command line.
# Sparkfun's FTDI basic / breakout shows up as /dev/cu.usbserial-*.
PORT ?= $(shell ls /dev/cu.usbserial-* /dev/cu.usbmodem* 2>/dev/null | head -n 1)
BAUD ?= 9600

# Prefer arduino-cli on PATH (brew install arduino-cli); fall back to the
# binary bundled inside Arduino IDE.app on macOS so things just work after
# a fresh IDE install.
ARDUINO_IDE_CLI := /Applications/Arduino IDE.app/Contents/Resources/app/lib/backend/resources/arduino-cli
ARDUINO_CLI ?= $(shell command -v arduino-cli 2>/dev/null || (test -x "$(ARDUINO_IDE_CLI)" && echo "$(ARDUINO_IDE_CLI)") || echo arduino-cli)

.PHONY: help deps build upload flash monitor hex clean

help:
	@echo "bGeigie Nano - Makefile targets"
	@echo ""
	@echo "  make deps     - install the arduino:avr core"
	@echo "  make build    - compile sketch into ./$(BUILD_DIR)/"
	@echo "  make upload   - compile + flash device (alias: make flash)"
	@echo "  make monitor  - serial monitor at $(BAUD) baud"
	@echo "  make hex      - copy compiled .hex to ./bGeigieNano.hex"
	@echo "  make clean    - remove ./$(BUILD_DIR)/"
	@echo ""
	@echo "  PORT         = $(if $(PORT),$(PORT),<none detected>)"
	@echo "  ARDUINO_CLI  = $(ARDUINO_CLI)"

deps:
	"$(ARDUINO_CLI)" core update-index
	"$(ARDUINO_CLI)" core install arduino:avr

build:
	"$(ARDUINO_CLI)" compile --fqbn "$(FQBN)" --libraries "$(LIBS)" --build-property "build.extra_flags=$(EXTRA_FLAGS)" --build-path "$(BUILD_DIR)" .

upload flash:
	@if [ -z "$(PORT)" ]; then \
		echo "ERROR: no serial port detected. Plug device in, or run: make upload PORT=/dev/cu.usbserial-XXXX"; \
		exit 1; \
	fi
	"$(ARDUINO_CLI)" compile --fqbn "$(FQBN)" --libraries "$(LIBS)" --build-property "build.extra_flags=$(EXTRA_FLAGS)" --build-path "$(BUILD_DIR)" --upload --port "$(PORT)" .

hex: build
	cp "$(BUILD_DIR)/$(SKETCH).hex" bGeigieNano.hex
	@echo "Wrote bGeigieNano.hex"

monitor:
	@if [ -z "$(PORT)" ]; then \
		echo "ERROR: no serial port detected. Plug device in, or run: make monitor PORT=/dev/cu.usbserial-XXXX"; \
		exit 1; \
	fi
	"$(ARDUINO_CLI)" monitor --port "$(PORT)" --config baudrate=$(BAUD)

clean:
	rm -rf "$(BUILD_DIR)"
