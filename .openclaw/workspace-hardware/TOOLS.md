# Hardware Tools Notes

## Dev Environment

- Primary workspace: `${LACROSSE_APP_PATH}/hardware/`
- Firmware source: `hardware/firmware/laxpod/`
- Board: Seeed XIAO nRF52840 Sense
- BSP: Adafruit nRF52 (Seeed variant) via Arduino Board Manager or PlatformIO

## Common Commands

### PlatformIO (preferred)
```bash
cd hardware/firmware
pio run                          # Compile
pio run --target upload          # Flash via USB-C
pio device monitor -b 115200    # Serial monitor
pio run --target clean           # Clean build
```

### Arduino IDE (fallback)
1. File → Preferences → Additional Board Manager URLs:
   `https://files.seeedstudio.com/arduino/package_seeeduino_boards_index.json`
2. Tools → Board Manager → search "Seeed nRF52" → install
3. Tools → Board → "Seeed XIAO nRF52840 Sense"
4. Sketch → Upload (USB-C cable required)
5. Tools → Serial Monitor → 115200 baud

### Fusion 360 (manual CAD — not scriptable)
- Follow `hardware/enclosure/README.md` step-by-step guide
- Export: File → 3D Print → STL (high resolution)
- Save .f3d for future modifications

### SLA Printing
- Material: Rigid 10K resin (or Tough 2000 for flex testing)
- Layer height: 0.05mm
- Post-cure: 60 minutes UV at 60°C
- Xometry upload: https://www.xometry.com/ → Instant Quote → upload STL

### Testing
```bash
# Use nRF Connect mobile app (iOS/Android) for BLE debugging
# Verify BLE service discovery, characteristic values, notification subscription
```

## Library Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| LSM6DS3 (Seeed) | latest | IMU driver (accel + gyro) |
| Adafruit Bluefruit nRF52 | latest | BLE stack |
| MadgwickAHRS | latest | Quaternion sensor fusion |

## Hardware Specs Quick Reference

| Parameter | Value |
|-----------|-------|
| MCU | nRF52840 (64MHz Cortex-M4F) |
| Flash | 1MB |
| RAM | 256KB |
| BLE | 5.0, +8 dBm TX |
| IMU | LSM6DS3 (onboard XIAO Sense) |
| Battery | 300mAh 3.7V LiPo |
| Charge IC | BQ25101 (onboard XIAO) |
| Board size | 21 × 17.8 mm |
| USB | USB-C (flash + charge) |

## Pin Mapping (XIAO nRF52840 Sense)

| Function | Pin |
|----------|-----|
| IMU I2C SDA | P0.04 (built-in) |
| IMU I2C SCL | P0.05 (built-in) |
| Battery ADC | P0.31 (VBAT/2 divider) |
| LED Red | P0.26 (LED_RED) |
| LED Green | P0.30 (LED_GREEN) |
| LED Blue | P0.06 (LED_BLUE) |
| Button | P1.14 (onboard) |
| Charge detect | P0.17 |

## Environment Variables
- No secrets needed for firmware — all config is in `config.h`
- For ordering: browser automation handles supplier carts directly

## Supplier Links
- XIAO nRF52840 Sense: https://www.seeedstudio.com/Seeed-XIAO-BLE-Sense-nRF52840-p-5253.html
- Xometry SLA prints: https://www.xometry.com/
- JLCPCB (Phase 2 only): https://jlcpcb.com/
