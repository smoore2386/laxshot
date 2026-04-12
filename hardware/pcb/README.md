# Phase 2 Custom PCB — LaxPod 18×12mm Board

Shrink the off-the-shelf XIAO nRF52840 Sense (21×17.8mm) down to a custom **18×12mm** PCB using KiCad and JLCPCB turnkey assembly. Same core circuit — nRF52840 + IMU + LiPo charger — but smaller, cheaper at scale, and purpose-built for the lacrosse butt-end plug enclosure.

---

## Why Phase 2?

| | Phase 1 (XIAO) | Phase 2 (Custom) |
|---|---|---|
| **Board size** | 21 × 17.8mm | 18 × 12mm |
| **Unit cost (5 qty)** | $15.99 | ~$12.47 |
| **Unit cost (100 qty)** | $15.99 | ~$12.47 |
| **Unit cost (1k qty)** | $15.99 | ~$9.00 |
| **IMU** | LSM6DS3 | LSM6DSV16X (better high-g range) |
| **BLE** | 5.0 | 5.4 (pre-certified module) |
| **USB-C** | On-board | Removed (charge via pogo pads) |
| **Women's shaft fit** | Very tight (0.7mm clearance) | Comfortable (3.5mm+ clearance) |
| **Plug length** | ~65mm | ~50mm (shorter axial stack) |

---

## Source Files & References

### Official Seeed XIAO Open-Source Design Files

These are the starting point — delete what you don't need:

| Resource | Description |
|----------|-------------|
| **Schematic PDF** | Exact reference circuit for nRF52840 + BQ25101 charger |
| **KiCad Project ZIP** (V1.1) | Full Sense variant with IMU — unzip and modify in KiCad |
| **GitHub Repo** | All XIAO variants + footprint libraries |

> The KiCad project V1.1 includes the Sense variant with the LSM6DS3 IMU. Use this as your starting schematic.

---

## Step-by-Step: Shrink to 18×12mm in KiCad

### Step 1 — Set Up Project (0:00–0:05)

1. Unzip the KiCad project
2. Open the `.kicad_pro` file in KiCad 8+
3. The schematic contains the full XIAO circuit: nRF52840, IMU, charger, USB-C, LEDs, NFC antenna, etc.

### Step 2 — Strip Unnecessary Components (0:05–0:20)

Delete these from the **schematic** (Eeschema):

| Remove | Why |
|--------|-----|
| USB-C connector + ESD diodes | Charging via pogo pads instead |
| NFC antenna + matching network | Not needed for BLE-only use |
| User LEDs (×3) | Keep only 1 status LED |
| Extra decoupling caps beyond minimum | Only keep nRF52840 required caps |
| Debug header / SWD pads | Keep 2 test pads for programming (Tag-Connect or pogo) |
| Reset button | Not needed in sealed enclosure |

**Keep these (critical):**

| Keep | Why |
|------|-----|
| **nRF52840 (QFN48)** or **Fanstel BM840P module** | MCU + BLE radio. The BM840P is pre-certified (FCC/CE) and includes the crystal + antenna, saving layout work |
| **LSM6DSV16X** (upgrade from LSM6DS3) | IMU — better ±16g accuracy, lower noise, I2C/SPI |
| **BQ25101** | LiPo charger IC with power path |
| **32.768 kHz crystal + load caps** | Required for nRF52840 RTC (skip if using BM840P — it includes this) |
| **Power regulation passives** | LDO, decoupling caps per nRF52840 datasheet |
| **Battery connector pads** | JST-PH 2.0mm or solder pads |
| **1× status LED** | Single RGB or single-color for pairing/status |

### Step 3 — Choose MCU Approach

**Option A: Bare nRF52840 QFN48** (smaller, cheaper at 1k+)
- Requires PCB antenna trace or chip antenna
- Requires 32 MHz + 32.768 kHz crystals
- Requires FCC/CE certification ($$$ at scale)
- Board area: chip is 6×6mm, but antenna + passives add ~8×6mm

**Option B: Fanstel BM840P Module** (recommended for Phase 2)
- Pre-certified FCC/CE/IC — no certification cost
- Includes nRF52840, 32 MHz crystal, 32.768 kHz crystal, antenna
- Module size: 10.2 × 15.1mm — fits within 18×12mm with overhang on one axis
- Leaves room for IMU + charger on the remaining board area

> **Recommendation:** Use the BM840P for Phase 2 (100 units). Switch to bare nRF52840 QFN48 at Phase 3 (1k+ units) when certification cost amortizes.

### Step 4 — PCB Layout (0:20–0:45)

1. **Switch to PCB editor** (Pcbnew)
2. Set board outline to **18mm × 12mm** rectangle:
   - Edit → Board Setup → Board Outline
   - Or draw on `Edge.Cuts` layer
3. Set design rules:
   - Minimum trace width: **0.15mm** (JLCPCB 2-layer minimum)
   - Minimum clearance: **0.15mm**
   - Via drill: **0.3mm**, via diameter: **0.6mm**
   - Copper layers: **2** (front + back)
4. Place components:
   - **BM840P module** — top side, centered, antenna end at board edge (keep copper-free zone under antenna)
   - **LSM6DSV16X** — bottom side, center of board (away from board edge vibrations — actually center is best for IMU accuracy)
   - **BQ25101** — bottom side, near battery pads
   - **Passives (0402)** — fill remaining space on both sides
5. Set grid snap to **0.1mm** for precise placement
6. Route traces at **0.15mm width** (signal), **0.3mm width** (power)
7. Add ground plane (copper pour) on both layers

### Step 5 — Mounting & Connector Pads (0:45–0:55)

1. Add **2× M1.2 mounting holes** at diagonal corners (fits plug M1.2 standoffs)
   - Hole pattern: **16mm × 10mm** (corner-to-corner)
2. Add **battery pads** (2× solder pads, 1.5mm × 2mm) on one edge — for JST-PH or direct solder
3. Add **2× pogo/programming pads** (SWDIO, SWCLK) on the edge — for factory flashing via Tag-Connect
4. Add **charge pads** (2× pads) on the endcap-facing edge — for pogo-pin charging through endcap
5. Add **1× LED pad** (0603 footprint) near board edge

### Step 6 — DRC & Export (0:55–1:00)

1. Run **DRC** (Design Rule Check) — fix any violations
2. Verify all nets are routed (no unconnected ratsnest lines)
3. Export manufacturing files:
   - **File → Fabrication Outputs → Gerbers** (.gbr) — all layers
   - **File → Fabrication Outputs → Drill Files** (.drl)
   - **File → Fabrication Outputs → Component Placement** (.pos) — for pick-and-place
   - **File → BOM** — export from schematic
4. Package Gerbers + drill files into a single ZIP for JLCPCB upload

---

## JLCPCB Order Guide (Turnkey PCBA)

### Ordering Workflow

1. Go to **jlcpcb.com** → **Order Now**
2. Upload the **Gerber ZIP** file
3. Configure PCB:
   - Layers: **2**
   - Dimensions: **18 × 12mm**
   - Qty: **100** (minimum for PCBA pricing)
   - Surface finish: **ENIG** (better for fine-pitch QFN pads)
   - Board thickness: **1.0mm** (thinner = lighter)
   - Copper weight: **1 oz**
4. Enable **SMT Assembly**:
   - Assembly side: **Both** (components on front + back)
   - Upload **BOM** and **Pick & Place** files
   - JLCPCB auto-matches parts from LCSC inventory
5. Review component placements in the online viewer
6. Place order — expect **7–10 business days** for PCBA

### Cost Breakdown (100 boards)

| Item | Unit Cost | Total (100) |
|------|-----------|-------------|
| PCB fabrication (18×12mm, 2-layer, ENIG) | $1.80 | $180 |
| SMT assembly fee | $2.50 | $250 |
| Components (BOM total per board) | ~$8.17 | $817 |
| **Total per board (assembled)** | **~$12.47** | **$1,247** |

> Add ~$30–50 for shipping. First order may include $8 engineering setup fee.

---

## Phase 2 Board Pinout

```
              18mm
    ┌──────────────────────┐
    │  ┌────────────────┐  │
    │  │   BM840P       │  │  ← Top side
    │  │   nRF52840     │  │    Pre-certified BLE module
    │  │   + antenna    │  │    10.2 × 15.1mm
    │  └────────────────┘  │
    │  [CHG+] [CHG−]       │  ← Pogo charge pads (endcap edge)
    │  [LED]               │  ← Status LED
    ├──────────────────────┤
    │  ┌────────┐ ┌─────┐  │
    │  │LSM6DSV │ │BQ251│  │  ← Bottom side
    │  │  16X   │ │ 01  │  │    IMU + LiPo charger
    │  └────────┘ └─────┘  │
    │  [BAT+] [BAT−]       │  ← Battery solder pads
12mm│  [SWD] [CLK]         │  ← Programming pads
    └──────────────────────┘
    ○                    ○     ← M1.2 mounting holes
```

---

## Firmware Changes for Phase 2

The firmware (`hardware/firmware/laxpod/`) needs minor updates for the custom board:

| Change | Phase 1 | Phase 2 |
|--------|---------|---------|
| IMU driver | LSM6DS3 (existing `imu.cpp`) | LSM6DSV16X — different register set, same I2C address option |
| Pin assignments | XIAO pinout (D0–D10) | Direct nRF52840 GPIO numbers (P0.xx) |
| USB | USB-C serial for debug | Remove USB init, use SWD for debug |
| Charging detection | XIAO charge LED pin | BQ25101 STAT pin → GPIO interrupt |
| BLE | Same | Same (nRF52840 softdevice identical) |
| Power management | Same | Add charge-pad detection (pogo pin sense) |

> The BLE protocol, shot detection algorithm, and Madgwick filter remain **identical** between Phase 1 and Phase 2.

---

## Impact on Enclosure Design

The smaller board changes the plug internal layout:

| Dimension | Phase 1 (XIAO) | Phase 2 (Custom) |
|-----------|----------------|------------------|
| Board bay length | 24mm | 14mm |
| Board bay width | 17.8mm | 12mm |
| Rail spacing | 17.8mm | 12mm |
| Standoff pattern | 21 × 17.8mm (M1.6) | 16 × 10mm (M1.2) |
| Total plug length | ~65mm | ~50mm |
| Battery + board can stack vertically | No (side-by-side) | Yes (board is narrow enough) |

**Phase 2 Plug Axial Stack:**

| Section | Length | Contents |
|---|---|---|
| Endcap wall | 5mm | Sealed face with charge pads + LED window |
| Board bay | 14mm | Custom PCB on M1.2 standoffs |
| Battery bay | 23mm | 402025 LiPo (both men's & women's — board is narrow enough now!) |
| O-ring zone | 8mm | 2 circumferential O-ring grooves |
| **Total** | **~50mm** | **~1.97"** |

> Key win: the 12mm-wide board fits comfortably inside the women's plug cavity (15.5mm Ø), which means **both men's and women's versions can use the same 402025 battery** (20mm wide fits when board and battery stack axially rather than side-by-side).

---

## Phase 2 Timeline

| Step | Duration | Dependencies |
|------|----------|-------------|
| KiCad schematic cleanup | 2–3 hours | Seeed source files downloaded |
| PCB layout (18×12mm) | 3–4 hours | Schematic finalized |
| DRC + Gerber export | 30 min | Layout complete |
| JLCPCB order | 15 min | Gerbers + BOM ready |
| PCB fabrication + assembly | 7–10 days | Order placed |
| Firmware port (IMU driver + pins) | 2–3 hours | Boards received |
| Enclosure update (Fusion 360) | 1–2 hours | Board dimensions confirmed |
| Assembly + test | 1 hour per unit | All parts in hand |
