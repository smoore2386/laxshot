# Phase 2 BOM — LaxPod Custom PCB (100 Units)

Custom 18×12mm PCB using JLCPCB turnkey assembly. All component prices reflect 100-unit LCSC/JLCPCB bulk pricing as of March 2026.

## Bill of Materials (Per Board)

| # | Item | Qty | Description / Specs | Unit Price (100 qty) | Total (100 boards) | Source |
|---|------|-----|---------------------|---------------------|---------------------|--------|
| 1 | Fanstel BM840P nRF52840 Module | 1 | Pre-certified BLE 5.4 module, 10.2×15.1mm, includes crystal + antenna | $4.80 | $480 | LCSC |
| 2 | LSM6DSV16XTR IMU | 1 | 6-axis, ±16g accel, ±2000°/s gyro, I2C/SPI, 2.5×3×0.83mm | $1.95 | $195 | LCSC |
| 3 | BQ25101 LiPo Charger IC | 1 | 1A charge, NTC input, power path management, SOT-23-6 | $0.65 | $65 | LCSC |
| 4 | 32.768 kHz Crystal | 1 | SMD 2-pad, 12.5 pF load (skip if BM840P includes RTC crystal) | $0.12 | $12 | LCSC |
| 5 | Load Capacitors (12 pF) | 2 | 0402, C0G/NP0, for 32.768 kHz crystal | $0.12 | $24 | LCSC |
| 6 | Passives (resistors, caps, inductors) | ~15 | 0402/0603, 1% resistors, MLCC caps, ferrite beads | $0.05 avg | $75 | LCSC |
| 7 | Status LED | 1 | 0603 RGB or single-color, low-power | $0.08 | $8 | LCSC |
| 8 | PCB Fabrication (18×12mm, 2-layer, ENIG) | 1 | JLCPCB fab, 1.0mm thickness, ENIG finish | $1.80 | $180 | JLCPCB |
| 9 | SMT Assembly Fee | 1 | JLCPCB pick-and-place, both sides | $2.50 | $250 | JLCPCB |

### Per-Board Component Subtotal: **~$12.47**

---

## Off-Board Components (Per Unit)

| # | Item | Qty | Description | Unit Price (100 qty) | Total (100 units) | Source |
|---|------|-----|-------------|---------------------|---------------------|--------|
| 10 | 300mAh 3.7V LiPo Battery | 1 | 402025 form (20×25×4mm), JST-PH 2.0mm or bare leads | $3.10 | $310 | DigiKey / LCSC |
| 11 | LaxPod Plug Enclosure (injection molded) | 1 | ABS/Nylon, men's or women's variant | $1.50–2.00 | $150–200 | JLCPCB 3D / injection mold vendor |
| 12 | Nitrile O-Rings | 2 | 1.5mm cross-section, sized per shaft variant | $0.05 | $10 | LCSC / Amazon bulk |
| 13 | Pogo Pin Charge Cable | 0.1 | Shared charging cable (1 per ~10 units sold) | $2.00 | $20 | AliExpress / custom |

### Per-Unit Off-Board Subtotal: **~$6.15–6.65**

---

## Total Cost Summary (100 Units)

| Category | Per Unit | Total (100) |
|----------|----------|-------------|
| Custom PCB (assembled) | $12.47 | $1,247 |
| Battery | $3.10 | $310 |
| Enclosure (3D print or low-volume mold) | $1.50–2.00 | $150–200 |
| O-Rings | $0.10 | $10 |
| Charging cable (shared, amortized) | $0.20 | $20 |
| **Total per unit** | **~$17.37–17.87** | **$1,737–1,787** |

---

## Cost at Scale

| Quantity | PCB + Assembly | Battery | Enclosure | O-Rings | **Total/Unit** |
|----------|---------------|---------|-----------|---------|---------------|
| **5 (Phase 1, XIAO)** | $15.99 | $3.50 | $15.00 | $0.60 | **~$35.09** |
| **100 (Phase 2)** | $12.47 | $3.10 | $1.50–2.00 | $0.10 | **~$17.17–17.67** |
| **1,000 (Phase 3)** | ~$9.00 | $2.50 | $1.00 | $0.05 | **~$12.55** |

> At 1k+ quantity, switch from BM840P module to bare nRF52840 QFN48 (~$2.50 vs $4.80) and use injection-molded enclosures (~$3k one-time tooling, ~$1.00/unit).

---

## Key Component Notes

### Fanstel BM840P vs Bare nRF52840

- **BM840P** ($4.80): Pre-certified FCC/CE/IC. Includes 32 MHz crystal, 32.768 kHz crystal, antenna, matching network. No RF layout expertise needed. Recommended for 100-unit run.
- **Bare nRF52840** (~$2.50 at 1k): Requires PCB antenna trace design, crystal layout, and FCC/CE certification ($5k–15k). Only cost-effective at 1k+ units.

### LSM6DSV16X vs LSM6DS3

- **LSM6DSV16X** ($1.95): Newer, lower noise, better accuracy at ±16g, hardware sensor fusion features, QVAR touch sensing (unused). Pin-compatible I2C address options.
- **LSM6DS3** ($1.50): Phase 1 IMU. Adequate but older. Firmware driver needs rewriting for DSV16X register set.

### BQ25101

- Same charger IC used on the XIAO nRF52840. Proven circuit — copy the Seeed reference design exactly.
- Charge current set by a single resistor ($R_{ISET}$). Use 1kΩ for 1A charge (300mAh battery charges in ~20 min).

### Battery (Both Phases Share 402025)

- Phase 2 board at 12mm wide fits inside both men's (18.5mm cavity) and women's (15.5mm cavity) plugs
- This means **both shaft sizes can use the same 402025 (300mAh) battery** — no more separate women's battery!
- Battery sits axially above the board (stacked), not side-by-side

---

## Ordering Checklist (100 Units)

### JLCPCB Order
- [ ] Gerber ZIP uploaded
- [ ] BOM CSV uploaded (LCSC part numbers)
- [ ] Pick-and-place (.pos) file uploaded
- [ ] PCB specs: 2-layer, 18×12mm, 1.0mm thick, ENIG
- [ ] Assembly: both sides, confirm all parts sourced
- [ ] Review placement in online viewer
- [ ] Order placed (~$1,250 total)

### Separate Procurement
- [ ] 100× 300mAh LiPo 402025 batteries (DigiKey/LCSC)
- [ ] 100× enclosures (50 men's + 50 women's, or adjust split)
- [ ] 200× O-rings (sized per shaft variant)
- [ ] 10× pogo-pin charge cables
- [ ] Tag-Connect programming cable (1× for firmware flashing)

### Firmware Prep
- [ ] Port IMU driver from LSM6DS3 → LSM6DSV16X
- [ ] Update pin assignments (XIAO pinout → direct nRF52840 GPIO)
- [ ] Remove USB serial init (no USB-C on Phase 2 board)
- [ ] Add pogo-pin charge detection
- [ ] Test BLE advertising with BM840P module
- [ ] Compile + flash via SWD (Tag-Connect or pogo jig)
