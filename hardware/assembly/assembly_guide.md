# Assembly Guide — LaxPod Sensor Pod

Step-by-step assembly instructions for building one LaxPod unit. Repeat for all 5 prototypes.

**Time per unit:** ~15–20 minutes  
**Tools needed:** Soldering iron (optional), small Phillips screwdriver, wire cutters, USB-C cable  
**Skill level:** Beginner-friendly (mostly snap-together)

---

## Before You Start

- [ ] Firmware is compiled and verified (see `firmware/README.md`)
- [ ] Enclosure plug is printed and post-cured (see `enclosure/print_settings.md`)
- [ ] O-rings for your shaft size are on hand (2 per plug)
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

1. Hold the enclosure plug with the **open end facing up** (endcap face down)
2. Slide the XIAO board into the **rail cradle** inside the plug:
   - The board slides between the two parallel rails like a card in a slot
   - **USB-C port faces down** toward the endcap
   - Push until the board contacts the retaining lip
3. Align the 4 mounting holes with the M1.6 standoff bosses on the endcap floor
4. Thread **M1.6×4mm screws** through the board holes into the standoff bosses
5. Finger-tighten — don't overtorque (the resin bosses are small)

**Alternative (no screws):** The rail cradle holds the board in position. A small dot of hot glue on the standoffs adds security without screws.

---

## Step 5: Install Battery

1. Place a small piece of **double-sided foam tape** in the battery pocket (above the XIAO bay)
2. Press the LiPo cell into the pocket — it should sit flat:
   - **Men's units:** use 402025 battery (300mAh, 20×25×4mm)
   - **Women's units:** use 401730 battery (~150mAh, 17×30×3.5mm)
3. Route the JST wire along the wire channel to the XIAO connector
4. Tuck any excess wire length beside the battery
5. Ensure no wires are pinched between the board and plug walls

---

## Step 6: Install O-Rings

1. Locate the **2 circumferential grooves** near the open end (insertion end) of the plug
2. Stretch an O-ring and seat it into the **first groove** (closest to the open end):
   - **Men's:** ~19mm ID × 1.5mm cross-section
   - **Women's:** ~16mm ID × 1.5mm cross-section
3. Repeat for the **second groove**
4. Verify both O-rings sit flush in their grooves — they should protrude ~0.5mm above the plug surface
5. The O-rings should not easily roll out of the grooves when handled

---

## Step 7: Insert Plug into Shaft

1. Remove the stock butt-end cap from your lacrosse shaft (pull or twist off)
2. **Orient the plug** with the endcap face (button/LED holes) facing outward (toward you)
3. Push the plug **into the open butt end** of the shaft:
   - The O-rings compress against the shaft interior wall
   - Push until the endcap face is **flush with the shaft end**
4. **Men's version:** fits shafts with ~22mm+ internal diameter (1.000" OD shafts)
5. **Women's version:** fits shafts with ~19mm+ internal diameter (0.875" OD shafts)

### Fit Checks:
- [ ] Plug slides in with moderate force (O-rings grip but don't require excessive push)
- [ ] Plug doesn't fall out when you hold the stick vertically (butt-end down)
- [ ] Plug doesn't fall out when you shake the stick aggressively
- [ ] Plug doesn't rotate freely inside the shaft
- [ ] Endcap face is flush with (or slightly recessed from) the shaft end
- [ ] Button and LED holes are accessible from the butt end

### If too loose:
- Try the next size up O-ring cross-section (e.g., 2.0mm instead of 1.5mm)
- Wrap a thin layer of PTFE tape around the plug body between the O-ring grooves
- For octagonal or concave shafts: the O-rings naturally compress into the profile gaps

### If too tight:
- Lightly sand the plug exterior with 400-grit sandpaper
- Or use thinner O-rings (1.0mm cross-section)
- Check that no support nubs remain on the plug surface from printing

---

## Step 8: Final Verification

1. Power on (should auto-start when battery is connected)
2. Confirm blue LED visible through **endcap face** LED window (advertising)
3. Press the button through the **endcap face** button hole — confirm you can feel the click
4. Connect via nRF Connect app → verify all 3 services visible:
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
         │  (JST-PH 2.0)   │  ← Men's units (M1–M3)
         └──────────────────┘
              ─ OR ─
         ┌──────────────────┐
         │  150mAh LiPo     │
         │  3.7V 401730     │
         │  (JST-PH 2.0)   │  ← Women's units (W1–W2)
         └──────────────────┘
```

No external wiring beyond the battery connection. The IMU is onboard the XIAO Sense variant.

---

## Removing the Plug for Charging

To charge or flash firmware, the plug must be removed from the shaft:

1. Grip the exposed endcap face and **pull firmly** — the O-rings will release
2. If difficult to grip, use a small flat tool (coin, butter knife) to pry at the shaft edge
3. Connect USB-C to the XIAO port (accessible with plug removed)
4. When done, push the plug back into the shaft until flush
