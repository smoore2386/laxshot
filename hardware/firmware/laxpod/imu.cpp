#include "imu.h"
#include "config.h"

static LSM6DS3 imu(I2C_MODE, 0x6A);

bool imuInit() {
  if (imu.begin() != 0) {
    Serial.println("[IMU] Init failed — check wiring");
    return false;
  }

  // Configure accelerometer: ±16g, 416 Hz
  imu.writeRegister(LSM6DS3_ACC_GYRO_CTRL1_XL, 0x64); // 416 Hz, ±16g
  // Configure gyroscope: ±2000 dps, 416 Hz
  imu.writeRegister(LSM6DS3_ACC_GYRO_CTRL2_G, 0x6C);  // 416 Hz, ±2000 dps

  Serial.println("[IMU] Initialized — 416 Hz, ±16g, ±2000 dps");
  return true;
}

ImuData imuRead() {
  ImuData data;
  data.valid = true;

  // Read accelerometer (returns values in g)
  if (imu.readFloatAccelX() == 0 && imu.readFloatAccelY() == 0 && imu.readFloatAccelZ() == 0) {
    // All zeros could indicate a read error — but could also be freefall
    // We'll trust the data and let the caller decide
  }

  data.ax = imu.readFloatAccelX();
  data.ay = imu.readFloatAccelY();
  data.az = imu.readFloatAccelZ();
  data.gx = imu.readFloatGyroX();
  data.gy = imu.readFloatGyroY();
  data.gz = imu.readFloatGyroZ();

  return data;
}

float imuAccelMagnitude(const ImuData& data) {
  return sqrtf(data.ax * data.ax + data.ay * data.ay + data.az * data.az);
}

void imuConfigureWakeOnMotion(float thresholdG) {
  // LSM6DS3 wake-up interrupt configuration
  // See application note AN5130 for full details

  // Set wake-up threshold (1 LSB = FS_XL / 64)
  // At ±16g: 1 LSB = 0.25g, so threshold = thresholdG / 0.25
  uint8_t wkThreshold = (uint8_t)(thresholdG / 0.25f);
  if (wkThreshold > 63) wkThreshold = 63;

  // TAP_CFG: enable interrupts, latch mode
  imu.writeRegister(0x58, 0x80); // TIMER_EN + INTERRUPTS_ENABLE

  // WAKE_UP_THS: set threshold
  imu.writeRegister(0x5B, wkThreshold & 0x3F);

  // WAKE_UP_DUR: no duration filtering
  imu.writeRegister(0x5C, 0x00);

  // MD1_CFG: route wake-up to INT1
  imu.writeRegister(0x5E, 0x20); // INT1_WU

  Serial.print("[IMU] Wake-on-motion configured — threshold: ");
  Serial.print(thresholdG);
  Serial.println("g");
}

void imuDisableWakeOnMotion() {
  // Clear wake-up interrupt routing
  imu.writeRegister(0x5E, 0x00); // MD1_CFG clear
  imu.writeRegister(0x5B, 0x00); // WAKE_UP_THS clear
  Serial.println("[IMU] Wake-on-motion disabled");
}
