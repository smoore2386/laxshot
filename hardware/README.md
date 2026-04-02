# LaxPod Hardware Project

Hardware design, firmware, and documentation for the LaxPod lacrosse stick motion sensor pod.

## Overview

The LaxPod is a compact sensor pod that replaces the standard butt cap on a lacrosse shaft. It streams real-time motion data (accelerometer, gyroscope, 3D orientation) via BLE to the LaxShot mobile app for shot analysis and coaching.

## Project Structure

```
hardware/
├── firmware/              ← Embedded firmware (nRF52840)
│   ├── platformio.ini     ← Build configuration
│   ├── README.md          ← Build & flash instructions
│   └── laxpod/            ← Source code
│       ├── laxpod.ino     ← Main sketch
│       ├── config.h       ← Configuration (UUIDs, thresholds, pins)
│       ├── imu.h/.cpp     ← IMU driver
│       ├── ble.h/.cpp     ← BLE service
│       ├── shot.h/.cpp    ← Shot detection + quaternion fusion
│       └── power.h/.cpp   ← Power management + LEDs
├── enclosure/             ← 3D-printed enclosure design
│   ├── README.md          ← Fusion 360 step-by-step guide
│   └── print_settings.md  ← SLA print parameters
├── bom/                   ← Bill of Materials
│   ├── phase1_bom.md      ← Human-readable BOM (5 units)
│   └── phase1_bom.csv     ← Spreadsheet-importable BOM
├── assembly/              ← Build instructions
│   ├── assembly_guide.md  ← Step-by-step assembly
│   └── test_protocol.md   ← 9-step verification protocol
├── docs/                  ← Technical documentation
│   ├── ble_protocol.md    ← BLE protocol spec (integration contract)
│   └── architecture.md    ← System block diagram + data flow
└── README.md              ← This file
```

## Quick Start

1. **Order parts** — see [bom/phase1_bom.md](bom/phase1_bom.md)
2. **Design enclosure** — follow [enclosure/README.md](enclosure/README.md) in Fusion 360
3. **Print enclosure** — see [enclosure/print_settings.md](enclosure/print_settings.md)
4. **Flash firmware** — see [firmware/README.md](firmware/README.md)
5. **Assemble** — follow [assembly/assembly_guide.md](assembly/assembly_guide.md)
6. **Test** — run [assembly/test_protocol.md](assembly/test_protocol.md)

## Phase 1 Specs

| Parameter | Value |
|-----------|-------|
| Platform | Seeed XIAO nRF52840 Sense |
| IMU | LSM6DS3 (±16g accel, ±2000°/s gyro) @ 416Hz |
| Wireless | BLE 5.0, +8 dBm TX |
| Battery | 300mAh 3.7V LiPo |
| Enclosure | SLA Rigid 10K resin |
| Size | 1.6" L × 1.25" OD |
| Weight | < 0.4 oz with electronics |
| Shaft fit | Men's 1.000" OD / Women's 0.875" OD |
| Battery life | 20+ hours active use, 25+ days standby |

## Prototype Quantities

- 3× Men's (1" bore)
- 2× Women's (7/8" bore)
- **Total: 5 units, ~$280 BOM cost**

## Cross-Agent Integration

- **BLE Protocol:** [docs/ble_protocol.md](docs/ble_protocol.md) — shared with FrontClaw for Flutter integration
- **Firestore Schema:** Defined in BLE protocol doc — shared with Laxback for backend rules
- **App Feature:** `lib/features/sensor/` in the Flutter app — owned by FrontClaw
