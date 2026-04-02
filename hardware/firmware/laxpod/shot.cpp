#include "shot.h"
#include "config.h"
#include <MadgwickAHRS.h>

static Madgwick madgwick;
static ShotState state = ShotState::IDLE;
static ShotEvent lastEvent;
static uint32_t shotCount = 0;

static float currentQuat[4] = {1.0f, 0.0f, 0.0f, 0.0f};  // Identity quaternion
static float peakAccel = 0.0f;
static unsigned long shotStartTime = 0;
static unsigned long lastShotEndTime = 0;

void shotInit(float sampleRateHz) {
  madgwick.begin(sampleRateHz);
  state = ShotState::IDLE;
  shotCount = 0;
  peakAccel = 0.0f;
  shotStartTime = 0;
  lastShotEndTime = 0;
  Serial.print("[SHOT] Initialized — sample rate: ");
  Serial.print(sampleRateHz);
  Serial.println(" Hz");
}

bool shotUpdate(const ImuData& data) {
  if (!data.valid) return false;

  // Always update Madgwick filter for continuous orientation tracking
  madgwick.updateIMU(data.gx, data.gy, data.gz, data.ax, data.ay, data.az);

  // Store current quaternion
  currentQuat[0] = madgwick.getQuatW();
  currentQuat[1] = madgwick.getQuatX();
  currentQuat[2] = madgwick.getQuatY();
  currentQuat[3] = madgwick.getQuatZ();

  float accelMag = imuAccelMagnitude(data);
  unsigned long now = millis();

  switch (state) {
    case ShotState::IDLE:
      // Check if acceleration exceeds shot threshold
      if (accelMag > SHOT_ACCEL_THRESHOLD) {
        // Check cooldown from last shot
        if (now - lastShotEndTime > SHOT_COOLDOWN_MS) {
          state = ShotState::DETECTED;
          shotStartTime = now;
          peakAccel = accelMag;
          Serial.print("[SHOT] Detected! accel=");
          Serial.print(accelMag);
          Serial.println("g");
        }
      }
      break;

    case ShotState::DETECTED:
      // Fall through to CAPTURING
      state = ShotState::CAPTURING;
      // no break — intentional

    case ShotState::CAPTURING:
      // Track peak acceleration during capture window
      if (accelMag > peakAccel) {
        peakAccel = accelMag;
      }

      // Check if capture window has elapsed
      if (now - shotStartTime > SHOT_WINDOW_MS) {
        // Shot complete — record event
        lastEvent.peakAccelG = peakAccel;
        lastEvent.quaternion[0] = currentQuat[0];
        lastEvent.quaternion[1] = currentQuat[1];
        lastEvent.quaternion[2] = currentQuat[2];
        lastEvent.quaternion[3] = currentQuat[3];
        lastEvent.startTimeMs = shotStartTime;
        lastEvent.durationMs = now - shotStartTime;

        shotCount++;
        lastShotEndTime = now;
        state = ShotState::COOLDOWN;

        Serial.print("[SHOT] Complete #");
        Serial.print(shotCount);
        Serial.print(" — peak: ");
        Serial.print(peakAccel);
        Serial.print("g, duration: ");
        Serial.print(lastEvent.durationMs);
        Serial.println("ms");

        return true;  // New shot completed
      }
      break;

    case ShotState::COOLDOWN:
      // Wait for cooldown period
      if (now - lastShotEndTime > SHOT_COOLDOWN_MS) {
        state = ShotState::IDLE;
        peakAccel = 0.0f;
      }
      break;
  }

  return false;
}

ShotState shotGetState() {
  return state;
}

ShotEvent shotGetLastEvent() {
  return lastEvent;
}

void shotGetQuaternion(float q[4]) {
  q[0] = currentQuat[0];
  q[1] = currentQuat[1];
  q[2] = currentQuat[2];
  q[3] = currentQuat[3];
}

void shotReset() {
  state = ShotState::IDLE;
  shotCount = 0;
  peakAccel = 0.0f;
  shotStartTime = 0;
  lastShotEndTime = 0;
}

uint32_t shotGetCount() {
  return shotCount;
}
