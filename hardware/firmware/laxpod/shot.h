#ifndef SHOT_H
#define SHOT_H

#include <Arduino.h>
#include "imu.h"

// Shot state
enum class ShotState {
  IDLE,       // No shot in progress
  DETECTED,   // Peak acceleration exceeded threshold
  CAPTURING,  // Recording shot window data
  COOLDOWN    // Waiting for cooldown period
};

// Shot event data
struct ShotEvent {
  float peakAccelG;           // Maximum acceleration magnitude during shot
  float quaternion[4];        // Orientation at peak (w, x, y, z)
  unsigned long startTimeMs;  // Timestamp when shot was detected
  unsigned long durationMs;   // Duration of shot event
};

// Initialize shot detection system and Madgwick filter
void shotInit(float sampleRateHz);

// Update shot detection with new IMU data
// Call this every loop iteration with fresh IMU readings
// Returns true if a new shot was just completed
bool shotUpdate(const ImuData& data);

// Get the current shot state
ShotState shotGetState();

// Get the last completed shot event
// Only valid after shotUpdate() returns true
ShotEvent shotGetLastEvent();

// Get current quaternion orientation (always valid, updated every frame)
void shotGetQuaternion(float q[4]);

// Reset shot detection state
void shotReset();

// Get shot count since last reset
uint32_t shotGetCount();

#endif // SHOT_H
