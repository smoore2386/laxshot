# Fusion 360 Enclosure Design Guide — LaxPod Butt-Cap

Step-by-step narrated guide for designing the LaxPod sensor enclosure in Autodesk Fusion 360. Create **two versions**: men's (1.0" bore) and women's (7/8" bore).

**Design time:** ~20–30 minutes per version  
**Result:** A compact Marucci CATX-style replacement butt-cap, 1.6" long × 1.25" max OD  
**Print:** SLA in Rigid 10K resin, 0.05mm layers, post-cure 60 min UV

---

## Prerequisites

- Autodesk Fusion 360 installed (free for personal/startup use)
- Units set to **Inches** (Design → Document Settings → Units)
- Save to Project: "LaxPod Enclosure"

---

## Part 1: Main Body

### Step 1 — Shaft Bore Circle (0:00–0:30)

1. **Create Sketch** on the **XY plane**
2. Draw a **circle** centered at origin
   - Men's version: **Diameter = 1.000"**
   - Women's version: **Diameter = 0.875"**
3. **Offset** the circle outward by **0.125"**
   - This creates the outer wall circle at **1.250" diameter** (men's) or **1.125"** (women's)
4. **Finish Sketch**

### Step 2 — Revolve to Create Cylinder (0:30–1:00)

5. Select **Revolve** (Create menu)
6. Select the profile between the inner and outer circles
7. Revolve **360°** around the Y-axis
8. Set height to **1.60 inches**
9. Click **OK** — you now have a hollow cylinder

### Step 3 — Shell the Top (1:00–1:15)

10. Select **Shell** command (Modify menu)
11. Click the **top face** of the cylinder
12. Set inside offset to **0.100"** (room for electronics)
13. **OK** — the interior is now hollow

### Step 4 — Internal Grip Ribs (1:15–1:30)

14. **Create Sketch** on the **bottom face** (where the shaft enters)
15. Draw **4 small rectangles** equally spaced around the inside of the bore:
    - Width: **0.050"**
    - Height from wall: **0.080"**
    - Spacing: 90° apart (12, 3, 6, 9 o'clock positions)
16. **Finish Sketch**
17. **Extrude** the rectangles **upward 0.30"**
18. These ribs press against the shaft wall for friction grip — identical to stock butt caps

---

## Part 2: Snap-Fit Lid

### Step 5 — Lid Body (1:30–1:45)

19. **Offset** the top face down by **0.150"** to create the lid thickness
20. **Create new body** for the lid (don't merge with main body)
21. Sketch a cap that matches the outer diameter with a **0.020" lip overhang**
    - The lip sits inside the main body rim

### Step 6 — Snap Hooks (1:45–2:00)

22. Around the lid perimeter, add **4 snap hooks**:
    - Depth: **0.040"**
    - Width: **0.15"**
    - Spacing: 90° apart
23. **Extrude** the hooks downward from the lid rim
24. Add a small **45° chamfer** on the hook leading edge for easy snap-in

### Step 7 — Button & LED Holes (2:00–2:15)

25. **Create Sketch** on the top face of the lid
26. Cut a **3mm × 3mm square hole** for the button (centered, slightly offset)
27. Cut a **4mm diameter circular hole** for the RGB LED window (adjacent to button)
28. **Extrude Cut** through the lid
29. These should be flush with the top surface

---

## Part 3: Electronics Mounting

### Step 8 — XIAO Board Standoffs (2:15–2:30)

30. **Create Sketch** inside the main body (bottom interior surface)
31. Place **4 standoff boss circles**:
    - Diameter: **0.12"** (3mm) outer, **M1.6 through-hole** center
    - Height: **0.100"** (extrude upward)
    - Pattern: **21mm × 17.8mm rectangle** matching XIAO nRF52840 Sense mounting holes
32. Position so the USB-C port faces the lid button hole
33. **Extrude** the bosses upward 0.100"

### Step 9 — Battery Pocket (2:30–2:45)

34. Adjacent to the XIAO standoffs, sketch a **rectangular pocket**:
    - Size: **22mm × 19mm × 4mm deep**
    - This fits the 402025 LiPo cell snugly
35. **Extrude Cut** the pocket into the interior floor
36. Add a small **wire routing channel** (1mm wide, 1mm deep) from battery pocket to XIAO area

---

## Part 4: Styling

### Step 10 — Fillets & Knob Look (2:45–3:00)

37. Select all **outer edges** of the main body
38. Apply **0.100" fillet** — rounds the profile to look like a Marucci knob
39. Add a subtle **0.5mm chamfer** at the very top rim (before the lid sits)
40. Optional: Add a **0.5mm groove** around the body (about 0.3" from the top) for a team-color silicone inlay ring

### Step 11 — Duplicate for Women's Version (3:00–3:15)

41. **Save** the current design
42. **Save As** → rename to "LaxPod_Womens"
43. Edit the inner bore sketch → change diameter from **1.000"** to **0.875"**
44. The outer diameter drops to **1.125"** (0.875 + 2×0.125)
45. All other dimensions stay the same
46. Verify grip ribs still contact the bore wall

---

## Part 5: Export

### Step 12 — STL Export (3:15–3:30)

47. Select the **main body** → File → 3D Print → **Save as STL**
    - Resolution: High
    - Name: `laxpod_body_mens_1inch.stl` (or `womens_7_8inch`)
48. Select the **lid** → Export STL separately
    - Name: `laxpod_lid.stl` (same lid fits both versions if outer rim matches)
49. Save the Fusion 360 project as **.f3d**

---

## Print Settings

| Parameter | Value |
|-----------|-------|
| Printer | SLA (Form 3+, Xometry, or similar) |
| Material | Rigid 10K resin (strong, heat-resistant) |
| Layer Height | 0.05mm |
| Supports | Auto-generate, light touchpoints |
| Orientation | Print body upside-down (bore opening up) for best surface finish on outer surface |
| Post-Cure | 60 minutes UV at 60°C |
| Tolerance | ±0.1mm (SLA is excellent for friction fits) |

## Test Fit Checklist

- [ ] Pod slides onto bare 1" shaft (men's) / 0.875" shaft (women's)
- [ ] Grip ribs provide snug friction — pod doesn't fall off when inverted
- [ ] Pod doesn't wobble or rotate on the shaft
- [ ] Snap-fit lid clicks securely and doesn't rattle
- [ ] Button hole aligns with XIAO onboard button
- [ ] LED window shows RGB LED clearly
- [ ] XIAO sits flat on standoffs, USB-C accessible through lid/side
- [ ] Battery fits in pocket with JST connector routed to board
- [ ] Total weight < 0.4 oz (11g) with electronics

## Dimensions Reference

| Measurement | Men's | Women's |
|-------------|-------|---------|
| Inner bore diameter | 1.000" | 0.875" |
| Outer body diameter | 1.250" | 1.125" |
| Wall thickness | 0.125" | 0.125" |
| Total length | 1.600" | 1.600" |
| Shell inside offset | 0.100" | 0.100" |
| Grip rib width | 0.050" | 0.050" |
| Grip rib height | 0.080" | 0.080" |
| Grip rib length | 0.300" | 0.300" |
| Lid depth | 0.150" | 0.150" |
| Lip overhang | 0.020" | 0.020" |
| Snap hook depth | 0.040" | 0.040" |
