#include "ble.h"
#include "config.h"

// BLE Services and Characteristics
static BLEService motionService(MOTION_SERVICE_UUID);
static BLECharacteristic motionChar(MOTION_CHAR_UUID);
static BLECharacteristic controlChar(CONTROL_CHAR_UUID);

// Standard services
static BLEDis deviceInfo;  // Device Information Service
static BLEBas battery;     // Battery Service

// Connection callbacks
void (*bleOnConnect)(uint16_t connHandle) = nullptr;
void (*bleOnDisconnect)(uint16_t connHandle, uint8_t reason) = nullptr;

// Internal callbacks
static void _connectCallback(uint16_t connHandle) {
  Serial.print("[BLE] Connected — handle: ");
  Serial.println(connHandle);

  // Request higher connection interval for faster data throughput
  // Min 7.5ms, Max 15ms, latency 0, timeout 2s
  BLEConnection* conn = Bluefruit.Connection(connHandle);
  if (conn) {
    conn->requestConnectionParameter(6, 12, 0, 200);  // units of 1.25ms
  }

  if (bleOnConnect) bleOnConnect(connHandle);
}

static void _disconnectCallback(uint16_t connHandle, uint8_t reason) {
  Serial.print("[BLE] Disconnected — handle: ");
  Serial.print(connHandle);
  Serial.print(", reason: 0x");
  Serial.println(reason, HEX);

  if (bleOnDisconnect) bleOnDisconnect(connHandle, reason);
}

void bleInit() {
  Bluefruit.begin();
  Bluefruit.setTxPower(BLE_TX_POWER);
  Bluefruit.setName(BLE_DEVICE_NAME);

  // Set connection callbacks
  Bluefruit.Periph.setConnectCallback(_connectCallback);
  Bluefruit.Periph.setDisconnectCallback(_disconnectCallback);

  // Device Information Service
  deviceInfo.setManufacturer("LaxShot");
  deviceInfo.setModel("LaxPod v1");
  deviceInfo.setFirmwareRev(FW_VERSION_STRING);
  deviceInfo.setHardwareRev("XIAO-nRF52840-Sense");
  deviceInfo.begin();

  // Battery Service
  battery.begin();
  battery.write(100);  // Will be updated with real readings

  // Motion Service
  motionService.begin();

  // Motion Characteristic — notify only (48 bytes)
  motionChar.setProperties(CHR_PROPS_READ | CHR_PROPS_NOTIFY);
  motionChar.setPermission(SECMODE_OPEN, SECMODE_NO_ACCESS);
  motionChar.setFixedLen(BLE_PACKET_SIZE);
  motionChar.begin();

  // Control Characteristic — write (for session start/stop commands)
  controlChar.setProperties(CHR_PROPS_WRITE);
  controlChar.setPermission(SECMODE_NO_ACCESS, SECMODE_OPEN);
  controlChar.setFixedLen(1);
  controlChar.begin();

  Serial.println("[BLE] Initialized — services registered");
}

void bleStartAdvertising() {
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  Bluefruit.Advertising.addService(motionService);
  Bluefruit.ScanResponse.addName();

  // Advertising parameters
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);  // units of 0.625ms → 20ms to 152.5ms
  Bluefruit.Advertising.setFastTimeout(30);     // Fast advertising for 30 seconds
  Bluefruit.Advertising.start(0);               // 0 = advertise forever

  Serial.println("[BLE] Advertising started");
}

void bleStopAdvertising() {
  Bluefruit.Advertising.stop();
  Serial.println("[BLE] Advertising stopped");
}

bool bleIsConnected() {
  return Bluefruit.connected() > 0;
}

bool bleSendMotionPacket(const uint8_t* packet, uint16_t len) {
  if (!bleIsConnected()) return false;
  return motionChar.notify(packet, len);
}

uint8_t bleConnectionCount() {
  return Bluefruit.connected();
}

void bleDisconnectAll() {
  for (uint16_t i = 0; i < BLE_MAX_CONNECTION; i++) {
    BLEConnection* conn = Bluefruit.Connection(i);
    if (conn && conn->connected()) {
      conn->disconnect();
    }
  }
  Serial.println("[BLE] All connections closed");
}
