# Assembly Guide — LaxPod Sensor Pod

Step-by-step assembly instructions for building one LaxPod unit. Repeat for all 5 prototypes.

**Time per unit:** ~15–20 minutes  
**Tools needed:** Soldering iron (optional), small Phillips screwdriver, wire cutters, USB-C cable  
**Skill level:** Beginner-friendly (mostly snap-together)

---

## Before You Start

- [ ] Firmware is compiled and verified (see `firmware/README.md`)
- [ ] Enclosure body + lid are printed and post-cured
- [ ] All BOM items received

---

## Step 1: Flash Firmware

1. Connect XIAO nRF52840 Sense to computer via USB-C
2. Open terminal in `hardware/firmware/`:
   ```bash
   pio run --target upload
   ```
   Or use Arduino IDE (see firmware README)
3. Open serial monitor (115200 baud) — verify output:
   ```
   LaxPod Firmware v0.1.0
   [IMU] Initialized — 416 Hz, ±16g, ±2000 dps
   [BLE] Advertising started
   ```
4. Verify BLE advertising: open **nRF Connect** app on phone → scan → find "LaxPod"
5. **Mark the board** with a Sharpie (1–5) to track which unit is which

---

## Step 2: Connect Battery

**Option A — Battery already has JST-PH 2.0mm connector (preferred):**
1. Simply plug the JST-PH connector into the battery pads on the bottom of the XIAO
2. The XIAO will start running on battery power
3. Verify the serial output still works (connect USB simultaneously)

**Option B — Battery has bare leads (requires soldering):**
1. Cut JST-PH connector wires to 3cm length
2. Strip 2mm of insulation from battery leads
3. Solder **red wire → BAT+** pad on XIAO bottom
4. Solder **black wire → BAT−** pad on XIAO bottom
5. Apply heat shrink tubing over solder joints
6. Plug the JST connector into the battery

**Battery polarity is critical — double-check red=positive, black=negative before connecting.**

---

## Step 3: Verify Battery Charging

1. With battery connected, plug in USB-C
2. Orange charge LED on XIAO should illuminate
3. When fully charged (takes ~1 hour from empty), charge LED turns off
4. Check serial output: battery percentage should read > 0%

---

## Step 4: Mount Board in Enclosure

1. Place the enclosure body **bore-side down** on the table (opening facing up)
2. Drop in 4× M1.6 screws through the standoff holes (from inside)
3. Place the XIAO board on the standoffs, aligning the 4 mounting holes:
   - USB-C port should face **toward the lid** (top)
   - IMU chip faces up
4. Thread M1.6 nuts onto the screws from the bottom side of the board
5. Finger-tighten — don't overtorque (the resin standoffs are small)

**Alternative (no screws):** Use a small dot of hot glue on each standoff. The pod doesn't experience sustained force on the board.

---

## Step 5: Install Battery

1. Place a small piece of **double-sided foam tape** in the battery pocket
2. Press the LiPo cell into the pocket — it should sit flat
3. Route the JST wire along the wire channel to the XIAO connector
4. Tuck any excess wire length beside the battery
5. Ensure no wires are pinched between the board and enclosure walls

---

## Step 6: Snap Lid

1. Orient the lid so the **button hole aligns** with the XIAO's onboard button
2. The **LED window** should align with the RGB LED area
3. Press the lid down firmly until the **4 snap hooks click** into place
4. Verify the lid is flush and doesn't wobble
5. Press the button through the hole — confirm you can feel the click

---

## Step 7: Test Fit on Shaft

1. Remove the stock butt cap from your lacrosse shaft (pull or twist off)
2. Slide the LaxPod onto the bare shaft end
3. **Men's version:** Should grip a 1.000" OD shaft snugly
4. **Women's version:** Should grip a 0.875" OD shaft snugly

### Fit Checks:
- [ ] Pod slides on with moderate force (not too easy, not impossible)
- [ ] Pod doesn't fall off when you hold the stick horizontally
- [ ] Pod doesn't fall off when you shake the stick vertically (butt-end down)
- [ ] Pod doesn't rotate freely on the shaft
- [ ] Pod sits flush — no gap between pod and shaft tape

### If too loose:
- Wrap 1–2 layers of electrical tape on the shaft where the ribs contact
- Or print with 0.02" tighter bore diameter

### If too tight:
- Sand the grip ribs lightly with 400-grit sandpaper
- Or file ribs down 0.01–0.02"

---

## Step 8: Final Verification

1. Power on (should auto-start when battery is connected)
2. Confirm blue LED visible through lid window (advertising)
3. Connect via nRF Connect app → verify all 3 services visible:
   - Motion Service (4C415801...)
   - Device Information (0x180A)
   - Battery Service (0x180F)
4. Subscribe to motion characteristic notifications
5. Shake the pod → verify data streams in nRF Connect
6. Set pod down for 5 minutes → verify it enters deep sleep (LED off)
7. Shake to wake → verify LED comes back on and BLE re-advertises

---

## Labeling

Mark each completed unit:
- **Pod 1–3:** Men's (1") — mark with "M1", "M2", "M3"
- **Pod 4–5:** Women's (7/8") — mark with "W1", "W2"

Use a silver Sharpie on the resin surface, or print small labels.

---

## Wiring Diagram

```
         ┌──────────────────┐
         │  XIAO nRF52840   │
         │     Sense         │
         │                   │
USB-C ──►│ [USB]    [IMU]   │
         │                   │
         │ BAT+  BAT-       │
         └──┬───────┬───────┘
            │       │
            │ Red   │ Black
            │       │
         ┌──┴───────┴───────┐
         │  300mAh LiPo     │
         │  3.7V 402025     │
         │  (JST-PH 2.0)   │
         └──────────────────┘
```

No external wiring beyond the battery connection. The IMU is onboard the XIAO Sense variant.
