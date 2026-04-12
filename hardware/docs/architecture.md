# LaxPod Hardware Architecture

## System Block Diagram

```
┌─────────────────────────────────────────────┐
│              LaxPod Sensor Pod              │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │     Seeed XIAO nRF52840 Sense       │   │
│  │                                      │   │
│  │  ┌─────────┐    ┌──────────────┐    │   │
│  │  │ nRF52840│    │   LSM6DS3    │    │   │
│  │  │  MCU    │◄──►│  IMU (I2C)   │    │   │
│  │  │         │    │ ±16g / ±2000°│    │   │
│  │  │  BLE    │    └──────────────┘    │   │
│  │  │  5.0    │                        │   │
│  │  │ +8dBm   │    ┌──────────────┐    │   │
│  │  │         │◄───│  BQ25101     │    │   │
│  │  │  USB-C  │    │  Charger IC  │    │   │
│  │  └─────────┘    └──────┬───────┘    │   │
│  │                        │            │   │
│  └────────────────────────┼────────────┘   │
│                           │                │
│  ┌────────────────────────┼────────────┐   │
│  │    300mAh 3.7V LiPo   │            │   │
│  │    (402025 form)    ◄──┘            │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────┐  ┌──────┐  ┌────────────┐    │
│  │ RGB LED │  │Button│  │ O-ring     │    │
│  │ Status  │  │ Pair │  │ Grip       │    │
│  └─────────┘  └──────┘  └────────────┘    │
│                                             │
│  Enclosure: SLA Rigid 10K Resin            │
│  65mm L × 21.5mm OD plug (inside shaft)   │
└─────────────────────────────────────────────┘
          │
          │  BLE 5.0 (~30m range)
          │  48-byte motion packets
          ▼
┌─────────────────────────────────────────────┐
│            LaxShot Mobile App               │
│                                             │
│  ┌──────────────┐    ┌──────────────────┐  │
│  │ flutter_blue  │    │  Sensor Feature  │  │
│  │  _plus       │───►│  Module          │  │
│  │ (BLE driver) │    │  - Live display  │  │
│  └──────────────┘    │  - Shot capture  │  │
│                      │  - Session mgmt  │  │
│                      └────────┬─────────┘  │
│                               │            │
│                      ┌────────▼─────────┐  │
│                      │ Firestore Write  │  │
│                      │ sensorSessions/  │  │
│                      └────────┬─────────┘  │
└───────────────────────────────┼─────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────┐
│             Firebase Backend                │
│                                             │
│  Firestore: users/{uid}/sensorSessions/     │
│  Cloud Functions: aggregateSensorStats      │
└─────────────────────────────────────────────┘
```

## Data Flow

1. **IMU → Firmware**: LSM6DS3 sampled at 416Hz via I2C
2. **Firmware → Madgwick**: Raw accel+gyro → quaternion orientation
3. **Firmware → Shot Detector**: Accel magnitude > 8g → shot event
4. **Firmware → BLE**: 48-byte packet at 200Hz (shot) or 10Hz (idle)
5. **BLE → Flutter**: `flutter_blue_plus` subscribes to notifications
6. **Flutter → Firestore**: Session summary + shot array on session end
7. **Cloud Function → Stats**: Daily aggregation of sensor session data

## Power Budget

| State | Current Draw | Duration | Energy |
|-------|-------------|----------|--------|
| Deep Sleep | ~3µA | Overnight / idle | Negligible |
| Advertising (no connection) | ~0.5mA | Between sessions | Low |
| Connected, idle (10Hz notify) | ~3mA | Between shots | Medium |
| Connected, shot (200Hz notify) | ~8mA | During swing (~0.5s) | Brief |
| Peak (BLE TX + IMU) | ~15mA | Burst | Very brief |

**Estimated battery life (300mAh):**
- Continuous connected idle: ~100 hours
- Active practice session (100 shots/hr): ~20+ hours
- Standby (advertising): ~25 days
- Deep sleep: ~years (negligible drain)

## Enclosure Cross-Section (Plug Inside Shaft)

```
    ┌──────────────────────────────────┐
    │          LACROSSE SHAFT          │ ← Shaft wall (aluminum/carbon)
    │  ┌────────────────────────────┐  │
    │  │ ╔══╗              ╔══╗    │  │ ← O-ring grooves (×2)
    │  │ ║OR║              ║OR║    │  │   1.5mm wide × 1.0mm deep
    │  │ ╚══╝              ╚══╝    │  │
    │  │                           │  │
    │  │     [    LiPo    ]        │  │ ← Battery pocket
    │  │     [ 402025/401730 ]     │  │   Men's: 20×25×4mm
    │  │                           │  │   Women's: 17×30×3.5mm
    │  │     ┌────────────┐        │  │
    │  │     │   XIAO     │        │  │ ← Board on rail cradle
    │  │     │ nRF52840   │        │  │   17.8mm wide, M1.6 standoffs
    │  │     │  Sense     │        │  │
    │  │     └────────────┘        │  │
    │  │  ┌──────────────────────┐ │  │
    │  │  │  [BTN]    [LED]     │ │  │ ← Endcap face (visible)
    │  └──┴──────────────────────┴─┘  │   3mm button + 4mm LED window
    │        ↑ Butt end of stick      │   1mm dome, flush with shaft end
    └──────────────────────────────────┘

    Plug OD: Men's 21.5mm / Women's 18.5mm
    Shaft ID: Men's ~22mm / Women's ~19mm
    Total plug length: ~65mm (~2.56")
```

## Phase 2 Architecture (Custom 18×12mm PCB)

Phase 2 replaces the off-the-shelf XIAO nRF52840 Sense with a custom 18×12mm PCB. The core circuit is identical (nRF52840 + IMU + LiPo charger) but smaller and cheaper at scale.

### Phase 2 Block Diagram

```
┌─────────────────────────────────────────────┐
│           LaxPod Sensor Pod (v2)            │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │     Custom PCB (18 × 12mm)          │   │
│  │                                      │   │
│  │  ┌───────────┐  ┌──────────────┐    │   │
│  │  │ BM840P    │  │ LSM6DSV16X   │    │   │
│  │  │ nRF52840  │◄►│  IMU (I2C)   │    │   │
│  │  │ module    │  │ ±16g / ±2000°│    │   │
│  │  │           │  └──────────────┘    │   │
│  │  │ BLE 5.4   │                      │   │
│  │  │ +8dBm     │  ┌──────────────┐    │   │
│  │  │ antenna   │  │  BQ25101     │    │   │
│  │  │ (built-in)│◄─│  Charger IC  │    │   │
│  │  └───────────┘  └──────┬───────┘    │   │
│  │                        │            │   │
│  │  [SWD pads] [Charge pogo pads]      │   │
│  └────────────────────────┼────────────┘   │
│                           │                │
│  ┌────────────────────────┼────────────┐   │
│  │    300mAh 3.7V LiPo   │            │   │
│  │    (402025 — both sizes)◄──┘        │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────┐  ┌────────────────────────┐   │
│  │ Status  │  │ O-ring Grip            │   │
│  │ LED     │  │ (2× grooves)           │   │
│  └─────────┘  └────────────────────────┘   │
│                                             │
│  Enclosure: SLA or injection-molded        │
│  50mm L × 21.5/18.5mm OD plug             │
└─────────────────────────────────────────────┘
```

### Phase 2 Cross-Section

```
    ┌──────────────────────────────────┐
    │          LACROSSE SHAFT          │ ← Shaft wall
    │  ┌────────────────────────────┐  │
    │  │ ╔══╗              ╔══╗    │  │ ← O-ring grooves (×2)
    │  │ ║OR║              ║OR║    │  │
    │  │ ╚══╝              ╚══╝    │  │
    │  │                           │  │
    │  │     [   402025   ]        │  │ ← 300mAh battery (both sizes)
    │  │     [   LiPo     ]        │  │   20×25×4mm — stacked above board
    │  │                           │  │
    │  │       ┌────────┐          │  │
    │  │       │ Custom │          │  │ ← 18×12mm custom PCB
    │  │       │  PCB   │          │  │   M1.2 standoffs
    │  │       └────────┘          │  │
    │  │  ┌──────────────────────┐ │  │
    │  │  │ [CHG pads] [LED]    │ │  │ ← Endcap face (visible)
    │  └──┴──────────────────────┴─┘  │   Pogo charge pads + LED window
    │        ↑ Butt end of stick      │   Flush with shaft end
    └──────────────────────────────────┘

    Total plug length: ~50mm (~1.97")
    Board: 18×12mm (vs 21×17.8mm XIAO)
```

### Phase Comparison

| | Phase 1 | Phase 2 |
|---|---|---|
| **Board** | XIAO nRF52840 Sense (21×17.8mm) | Custom PCB (18×12mm) |
| **IMU** | LSM6DS3 | LSM6DSV16X |
| **BLE** | 5.0 | 5.4 (BM840P module) |
| **Charging** | USB-C (remove plug from shaft) | Pogo pads through endcap |
| **Plug length** | 65mm | 50mm |
| **Women's battery** | 401730 (150mAh, ~8-12hr) | 402025 (300mAh, 20+hr) — same as men's |
| **Unit cost (100 qty)** | ~$35/unit | ~$17.50/unit |
| **Firmware** | Arduino/PlatformIO | Same, with IMU driver + pin mapping changes |
