#ifndef BLE_H
#define BLE_H

#include <Arduino.h>
#include <bluefruit.h>

// Initialize BLE stack and services
void bleInit();

// Start BLE advertising
void bleStartAdvertising();

// Stop BLE advertising (before sleep)
void bleStopAdvertising();

// Check if a central is connected
bool bleIsConnected();

// Send motion data packet via BLE notify
// Returns true if notification was sent successfully
bool bleSendMotionPacket(const uint8_t* packet, uint16_t len);

// Get the number of connected centrals
uint8_t bleConnectionCount();

// Disconnect all centrals (before sleep)
void bleDisconnectAll();

// BLE connection callbacks (set in setup)
extern void (*bleOnConnect)(uint16_t connHandle);
extern void (*bleOnDisconnect)(uint16_t connHandle, uint8_t reason);

#endif // BLE_H
