# Fusion 360 Enclosure Design Guide — LaxPod Butt-End Plug

Step-by-step guide for designing the LaxPod sensor enclosure in Autodesk Fusion 360. The plug inserts **inside** the hollow lacrosse shaft and acts as a game-legal replacement butt-end cap. Create **two versions**: men's (1" shaft) and women's (7/8" shaft).

**Design time:** ~25–35 minutes per version  
**Result:** A cylindrical plug, ~65mm long, that friction-fits inside any standard lacrosse shaft via O-ring grooves  
**Print:** SLA in Rigid 10K resin, 0.05mm layers, post-cure 60 min UV

---

## Lacrosse Shaft Reference Dimensions

Before designing, understand the shaft geometry the plug must fit inside.

### Standard Shaft Sizes

| | Men's / Field | Women's |
|---|---|---|
| **Shaft OD (outside)** | 1.000" (25.4mm) | 0.875" (22.225mm) |
| **Typical wall thickness** | 1.0–2.0mm | 1.0–2.0mm |
| **Estimated shaft ID (inside)** | 21.4–23.4mm | 18.2–20.2mm |
| **Target plug OD** | 21.5mm | 18.5mm |
| **O-ring seated OD** | ~22.0mm | ~19.0mm |

### Wall Thickness by Material

| Material | Typical Wall | Estimated ID (Men's) | Estimated ID (Women's) |
|----------|-------------|----------------------|------------------------|
| **Aluminum alloy** | 1.0–1.5mm | 22.4–23.4mm | 19.2–20.2mm |
| **Scandium alloy** | 1.0–1.2mm | 23.0–23.4mm | 19.8–20.2mm |
| **Carbon fiber** | 1.5–2.0mm | 21.4–22.4mm | 18.2–19.2mm |
| **Titanium** | 1.0–1.5mm | 22.4–23.4mm | 19.2–20.2mm |

### Cross-Section Profiles

Lacrosse shafts are **not always round**. Common profiles include:

- **Round** — standard, most common for aluminum
- **Octagonal** — popular for grip (STX Sci-Ti, ECD Carbon Pro 2.0)
- **Concave-sided** — slight inward curves per face (Maverik Hyperlite, StringKing Metal 3 Pro)

The plug uses **O-ring grooves** instead of rigid ribs to accommodate all profiles. The O-rings compress into gaps on octagonal/concave shafts while maintaining grip.

### Measuring Your Shaft ID

Players should measure their shaft's internal diameter before ordering:

1. Remove the existing butt-end cap
2. Insert a ruler or caliper into the open end
3. Measure the widest internal span (corner-to-corner for octagonal)
4. **Men's shafts:** expect 21–23mm. Order men's plug (21.5mm OD)
5. **Women's shafts:** expect 18–20mm. Order women's plug (18.5mm OD)

---

## Electronics Fit Budget

| Component | Width | Men's cavity (18.5mm Ø) | Women's cavity (15.5mm Ø) |
|---|---|---|---|
| XIAO nRF52840 Sense | 17.8mm | 0.7mm clearance ✓ | Rotated fit ✓ |
| Battery — men's (402025) | 20mm × 25mm × 4mm | Fits axially ✓ | N/A ✗ |
| Battery — women's (401730) | ~17mm × 30mm × 3.5mm | — | Fits axially ✓ |
| Button cutout | 3mm | ✓ | ✓ |
| LED window | 4mm Ø | ✓ | ✓ |

### Plug Internal Layout (axial stack, endcap → insertion end)

| Section | Length | Contents |
|---|---|---|
| Endcap wall | 5mm | Sealed face with button hole + LED window |
| XIAO bay | 24mm | Board on rail cradle, USB-C facing endcap |
| Battery bay | 28mm | LiPo pocket with foam tape retention |
| O-ring zone | 8mm | 2 circumferential O-ring grooves |
| **Total** | **~65mm** | **~2.56"** |

---

## Prerequisites

- Autodesk Fusion 360 installed (free for personal/startup use)
- Units set to **Millimeters** (Design → Document Settings → Units)
- Save to Project: "LaxPod Enclosure"

---

## Part 1: Plug Body

### Step 1 — Plug Outer Profile (0:00–0:30)

1. **Create Sketch** on the **XY plane**
2. Draw a **circle** centered at origin
   - Men's version: **Diameter = 21.5mm**
   - Women's version: **Diameter = 18.5mm**
3. **Finish Sketch**

### Step 2 — Extrude Solid Cylinder (0:30–1:00)

4. Select **Extrude** (Create menu)
5. Select the circle profile
6. Set distance to **65mm**
7. Click **OK** — you now have a solid cylinder

### Step 3 — Shell to Create Internal Cavity (1:00–1:30)

8. Select **Shell** command (Modify menu)
9. Click the **top face** of the cylinder (this becomes the open insertion end)
10. Set inside thickness to **1.5mm**
    - Men's internal cavity: **18.5mm Ø**
    - Women's internal cavity: **15.5mm Ø**
11. **OK** — the plug is now hollow with a sealed bottom (endcap) and open top

---

## Part 2: O-Ring Grooves

### Step 4 — O-Ring Groove Sketch (1:30–2:00)

12. **Create Sketch** on the **XZ plane** (side view, cutting through the plug centerline)
13. Near the **open end** (insertion end, top), draw **2 rectangular groove profiles**:
    - Groove width: **1.5mm**
    - Groove depth: **1.0mm** (from outer surface inward)
    - First groove center: **5mm from the open end**
    - Second groove center: **12mm from the open end** (7mm spacing)
14. **Finish Sketch**

### Step 5 — Revolve Cut the Grooves (2:00–2:15)

15. Select **Revolve** → **Cut** operation
16. Select both groove rectangles
17. Revolve **360°** around the plug center axis
18. **OK** — two circumferential grooves now ring the plug exterior
19. These grooves accept standard **1.5mm cross-section O-rings** (e.g., AS568-010 for men's, AS568-007 for women's)

---

## Part 3: Endcap Face

### Step 6 — Dome the Endcap (2:15–2:30)

20. Select the **bottom face** (sealed end — the visible butt-end when installed)
21. Use **Press Pull** or **Offset Face** to add a **1mm convex dome**
    - This matches the profile of stock lacrosse butt-end caps
22. Alternatively, sketch a **1mm arc** on the XZ plane and **Revolve** it for precise control

### Step 7 — Button & LED Holes (2:30–2:45)

23. **Create Sketch** on the **endcap face** (outer surface of the dome)
24. Cut a **3mm × 3mm square hole** for the tactile button (centered, slightly offset)
25. Cut a **4mm diameter circular hole** for the RGB LED window (adjacent to button)
26. **Extrude Cut** through the endcap wall (5mm depth)
27. These holes are flush with the endcap face — visible when the plug is installed in the shaft

---

## Part 4: XIAO Board Cradle

### Step 8 — Board Rails (2:45–3:15)

28. **Create Sketch** on the **interior floor of the endcap** (inside the cavity)
29. Draw **2 parallel rail profiles** running axially (along the plug length):
    - Rail width: **1.0mm**
    - Rail height: **1.0mm** (protruding into the cavity)
    - Spacing: **17.8mm apart** (matching XIAO board width)
    - Rail length: **22mm** (slightly shorter than the 24mm XIAO bay)
    - Centered in the cavity
30. **Extrude** the rails **22mm** away from the endcap floor
31. The XIAO board slides between these rails like a card in a slot

### Step 9 — Board Retaining Lip (3:15–3:30)

32. At the **endcap end** of each rail, add a small **retaining lip**:
    - Height: **0.5mm** inward from the rail face
    - Width: **1.0mm** (same as rail)
    - This prevents the board from sliding toward the endcap during impact
33. **Extrude** the lip features

### Step 10 — M1.6 Standoff Bosses (3:30–3:45)

34. On the **endcap interior floor**, place **4 standoff boss circles**:
    - Outer diameter: **3mm**, center hole: **M1.6 through**
    - Height: **2.5mm** (extrude toward the open end)
    - Pattern: **21mm × 17.8mm rectangle** matching XIAO mounting holes
    - USB-C port end of the board faces the endcap (for future charging-port access)
35. **Extrude** the bosses

---

## Part 5: Battery Pocket

### Step 11 — Battery Recess (3:45–4:15)

36. **Create Sketch** on the interior wall, **24mm from the endcap floor** (just past the XIAO bay)
37. Sketch a **rectangular pocket** recessed into the plug wall:
    - **Men's version:** 20mm × 25mm × 4mm deep (fits 402025 LiPo)
    - **Women's version:** 17mm × 30mm × 3.5mm deep (fits 401730 or similar narrow LiPo)
38. **Extrude Cut** the pocket into the cavity wall/floor
39. Add a **wire routing channel** (1mm × 1mm) from the battery pocket toward the XIAO bay
40. The battery is retained by double-sided foam tape on the pocket floor

---

## Part 6: Styling & Export

### Step 12 — Fillets & Chamfers (4:15–4:30)

41. Select the **outer edge of the endcap face** (where dome meets cylinder)
42. Apply **1.0mm fillet** — smooth transition from dome to cylinder body
43. Select the **open end** (insertion end) outer edge
44. Apply **0.5mm chamfer** — eases insertion into the shaft
45. Optional: Add a **0.5mm debossed ring** around the plug body (10mm from endcap) for a team-color silicone inlay band

### Step 13 — Duplicate for Women's Version (4:30–4:45)

46. **Save** the current design as "LaxPod_Plug_Mens"
47. **Save As** → rename to "LaxPod_Plug_Womens"
48. Edit the outer circle sketch → change diameter from **21.5mm** to **18.5mm**
49. Shell thickness remains **1.5mm** → internal cavity becomes **15.5mm Ø**
50. Update battery pocket from **20×25×4mm** to **17×30×3.5mm**
51. Rails remain at **17.8mm spacing** (XIAO board same size in both)
52. Update O-ring groove diameters to match new plug OD
53. Verify board and battery still clear the interior walls

### Step 14 — STL Export (4:45–5:00)

54. Select the **plug body** → File → 3D Print → **Save as STL**
    - Resolution: High
    - Name: `laxpod_plug_mens_1inch.stl`
55. Repeat for women's:
    - Name: `laxpod_plug_womens_7_8inch.stl`
56. No separate lid STL needed — the endcap is part of the plug body
57. Save the Fusion 360 project as **.f3d**

---

## Game Legality Notes

The plug is designed to comply with NCAA and NFHS equipment rules:

- **NCAA Rule 1, Section 24**: All sticks must have a butt-end cap. The LaxPod plug acts as the butt-end cap.
- **NFHS Rule 1-7-1**: The butt end must be covered with a cap. No protrusions allowed.
- **Design compliance**: The endcap face is flush with or slightly recessed from the shaft end. No electronics protrude. The domed profile matches stock end caps.
- **Referee inspection**: The plug looks and feels like a standard butt-end cap from the outside. Button and LED holes are small (3–4mm) and flush.

> **Note:** Always check with your league or official before game use. This design targets compliance but has not been formally certified.

---

## Print Settings

See `print_settings.md` for full SLA print configuration, material options, and Xometry ordering guide.

| Parameter | Value |
|-----------|-------|
| Printer | SLA (Form 3+, Xometry, or similar) |
| Material | Rigid 10K resin (strong, heat-resistant) |
| Layer Height | 0.05mm |
| Supports | Auto-generate, light touchpoints |
| Orientation | Print plug upright (endcap face down on build plate) for best surface finish on the visible endcap |
| Post-Cure | 60 minutes UV at 60°C |
| Tolerance | ±0.1mm (SLA is excellent for friction fits) |

## Test Fit Checklist

- [ ] Plug slides into bare 1" shaft (men's) / 0.875" shaft (women's) with O-rings seated
- [ ] O-rings provide snug grip — plug doesn't fall out when shaft is inverted
- [ ] Plug doesn't wobble or rotate inside the shaft
- [ ] Endcap face is flush with shaft end
- [ ] Button hole aligns with XIAO onboard button
- [ ] LED window shows RGB LED clearly
- [ ] XIAO sits flat on rail cradle, secured by M1.6 screws or hot glue
- [ ] Battery fits in pocket with JST connector routed to board
- [ ] Total weight < 0.4 oz (11g) with electronics

## Dimensions Reference

| Measurement | Men’s | Women’s |
|-------------|-------|--------|
| Plug OD | 21.5mm | 18.5mm |
| Internal cavity Ø | 18.5mm | 15.5mm |
| Wall thickness | 1.5mm | 1.5mm |
| Total plug length | 65mm | 65mm |
| O-ring groove width | 1.5mm | 1.5mm |
| O-ring groove depth | 1.0mm | 1.0mm |
| Endcap dome height | 1.0mm | 1.0mm |
| Rail spacing (XIAO width) | 17.8mm | 17.8mm |
| Battery pocket (men’s) | 20×25×4mm | — |
| Battery pocket (women’s) | — | 17×30×3.5mm |
---

## Phase 2 Enclosure Changes (Custom 18×12mm PCB)

When transitioning from the Phase 1 XIAO board (21×17.8mm) to the Phase 2 custom PCB (18×12mm), the plug design gets significantly smaller and simpler. See [pcb/README.md](../pcb/README.md) for the full custom PCB guide.

### Key Dimensional Changes

| Dimension | Phase 1 (XIAO) | Phase 2 (Custom) |
|-----------|----------------|------------------|
| Board bay length | 24mm | 14mm |
| Board bay width (rail spacing) | 17.8mm | 12mm |
| Standoff pattern | 21 × 17.8mm (M1.6) | 16 × 10mm (M1.2) |
| Total plug length | 65mm | **~50mm** |
| Battery | Men's 402025 / Women's 401730 | **402025 for both** (board is narrow enough) |

### Phase 2 Axial Stack

| Section | Length | Contents |
|---|---|---|
| Endcap wall | 5mm | Sealed face with charge pads + LED window |
| Board bay | 14mm | Custom 18×12mm PCB on M1.2 standoffs |
| Battery bay | 23mm | 402025 LiPo (same battery for both men's and women's) |
| O-ring zone | 8mm | 2 circumferential O-ring grooves |
| **Total** | **~50mm** | **~1.97"** |

### What Changes in Fusion 360

1. **Step 2**: Extrude cylinder to **50mm** (was 65mm)
2. **Step 8**: Rails spaced **12mm** apart (was 17.8mm), length **12mm** (was 22mm)
3. **Step 10**: Standoff pattern **16 × 10mm** with **M1.2** holes (was 21 × 17.8mm M1.6)
4. **Step 11**: **Both versions** use 20×25×4mm battery pocket (no separate women's pocket)
5. **Step 7**: Replace button hole with **pogo charge pad recesses** (2× Ø2mm, 4mm apart) + LED window
6. **Step 14**: Export as `laxpod_plug_v2_mens_1inch.stl` / `laxpod_plug_v2_womens_7_8inch.stl`

> The 15mm shorter plug improves feel and reduces weight. Both shaft sizes now use the same 300mAh battery.