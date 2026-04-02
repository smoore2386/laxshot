# LaxPod Firmware

Firmware for the LaxPod lacrosse stick sensor pod. Runs on the Seeed XIAO nRF52840 Sense.

## Features

- **IMU sampling** at 416Hz (accelerometer ±16g + gyroscope ±2000 dps)
- **Shot detection** — triggers when peak acceleration exceeds 8g
- **3D orientation** — Madgwick quaternion fusion updated every frame
- **BLE streaming** — 48-byte motion packets at 200Hz (during shots) or 10Hz (idle)
- **Auto-sleep** — deep sleep after 5 minutes of inactivity, wake on motion
- **LED status** — blue (advertising), green (connected), red (low battery)
- **Battery monitoring** — percentage reported via BLE packet + standard Battery Service

## Project Structure

```
firmware/
├── platformio.ini          ← PlatformIO build config
├── README.md               ← This file
└── laxpod/
    ├── laxpod.ino          ← Main sketch
    ├── config.h            ← Pin defs, thresholds, BLE UUIDs
    ├── imu.h / imu.cpp     ← LSM6DS3 driver wrapper
    ├── ble.h / ble.cpp     ← BLE service + characteristics
    ├── shot.h / shot.cpp   ← Shot detection + Madgwick fusion
    └── power.h / power.cpp ← Sleep/wake + LED + battery
```

## Build & Flash

### Option A: PlatformIO (recommended)

```bash
cd hardware/firmware

# Install PlatformIO CLI if needed
pip install platformio

# Build
pio run

# Flash via USB-C
pio run --target upload

# Serial monitor (115200 baud)
pio device monitor -b 115200
```

### Option B: Arduino IDE

1. Open Arduino IDE
2. File → Preferences → Additional Board Manager URLs:
   ```
   https://files.seeedstudio.com/arduino/package_seeeduino_boards_index.json
   ```
3. Tools → Board Manager → search "Seeed nRF52" → install **Seeed nRF52 Boards** (latest)
4. Tools → Board → **Seeed XIAO nRF52840 Sense**
5. Install libraries via Library Manager:
   - `Seeed Arduino LSM6DS3`
   - `MadgwickAHRS`
6. Open `laxpod/laxpod.ino`
7. Sketch → Upload (connect XIAO via USB-C)
8. Tools → Serial Monitor → 115200 baud

## BLE Protocol

See [../docs/ble_protocol.md](../docs/ble_protocol.md) for the full BLE service/characteristic specification.

**Quick reference:**
- Device name: `LaxPod`
- Motion service: `4C415801-...`
- Motion characteristic: `4C415802-...` (48 bytes, notify)
- Packet: `float32[3] accel + float32[3] gyro + float32[4] quat + uint8 batt + uint8 flags + uint32 timestamp + uint16 reserved`

## Serial Output

When connected via USB, the firmware outputs debug info:

```
========================================
LaxPod Firmware v0.1.0
========================================
[IMU] Initialized — 416 Hz, ±16g, ±2000 dps
[SHOT] Initialized — sample rate: 416.00 Hz
[BLE] Initialized — services registered
[BLE] Advertising started
[MAIN] Setup complete — advertising as LaxPod
[MAIN] Battery: 87%
[BLE] Connected — handle: 0
[MAIN] Central connected — streaming enabled
[SHOT] Detected! accel=12.45g
[SHOT] Complete #1 — peak: 14.72g, duration: 487ms
[MAIN] Shot #1 — peak: 14.72g
```

## Hardware

- **Board:** Seeed XIAO nRF52840 Sense
- **IMU:** LSM6DS3 (onboard)
- **BLE:** nRF52840 radio, +8 dBm TX power
- **Battery:** 300mAh 3.7V LiPo via JST-PH 2.0mm connector
- **Charging:** USB-C (onboard BQ25101 charger IC)

## Troubleshooting

| Problem | Fix |
|---------|-----|
| IMU init fails | Check I2C address 0x6A — try 0x6B if custom board |
| BLE not advertising | Verify Bluefruit library is installed, check serial output |
| No serial output | Wait 2s after reset, check baud rate is 115200 |
| Won't flash | Double-tap reset button to enter bootloader (drive appears as USB mass storage) |
| Battery reads 0% | Check VBAT pin connection — JST connector must be wired correctly |
