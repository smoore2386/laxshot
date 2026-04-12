#ifndef CONFIG_H
#define CONFIG_H

// ─── Shaft & Enclosure Specs ───────────────────────────────────────
// Plug inserts inside shaft: Men's shaft OD 1.000", Women's shaft OD 0.875"
// Plug: Men's 21.5mm OD × 65mm, Women's 18.5mm OD × 65mm

// ─── BLE Configuration ────────────────────────────────────────────
// Custom base UUID: 4C415800-5348-4F54-4C41-585353454E53
// "LAX" + "SHOT" + "LAXSSENS" in ASCII hex
#define BLE_DEVICE_NAME       "LaxPod"
#define BLE_TX_POWER          8    // +8 dBm for field range (~30m)

// Service UUIDs
#define MOTION_SERVICE_UUID   "4C415801-5348-4F54-4C41-585353454E53"
#define MOTION_CHAR_UUID      "4C415802-5348-4F54-4C41-585353454E53"
#define CONTROL_CHAR_UUID     "4C415803-5348-4F54-4C41-585353454E53"

// ─── IMU Configuration ────────────────────────────────────────────
#define IMU_SAMPLE_RATE       416   // Hz (closest LSM6DS3 setting to 400)
#define IMU_ACCEL_RANGE       16    // ±16g (high-g shots)
#define IMU_GYRO_RANGE        2000  // ±2000 dps

// ─── Shot Detection ───────────────────────────────────────────────
#define SHOT_ACCEL_THRESHOLD  8.0f  // g — peak accel to trigger shot
#define SHOT_COOLDOWN_MS      2000  // ms — minimum time between shots
#define SHOT_WINDOW_MS        500   // ms — capture window after trigger

// ─── Power Management ────────────────────────────────────────────
#define SLEEP_TIMEOUT_MS      300000  // 5 minutes idle → deep sleep
#define BATTERY_READ_PIN      PIN_VBAT  // nRF52840 VBAT ADC
#define BATTERY_READ_INTERVAL 30000    // Read battery every 30s
#define LOW_BATTERY_PERCENT   10       // Red LED below this

// ─── LED Pins (XIAO nRF52840 Sense — active LOW) ─────────────────
#define LED_RED_PIN           LED_RED
#ifndef LED_GREEN
#define LED_GREEN             14  // XIAO nRF52840 Sense green LED GPIO
#endif
#define LED_GREEN_PIN         LED_GREEN
#define LED_BLUE_PIN          LED_BLUE

// ─── BLE Packet Format ───────────────────────────────────────────
// Total: 48 bytes
// [0-11]   float32[3] accelerometer (x, y, z) in g
// [12-23]  float32[3] gyroscope (x, y, z) in deg/s
// [24-39]  float32[4] quaternion (w, x, y, z)
// [40]     uint8 battery percentage (0-100)
// [41]     uint8 flags (bit 0: in-shot, bit 1: session-active)
// [42-45]  uint32 timestamp (ms since boot)
// [46-47]  uint16 reserved
#define BLE_PACKET_SIZE       48

// ─── Notification Rate ───────────────────────────────────────────
#define BLE_NOTIFY_INTERVAL_ACTIVE  5    // ms (~200 Hz during shots)
#define BLE_NOTIFY_INTERVAL_IDLE    100  // ms (~10 Hz when idle/connected)

// ─── Firmware Version ────────────────────────────────────────────
#define FW_VERSION_MAJOR      0
#define FW_VERSION_MINOR      1
#define FW_VERSION_PATCH      0
#define FW_VERSION_STRING     "0.1.0"

#endif // CONFIG_H
