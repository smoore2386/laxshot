#include "power.h"
#include "config.h"
#include "imu.h"
#include <bluefruit.h>

static unsigned long lastActivityMs = 0;
static unsigned long lastBatteryReadMs = 0;
static uint8_t cachedBatteryPercent = 100;

// Battery voltage to percentage lookup (3.7V LiPo)
// Voltage range: 3.0V (empty) to 4.2V (full)
static uint8_t voltageToPct(float voltage) {
  if (voltage >= 4.15f) return 100;
  if (voltage >= 4.05f) return 90;
  if (voltage >= 3.95f) return 80;
  if (voltage >= 3.85f) return 70;
  if (voltage >= 3.78f) return 60;
  if (voltage >= 3.72f) return 50;
  if (voltage >= 3.67f) return 40;
  if (voltage >= 3.62f) return 30;
  if (voltage >= 3.55f) return 20;
  if (voltage >= 3.45f) return 10;
  if (voltage >= 3.30f) return 5;
  return 0;
}

void powerInit() {
  // Configure LED pins (active LOW on XIAO nRF52840)
  pinMode(LED_RED_PIN, OUTPUT);
  pinMode(LED_GREEN_PIN, OUTPUT);
  pinMode(LED_BLUE_PIN, OUTPUT);
  powerLedOff();

  // Configure battery ADC
  analogReference(AR_INTERNAL_3_0);  // 3.0V reference
  analogReadResolution(12);          // 12-bit ADC

  lastActivityMs = millis();
  lastBatteryReadMs = 0;  // Force immediate first read

  Serial.println("[POWER] Initialized");
}

uint8_t powerGetBatteryPercent() {
  unsigned long now = millis();

  // Only read battery at configured interval (saves power)
  if (now - lastBatteryReadMs > BATTERY_READ_INTERVAL) {
    lastBatteryReadMs = now;

    // Read VBAT pin — nRF52840 has internal voltage divider
    // VBAT/2 is connected to the ADC pin
    uint32_t adcRaw = analogRead(BATTERY_READ_PIN);

    // Convert to voltage: ADC * reference / resolution * divider
    // 3.0V reference, 12-bit (4096), ×2 for voltage divider
    float voltage = (float)adcRaw * 3.0f / 4096.0f * 2.0f;

    cachedBatteryPercent = voltageToPct(voltage);
  }

  return cachedBatteryPercent;
}

void powerEnterDeepSleep() {
  Serial.println("[POWER] Entering deep sleep — wake on motion");
  Serial.flush();

  // Turn off LEDs
  powerLedOff();

  // Configure IMU wake-on-motion before sleeping
  imuConfigureWakeOnMotion(SHOT_ACCEL_THRESHOLD * 0.5f);  // Wake at half shot threshold

  // Disable BLE
  Bluefruit.Advertising.stop();

  // Enter system OFF (deepest sleep, ~0.3µA)
  // Wake source: GPIO interrupt from IMU INT1 pin
  // Note: On XIAO nRF52840, the IMU INT1 is connected to a GPIO
  // that can wake from system OFF

  // Use NRF_POWER system OFF
  NRF_POWER->SYSTEMOFF = 1;

  // Execution stops here — device resets on wake
  // After wake, setup() runs again from the beginning
}

void powerResetIdleTimer() {
  lastActivityMs = millis();
}

bool powerShouldSleep() {
  return (millis() - lastActivityMs) > SLEEP_TIMEOUT_MS;
}

// ─── LED Functions (active LOW on XIAO) ──────────────────────────

void powerLedAdvertising() {
  // Blue pulsing (simplified: just solid blue)
  digitalWrite(LED_RED_PIN, HIGH);
  digitalWrite(LED_GREEN_PIN, HIGH);
  digitalWrite(LED_BLUE_PIN, LOW);
}

void powerLedConnected() {
  // Green solid
  digitalWrite(LED_RED_PIN, HIGH);
  digitalWrite(LED_GREEN_PIN, LOW);
  digitalWrite(LED_BLUE_PIN, HIGH);
}

void powerLedLowBattery() {
  // Red solid
  digitalWrite(LED_RED_PIN, LOW);
  digitalWrite(LED_GREEN_PIN, HIGH);
  digitalWrite(LED_BLUE_PIN, HIGH);
}

void powerLedShotDetected() {
  // Quick green flash (non-blocking — caller should restore previous state)
  digitalWrite(LED_RED_PIN, HIGH);
  digitalWrite(LED_GREEN_PIN, LOW);
  digitalWrite(LED_BLUE_PIN, HIGH);
}

void powerLedOff() {
  digitalWrite(LED_RED_PIN, HIGH);
  digitalWrite(LED_GREEN_PIN, HIGH);
  digitalWrite(LED_BLUE_PIN, HIGH);
}
