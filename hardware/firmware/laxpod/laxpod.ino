/*
 * LaxPod — Lacrosse Stick Sensor Pod Firmware
 * ============================================
 * Platform: Seeed XIAO nRF52840 Sense
 * Features: BLE streaming, IMU 416Hz, shot detection, Madgwick quaternion, auto-sleep
 * Version:  0.1.0 (Phase 1 Prototype)
 *
 * BLE Protocol: See hardware/docs/ble_protocol.md
 * Build:        PlatformIO (pio run) or Arduino IDE (Seeed nRF52 board package)
 */

#include <Arduino.h>
#include "config.h"
#include "imu.h"
#include "ble.h"
#include "shot.h"
#include "power.h"

// ─── State ────────────────────────────────────────────────────────
static bool bleConnected = false;
static unsigned long lastNotifyMs = 0;
static uint8_t packetBuffer[BLE_PACKET_SIZE];

// ─── BLE Callbacks ────────────────────────────────────────────────
static void onBleConnect(uint16_t connHandle) {
  bleConnected = true;
  powerLedConnected();
  powerResetIdleTimer();
  Serial.println("[MAIN] Central connected — streaming enabled");
}

static void onBleDisconnect(uint16_t connHandle, uint8_t reason) {
  bleConnected = false;
  powerLedAdvertising();
  Serial.println("[MAIN] Central disconnected — returning to advertising");
}

// ─── Packet Builder ───────────────────────────────────────────────
static void buildMotionPacket(const ImuData& imu, uint8_t battPct, bool inShot) {
  // Zero the buffer
  memset(packetBuffer, 0, BLE_PACKET_SIZE);

  uint16_t offset = 0;

  // Accelerometer: float32[3] (12 bytes)
  memcpy(&packetBuffer[offset], &imu.ax, sizeof(float)); offset += sizeof(float);
  memcpy(&packetBuffer[offset], &imu.ay, sizeof(float)); offset += sizeof(float);
  memcpy(&packetBuffer[offset], &imu.az, sizeof(float)); offset += sizeof(float);

  // Gyroscope: float32[3] (12 bytes)
  memcpy(&packetBuffer[offset], &imu.gx, sizeof(float)); offset += sizeof(float);
  memcpy(&packetBuffer[offset], &imu.gy, sizeof(float)); offset += sizeof(float);
  memcpy(&packetBuffer[offset], &imu.gz, sizeof(float)); offset += sizeof(float);

  // Quaternion: float32[4] (16 bytes)
  float q[4];
  shotGetQuaternion(q);
  memcpy(&packetBuffer[offset], &q[0], sizeof(float)); offset += sizeof(float);
  memcpy(&packetBuffer[offset], &q[1], sizeof(float)); offset += sizeof(float);
  memcpy(&packetBuffer[offset], &q[2], sizeof(float)); offset += sizeof(float);
  memcpy(&packetBuffer[offset], &q[3], sizeof(float)); offset += sizeof(float);

  // Battery: uint8 (1 byte)
  packetBuffer[offset] = battPct; offset += 1;

  // Flags: uint8 (1 byte)
  // Bit 0: in-shot, Bit 1: session-active
  uint8_t flags = 0;
  if (inShot) flags |= 0x01;
  if (bleConnected) flags |= 0x02;
  packetBuffer[offset] = flags; offset += 1;

  // Timestamp: uint32 (4 bytes) — ms since boot
  uint32_t ts = (uint32_t)millis();
  memcpy(&packetBuffer[offset], &ts, sizeof(uint32_t)); offset += sizeof(uint32_t);

  // Reserved: uint16 (2 bytes)
  // Already zeroed
}

// ─── Setup ────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  // Wait up to 2s for serial (don't block if no USB)
  unsigned long serialWait = millis();
  while (!Serial && (millis() - serialWait < 2000));

  Serial.println("========================================");
  Serial.print("LaxPod Firmware v");
  Serial.println(FW_VERSION_STRING);
  Serial.println("========================================");

  // Initialize subsystems
  powerInit();
  powerLedAdvertising();

  if (!imuInit()) {
    Serial.println("[MAIN] FATAL: IMU init failed — halting");
    while (1) {
      powerLedLowBattery();
      delay(500);
      powerLedOff();
      delay(500);
    }
  }

  shotInit((float)IMU_SAMPLE_RATE);

  // Set BLE callbacks before init
  bleOnConnect = onBleConnect;
  bleOnDisconnect = onBleDisconnect;
  bleInit();
  bleStartAdvertising();

  Serial.println("[MAIN] Setup complete — advertising as " BLE_DEVICE_NAME);
  Serial.print("[MAIN] Battery: ");
  Serial.print(powerGetBatteryPercent());
  Serial.println("%");
}

// ─── Main Loop ────────────────────────────────────────────────────
void loop() {
  // Read IMU
  ImuData data = imuRead();

  // Update shot detection + Madgwick filter
  bool newShot = shotUpdate(data);

  if (newShot) {
    powerResetIdleTimer();
    powerLedShotDetected();

    ShotEvent event = shotGetLastEvent();
    Serial.print("[MAIN] Shot #");
    Serial.print(shotGetCount());
    Serial.print(" — peak: ");
    Serial.print(event.peakAccelG);
    Serial.println("g");

    // Brief LED flash for shot feedback
    delay(50);
    if (bleConnected) {
      powerLedConnected();
    } else {
      powerLedAdvertising();
    }
  }

  // Any significant motion resets the idle timer
  float accelMag = imuAccelMagnitude(data);
  if (accelMag > 2.0f) {
    powerResetIdleTimer();
  }

  // BLE notification
  if (bleConnected) {
    unsigned long now = millis();
    bool inShot = (shotGetState() == ShotState::DETECTED ||
                   shotGetState() == ShotState::CAPTURING);

    // Higher rate during shots, lower rate when idle
    unsigned long interval = inShot ?
      BLE_NOTIFY_INTERVAL_ACTIVE :
      BLE_NOTIFY_INTERVAL_IDLE;

    if (now - lastNotifyMs >= interval) {
      lastNotifyMs = now;
      uint8_t battPct = powerGetBatteryPercent();
      buildMotionPacket(data, battPct, inShot);
      bleSendMotionPacket(packetBuffer, BLE_PACKET_SIZE);

      // Update battery service periodically
      static unsigned long lastBattUpdate = 0;
      if (now - lastBattUpdate > BATTERY_READ_INTERVAL) {
        lastBattUpdate = now;
        // Battery level is sent via standard BLE Battery Service
        // (handled automatically by BLEBas)
      }
    }

    // Low battery LED override
    if (powerGetBatteryPercent() < LOW_BATTERY_PERCENT) {
      powerLedLowBattery();
    }
  }

  // Deep sleep check
  if (powerShouldSleep() && !bleConnected) {
    Serial.println("[MAIN] Idle timeout — entering deep sleep");
    powerEnterDeepSleep();
    // Device resets after wake — setup() runs again
  }

  // Small delay to control loop rate
  // At 416Hz IMU, we want ~2.4ms per loop
  delay(2);
}
