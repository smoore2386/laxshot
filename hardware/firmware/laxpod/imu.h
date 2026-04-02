#ifndef IMU_H
#define IMU_H

#include <Arduino.h>
#include <LSM6DS3.h>

// IMU data structure
struct ImuData {
  float ax, ay, az;   // Accelerometer (g)
  float gx, gy, gz;   // Gyroscope (deg/s)
  bool valid;
};

// Initialize the LSM6DS3 IMU
bool imuInit();

// Read accelerometer and gyroscope data
ImuData imuRead();

// Get magnitude of acceleration vector
float imuAccelMagnitude(const ImuData& data);

// Configure wake-on-motion interrupt (for deep sleep wake)
void imuConfigureWakeOnMotion(float thresholdG);

// Disable wake-on-motion interrupt
void imuDisableWakeOnMotion();

#endif // IMU_H
