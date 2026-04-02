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
│  │ RGB LED │  │Button│  │ Snap-fit   │    │
│  │ Status  │  │ Pair │  │ Lid        │    │
│  └─────────┘  └──────┘  └────────────┘    │
│                                             │
│  Enclosure: SLA Rigid 10K Resin            │
│  1.6" L × 1.25" OD, friction-fit bore     │
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

## Enclosure Cross-Section

```
         ┌─────────────┐ ← Snap-fit lid (0.15" deep)
         │ [BTN] [LED] │ ← Button hole (3mm) + LED window (4mm)
         ├─────────────┤
         │             │
         │   [XIAO]    │ ← Board on M1.6 standoffs (0.1" tall)
         │             │
         │   [LiPo]    │ ← Battery pocket (22×19×4mm)
         │             │
    ┌────┤             ├────┐
    │ RR │             │ RR │ ← Grip ribs (0.05"×0.08"×0.30")
    │ II │             │ II │
    │ BB │             │ BB │
    │ SS │             │ SS │
    └────┼─────────────┼────┘
         │     ↕       │
         │  SHAFT      │ ← Lacrosse shaft inserts here
         │  BORE       │   Men's: 1.000" / Women's: 0.875"
         └─────────────┘
```
