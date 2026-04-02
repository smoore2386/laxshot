# Test Protocol — LaxPod Sensor Pod

Run this protocol on each assembled pod before marking it "ready for beta."

**Equipment needed:**
- Assembled LaxPod (firmware flashed, battery connected, in enclosure)
- Men's lacrosse stick (1" OD shaft) and/or women's stick (7/8" OD)
- Smartphone with nRF Connect app (or LaxShot app when BLE integration is ready)
- USB-C cable + computer (for serial monitor)
- Stopwatch/timer

---

## Test 1: Power-On (Pass/Fail)

| Step | Expected | Pass? |
|------|----------|-------|
| Connect battery (or press reset) | Serial output shows firmware version | ☐ |
| Observe LED | Blue LED visible through lid window | ☐ |
| Check serial | `[IMU] Initialized` + `[BLE] Advertising started` printed | ☐ |

**Fail action:** Check battery polarity, verify firmware was flashed, check solder joints.

---

## Test 2: BLE Discovery (Pass/Fail)

| Step | Expected | Pass? |
|------|----------|-------|
| Open nRF Connect on phone | App opens | ☐ |
| Tap Scan | Device list populates | ☐ |
| Find "LaxPod" in list | Device appears with correct name | ☐ |
| Check RSSI | Signal strength > -70 dBm at 1m distance | ☐ |
| Tap Connect | Connection established, services discovered | ☐ |
| Verify 3 services | Motion (4C415801), Device Info (180A), Battery (180F) | ☐ |

**Fail action:** Check antenna area (no metal nearby), verify BLE is initialized, check TX power setting.

---

## Test 3: IMU Baseline (Pass/Fail)

| Step | Expected | Pass? |
|------|----------|-------|
| Place pod flat on table | Stable readings | ☐ |
| Read accel via serial or BLE | X ≈ 0g, Y ≈ 0g, Z ≈ ±1g (gravity) | ☐ |
| Read gyro | All axes ≈ 0 deg/s (±5 tolerance) | ☐ |
| Tilt pod 90° | One axis shifts to ±1g, Z drops toward 0g | ☐ |

**Fail action:** Check I2C address (0x6A), verify IMU init succeeded, check for firmware register writes.

---

## Test 4: Shot Detection (Pass/Fail)

| Step | Expected | Pass? |
|------|----------|-------|
| Shake pod hard (simulate swing) | Serial prints `[SHOT] Detected!` | ☐ |
| Check acceleration threshold | Detection triggers above 8g | ☐ |
| Verify shot event data | Peak accel, quaternion, duration reported | ☐ |
| Wait 2 seconds | Shot state returns to IDLE | ☐ |
| Shake again | Second shot detected (cooldown elapsed) | ☐ |
| Gentle motion (< 8g) | No false shot triggers | ☐ |

**Fail action:** Adjust `SHOT_ACCEL_THRESHOLD` in config.h, check accel range is ±16g.

---

## Test 5: BLE Data Streaming (Pass/Fail)

| Step | Expected | Pass? |
|------|----------|-------|
| Connect via nRF Connect | Connected state | ☐ |
| Subscribe to Motion char (4C415802) | Notifications start arriving | ☐ |
| Idle rate | Packets arrive ~every 100ms (10 Hz) | ☐ |
| During shot | Packet rate increases (~5ms, 200 Hz) | ☐ |
| Packet size | Each notification = 48 bytes | ☐ |
| Parse a packet | Accel/gyro/quat values are reasonable | ☐ |
| Check battery byte (offset 40) | Shows value 0–100 | ☐ |
| Check flags byte (offset 41) | Bit 0 = IN_SHOT during shake | ☐ |

**Fail action:** Check BLE packet builder, verify characteristic is set to 48 bytes fixed length.

---

## Test 6: Quaternion Orientation (Pass/Fail)

| Step | Expected | Pass? |
|------|----------|-------|
| Hold pod still | Quaternion converges to stable value | ☐ |
| Rotate pod slowly 90° around one axis | Quaternion changes smoothly | ☐ |
| Return to original position | Quaternion returns near starting value | ☐ |
| Fast rotation | Quaternion tracks without large drift | ☐ |

**Fail action:** Check Madgwick filter sample rate matches IMU rate, verify gyro units are deg/s.

---

## Test 7: Deep Sleep (Pass/Fail)

| Step | Expected | Pass? |
|------|----------|-------|
| Disconnect BLE (if connected) | Pod returns to advertising (blue LED) | ☐ |
| Leave pod idle for 5 minutes | LED turns off, serial stops | ☐ |
| Shake pod | LED comes back on, BLE re-advertises | ☐ |
| Re-connect via nRF Connect | Connection works, data streams | ☐ |

**Fail action:** Check `SLEEP_TIMEOUT_MS`, verify wake-on-motion interrupt is configured.

---

## Test 8: Shaft Fit (Pass/Fail)

| Step | Expected | Pass? |
|------|----------|-------|
| Remove stock butt cap from stick | Bare shaft end exposed | ☐ |
| Slide LaxPod onto shaft | Goes on with moderate push force | ☐ |
| Hold stick horizontally | Pod stays on (no sliding off) | ☐ |
| Shake stick vertically (butt down) | Pod stays secure | ☐ |
| Twist pod on shaft | Doesn't rotate freely | ☐ |
| Remove pod | Pulls off with moderate force | ☐ |
| Check pod for damage after removal | No cracks, chips, or deformation | ☐ |

**Fail action:** See assembly guide fit adjustment section (tape for loose, sanding for tight).

---

## Test 9: Game Simulation (Pass/Fail)

| Step | Expected | Pass? |
|------|----------|-------|
| Mount pod on stick, connect via BLE | Connected + streaming | ☐ |
| Execute 5 overhand shots | All 5 shots detected, data captured | ☐ |
| Execute 5 sidearm shots | All 5 shots detected | ☐ |
| Execute 5 underhand shots | At least 3 detected (lower accel) | ☐ |
| Cradle and run (not shooting) | No false shot triggers | ☐ |
| Check pod after 15 shots | Still securely attached, no shifting | ☐ |
| Check BLE connection | Still connected, no disconnects during shots | ☐ |
| Check battery after session | Battery % decreased reasonably (< 5%) | ☐ |

**Fail action:** Tune shot threshold, check enclosure fit, verify BLE connection parameters.

---

## Results Log Template

```
Pod ID: _____ (M1/M2/M3/W1/W2)
Date: ___________
Tester: ___________
Stick used: ___________ (brand/model)

Test 1 Power-On:       PASS / FAIL — Notes: ___________
Test 2 BLE Discovery:  PASS / FAIL — Notes: ___________
Test 3 IMU Baseline:   PASS / FAIL — Notes: ___________
Test 4 Shot Detection: PASS / FAIL — Notes: ___________
Test 5 BLE Streaming:  PASS / FAIL — Notes: ___________
Test 6 Quaternion:     PASS / FAIL — Notes: ___________
Test 7 Deep Sleep:     PASS / FAIL — Notes: ___________
Test 8 Shaft Fit:      PASS / FAIL — Notes: ___________
Test 9 Game Sim:       PASS / FAIL — Notes: ___________

Overall: PASS / FAIL
Issues found: ___________
```
