# bGeigie Nano firmware simulator

Single-file HTML/JS/CSS preview of what the device draws on its 128×32
OLED and writes to the serial port. No build step, no server, no
dependencies — open `index.html` in any modern browser.

```
open simulator/index.html
```

## What it shows

- **128×32 OLED panel** at 4× CSS zoom, rendered pixel-by-pixel from the
  same 5×7 Adafruit GFX font (`libraries/Adafruit_GFX/glcdfont.c`) that
  the firmware uses, so glyph shapes are bit-accurate.
- **Phase breadcrumb** across the top showing the boot-to-recording state
  machine: `SPLASH → BANNER → WAITING_GPS → WARMING → RECORDING`.
- **Live state panel** with the running `cpm`, `cpb`, `total_count`,
  `uptime`, geiger/GPS status flags, satellites, HDOP, lat/lon, distance
  and battery — for transparency about what's driving the OLED.
- **Live serial log** streaming valid `$BNRDD,...,*XX` lines (XOR
  checksum included) every 5 sim-seconds while in `RECORDING`.

## Phases (matches the firmware's startup sequence)

| Phase | Duration | Behavior |
|---|---|---|
| `SPLASH` | 1 s | Stand-in for the Safecast logo bitmap |
| `BANNER` | 3 s | Version, device ID, user name (mirrors `setup()` line 348+) |
| `WAITING_GPS` | until lock | Main display, geiger status `V` (inverted CPM), `No GPS`, no log writes |
| `WARMING` | 12 ticks × 5 s = 60 s | GPS locked, CPM shift register filling, status still `V` |
| `RECORDING` | indefinite | Full operation: status `A`, BNRDD lines stream every 5 s, dose/distance accumulate |

## Controls

- **Reset** — restart from `SPLASH`.
- **1× / 5× / 20× / 100× speed** — scale sim time. Useful to skip past
  the ~60 s warm-up. The 5-second firmware tick is preserved
  proportionally.
- **Pause** — freeze the simulation (rendering continues so you can
  inspect the current OLED state).

## What's accurate vs. what's faked

**Accurate** (matches the firmware verbatim):
- OLED pixel grid (128×32 @ 1 bit) and bitmap font.
- All cursor positions for big CPM, sat indicator, µSv/h, uptime,
  distance/altitude toggle, date, battery rectangle.
- µSv/h ↔ mSv/h auto-switch thresholds and decimal counts (matches the
  fix from commit `0d6cbc0`).
- kCPM formatting (`>=10000` 1 decimal, `>=1000` 2 decimal, else plain).
- BNRDD line format with XOR checksum, including the kit-1.0 field order
  `…,HDOP,SATELLITES` (not the upstream-Safecast regression which swaps
  them).
- Dead-time compensation (`c_p_m / (1 - c_p_m * 1.8833e-6)`).
- Device ID formatting (`%04d`).
- Geiger status `V → A` transition gated on the shift register
  filling (`strCount >= NX`).

**Approximated** (good enough for a UI preview, not pixel/physics-perfect):
- Splash screen — placeholder "SAFECAST" text in a frame; the firmware
  ships a real logo bitmap.
- CPM generation — slow-drift sine around 20–35 CPM with occasional
  spikes; not a true Poisson process.
- Distance accumulation — naive `√(Δlat² + Δlon²) × 111000` instead of
  great-circle haversine. Fine at low latitudes and small steps.
- Date/time — uses the browser's `Date.now()`, so the BNRDD timestamps
  are the wall clock, not a simulated GPS clock.
- Battery — slow random drain from 4.10 V down to 3.40 V.
- GPS seed — fixed at Tokyo (35.681, 139.767) with a small random walk.

## Why this exists

Primary use is **showing what the device does without needing one on
your desk** — for the project website, talks, workshops, blog posts, or
anyone evaluating the repo who has never seen a bGeigie. The kit is
niche hardware; an interactive preview drops the "what is this thing?"
barrier to zero.

Realistic value, ranked honestly:

- **Demo / showcase asset (~70%)** — embed in the README, the project
  website, conference slides. The phase breadcrumb makes the boot story
  explicit in a way a static photo can't.
- **Workshop / talk visual (~15%)** — drive the OLED phases live on a
  projector without bringing working units.
- **Layout sketch pad while actively reworking the OLED (~10%)** — try
  a new cursor position or field layout in 2 s instead of flashing.
  Only worth it for multi-iteration redesigns, not one-line tweaks.
- **BNRDD format reference (~5%)** — copy a line with a valid checksum
  out of the live stream when writing log parsers or upload tools.

What this is **not**:

- A firmware test or regression check. The display and BNRDD code in
  this simulator is a parallel JS reimplementation, fully separate from
  the .ino. Nothing keeps them in sync automatically — changes to one
  side don't reflect in the other until you update both.
- A radiation- or GPS-physics model. The CPM stream is a slow sine plus
  spikes and the GPS is a random walk; useful for UI motion, useless
  for measurement questions.
- Timing-faithful. The 5-second tick is wall-clock scaled, not derived
  from `millis()` semantics.
