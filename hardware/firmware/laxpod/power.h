#ifndef POWER_H
#define POWER_H

#include <Arduino.h>

// Initialize power management (battery ADC, LED pins)
void powerInit();

// Read battery voltage and return percentage (0-100)
uint8_t powerGetBatteryPercent();

// Enter deep sleep mode (wake on IMU motion interrupt)
void powerEnterDeepSleep();

// Update activity timestamp (call on any motion/BLE activity)
void powerResetIdleTimer();

// Check if idle timeout has elapsed (should enter sleep)
bool powerShouldSleep();

// LED status indicators
void powerLedAdvertising();   // Blue pulsing
void powerLedConnected();     // Green solid
void powerLedLowBattery();    // Red solid
void powerLedShotDetected();  // Quick green flash
void powerLedOff();           // All LEDs off

#endif // POWER_H
