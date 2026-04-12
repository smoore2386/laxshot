# LaxPod Hardware Project

Hardware design, firmware, and documentation for the LaxPod lacrosse stick motion sensor pod.

## Overview

The LaxPod is a compact sensor plug that inserts inside the butt end of a lacrosse shaft, acting as a game-legal replacement end cap. It streams real-time motion data (accelerometer, gyroscope, 3D orientation) via BLE to the LaxShot mobile app for shot analysis and coaching.

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
├── pcb/                   ← Phase 2 custom PCB design
│   └── README.md          ← KiCad shrink guide (18×12mm board)
├── enclosure/             ← 3D-printed enclosure design
│   ├── README.md          ← Fusion 360 step-by-step guide
│   └── print_settings.md  ← SLA print parameters
├── bom/                   ← Bill of Materials
│   ├── phase1_bom.md      ← Phase 1 BOM (5 units, XIAO dev board)
│   ├── phase1_bom.csv     ← Phase 1 spreadsheet BOM
│   ├── phase2_bom.md      ← Phase 2 BOM (100 units, custom PCB)
│   └── phase2_bom.csv     ← Phase 2 spreadsheet BOM
├── assembly/              ← Build instructions
│   ├── assembly_guide.md  ← Step-by-step assembly
│   └── test_protocol.md   ← 9-step verification protocol
├── docs/                  ← Technical documentation
│   ├── ble_protocol.md    ← BLE protocol spec (integration contract)
│   └── architecture.md    ← System block diagram + data flow
└── README.md              ← This file
```

## Quick Start

### Phase 1 — Prototype (5 units, off-the-shelf XIAO)

1. **Order parts** — see [bom/phase1_bom.md](bom/phase1_bom.md)
2. **Design enclosure** — follow [enclosure/README.md](enclosure/README.md) in Fusion 360
3. **Print enclosure** — see [enclosure/print_settings.md](enclosure/print_settings.md)
4. **Flash firmware** — see [firmware/README.md](firmware/README.md)
5. **Assemble** — follow [assembly/assembly_guide.md](assembly/assembly_guide.md)
6. **Test** — run [assembly/test_protocol.md](assembly/test_protocol.md)

### Phase 2 — Production (100 units, custom PCB)

1. **Design custom PCB** — follow [pcb/README.md](pcb/README.md) (KiCad shrink guide)
2. **Order PCBs** — JLCPCB turnkey, see [bom/phase2_bom.md](bom/phase2_bom.md)
3. **Port firmware** — update IMU driver (LSM6DSV16X) + pin mapping
4. **Update enclosure** — see Phase 2 section in [enclosure/README.md](enclosure/README.md)
5. **Flash via SWD** — Tag-Connect or pogo jig
6. **Assemble + test** — same protocol, shorter plug

## Phase 1 Specs (Prototype — XIAO Dev Board)

| Parameter | Value |
|-----------|-------|
| Platform | Seeed XIAO nRF52840 Sense |
| Board size | 21 × 17.8mm |
| IMU | LSM6DS3 (±16g accel, ±2000°/s gyro) @ 416Hz |
| Wireless | BLE 5.0, +8 dBm TX |
| Battery | 300mAh 3.7V LiPo (men's) / 150mAh (women's) |
| Enclosure | SLA Rigid 10K resin |
| Size | 65mm L × 21.5mm OD (men's plug) |
| Weight | < 0.4 oz with electronics |
| Shaft fit | Men's 1.000" OD shaft / Women's 0.875" OD shaft (plug inserts inside) |
| Battery life | 20+ hours active use, 25+ days standby |

## Phase 2 Specs (Production — Custom PCB)

| Parameter | Value |
|-----------|-------|
| Platform | Custom PCB with Fanstel BM840P (nRF52840 module) |
| Board size | **18 × 12mm** |
| IMU | LSM6DSV16X (±16g accel, ±2000°/s gyro, lower noise) |
| Wireless | BLE 5.4, +8 dBm TX, pre-certified FCC/CE |
| Battery | 300mAh 3.7V LiPo (**same for both men's and women's**) |
| Charging | Pogo pads through endcap (no USB-C) |
| Enclosure | SLA or injection-molded |
| Size | **50mm L** × 21.5mm OD (men's) / 18.5mm OD (women's) |
| Weight | < 0.3 oz with electronics |
| Unit cost (100 qty) | ~$17.50 fully assembled |
| Unit cost (1k qty) | ~$12.55 |

## Prototype Quantities

### Phase 1

- 3× Men's (1" shaft, 21.5mm plug)
- 2× Women's (7/8" shaft, 18.5mm plug)
- **Total: 5 units, ~$237 BOM cost**

### Phase 2

- 100× custom PCBs (JLCPCB turnkey assembly)
- 50× men's enclosures + 50× women's enclosures (adjust split as needed)
- **Total: 100 units, ~$17.50/unit (~$1,750 BOM cost)**

## Cross-Agent Integration

- **BLE Protocol:** [docs/ble_protocol.md](docs/ble_protocol.md) — shared with FrontClaw for Flutter integration
- **Firestore Schema:** Defined in BLE protocol doc — shared with Laxback for backend rules
- **App Feature:** `lib/features/sensor/` in the Flutter app — owned by FrontClaw
