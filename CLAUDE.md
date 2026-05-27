# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Firmware for the **bGeigie Nano** — a portable radiation logger (Safecast bGeigie family) targeting the **Arduino Fio (ATmega328P @ 3.3V/8MHz)**. It reads pulses from an LND-7317 Geiger pancake via a Medcom iRover HV board, fuses with a GPS fix, renders to a 128×32 OLED, and writes `$BNRDD,...` NMEA-style sentences to an SD card via an OpenLog. The output log format is the canonical bGeigie format consumed by Safecast.

## Build & flash

`Makefile` is a thin wrapper around `arduino-cli`. It targets `arduino:avr:fio` and picks up the vendored Adafruit libs from `libraries/`. `arduino-cli` is auto-detected on `PATH`; on macOS it falls back to the binary bundled inside `Arduino IDE.app`. Same pattern as `workspace/embedded/esp32/pala-note/Makefile`.

```bash
make deps     # one-time: install arduino:avr core
make build    # compile into ./build/
make upload   # compile + flash (auto-detects /dev/cu.usbserial-*)
make monitor  # serial at 9600
make hex      # copy build/bGeigieNano.ino.hex -> ./bGeigieNano.hex
make clean
```

Override the port: `make upload PORT=/dev/cu.usbserial-XXXX`.

Flashing the prebuilt image without rebuilding:

```bash
avrdude -DV -p atmega328p -P /dev/ttyUSB0 -c arduino -b 57600 -U flash:w:bGeigieNano.hex:i
```

There is no test suite — verification is on-device (OLED + serial monitor + SD log inspection). A successful `make build` at HEAD prints ~88% flash / ~85% RAM; the toolchain warns "low memory" but that's expected for the 328P with OLED.

## SoftwareSerial RX buffer

TinyGPS needs `_SS_MAX_RX_BUFF >= 128` or NMEA sentences get truncated. The Makefile injects `-D_SS_MAX_RX_BUFF=128` via `--build-property build.extra_flags`; the system `SoftwareSerial.h` guards its default with `#ifndef`, so the override is honored without touching the Arduino install. `bGeigieNano.ino` has a `#if (_SS_MAX_RX_BUFF < 128) #error` that fires loudly if anything bypasses this.

## Architecture

**Single .ino sketch + a few helper modules.** All real logic lives in `bGeigieNano.ino`'s `loop()`; the helpers are thin.

- `bGeigieNano.ino` — main loop. Every `TIME_INTERVAL` (5 s) it: samples the free-running pulse counter and diffs against `prev_count` to get this bin's count (the hardware is never reset between reads, so no pulse is in flight when sampling — see the lost-interrupt note below), pumps GPS bytes through `TinyGPS`, advances the CPM shift register (`NX = 60000 / TIME_INTERVAL` bins → 1-min rolling window), formats a `$BNRDD,...*XX` sentence (with NMEA-style XOR checksum), writes it to OpenLog, and repaints the OLED. EEPROM dose is persisted hourly.
- `NanoConfig.h` — **the central feature-flag header**. Compile-time `#define ENABLE_*` switches select pulse-counter type, OLED, GPS chipset (MediaTek vs SkyTraq), 100 m coordinate truncation, EEPROM dose, dead-time compensation, geigie-type switch (bGeigie vs xGeigie), pin map (`ENABLE_NANOKIT_PIN`), etc. **Pin assignments and feature compilation are driven from here** — read this file first before changing wiring or behavior. Note: enabling `ENABLE_SSD1306` force-disables `ENABLE_DEBUG` (RAM pressure on the 328P).
- `NanoSetup.{h,cpp}` — `ConfigType`/`DoseType` structs persisted in EEPROM at fixed offsets (`BMRDD_EEPROM_SETUP=500`, `BMRDD_EEPROM_DOSE=200`), guarded by a `BMRDD_EEPROM_MARKER` magic. `loadFromFile()` parses `SAFECAST.TXT` from the SD card via the OpenLog to override config (user name, device id, timezone, CPM factor, alarm level, sensor type/shield/height, etc.). EEPROM dose is rewritten ~hourly to spread the ~100k-cycle wear over years.
- `InterruptCounter.{h,cpp}` / `HardwareCounter.{h,cpp}` — two interchangeable pulse-counting backends selected by `ENABLE_HARDWARE_COUNTER`. Default is interrupt-driven on D2 (`INT0`); the hardware variant uses Timer1's external clock on D5. Both expose a `COUNTER_TYPE` typedef (`unsigned int`) and a `count()` that resets only the *sampling window timer*, not the count itself — the main loop derives this bin's count by diffing against its previous read.
- `TinyGPS.{h,cpp}` — vendored Mikal Hart TinyGPS. Driven over `SoftwareSerial` (pins `GPS_RX_PIN`/`GPS_TX_PIN`).
- `libraries/` — vendored Adafruit GFX + SSD1306 (modified: Safecast logo bitmap and reduced font set to fit in 32 KB flash). `arduino-cli` loads them via `--libraries libraries`; no copying into the system install needed.
- `sample/` — example SD card contents: `CONFIG.TXT` (OpenLog config: `9600,26,3,2`), `SAFECAST.TXT` (user config parsed by `NanoSetup::loadFromFile`), and a real `*.LOG` showing the `$BNRDD` output format.

## Things that bite

- **It's an ATmega328P** (32 KB flash, 2 KB RAM). At HEAD the sketch uses ~88% flash and ~85% RAM. Adding features means watching the size report. Strings live in flash via `F("...")`; don't accidentally pull them into RAM. `ENABLE_DEBUG` and `ENABLE_SSD1306` together overflow — the config header enforces this.
- **Lost-interrupt fix is load-bearing.** Counter reads must use the delta pattern (`cpb = this_count - prev_count`); never reset the hardware between samples or pulses arriving in the window will be dropped. Unsigned subtraction is correct across one `COUNTER_TYPE` wrap.
- **OpenLog is a SoftwareSerial peer**, not SPI. It needs to be in command mode at 9600 bps (`CONFIG.TXT = 9600,26,3,2`). Reset is wired to `OPENLOG_RST_PIN` and toggled at startup. `nanoSetup.loadFromFile()` tolerates both CR and LF terminators in `SAFECAST.TXT`.
- **Two pin maps coexist** in `NanoConfig.h` (v1.0.0 interrupt, v1.0.1 hardware-counter, and the current nano-kit layout). The active one is gated by `ENABLE_NANOKIT_PIN` / `ENABLE_HARDWARE_COUNTER`. Reference build is the **nano kit 1.0** layout. The Safecast PCB-kit variant (`ENABLE_NANOPCBKIT_PIN`, alarm/custom-fn LEDs on different pins, `VOLTAGE_PIN A0`, `GEIGIE_TYPE_PIN A5`, a `*10` voltage scale, etc.) is deliberately **not** ported here — it targets different hardware.
- **CPM → uSv/h conversion** uses `NANO_CPM_FACTOR=334` (LND-7317 default) and is overridable via `SAFECAST.TXT` `cpmf=`. Dead-time compensation for the LND7317 is enabled by `ENABLE_LND_DEADTIME`.
- **Log filename is 8.3.** Generated from device ID; the sketch fails silently to write if the OpenLog isn't ready, so check the OLED status char (`A` = available, `V` = void) when debugging.
- **BNRDD format is `…,HDOP,SATELLITES`.** The upstream Safecast/Ray PR swaps these — that's a regression vs. the Safecast spec and is intentionally not pulled. Don't "fix" it.
