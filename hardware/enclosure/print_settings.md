# SLA Print Settings — LaxPod Butt-End Plug

## Recommended Settings

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Process** | SLA (Stereolithography) | Not FDM — need tight tolerances for O-ring grooves |
| **Material** | Formlabs Rigid 10K Resin | High stiffness, heat-resistant, IP67-capable |
| **Layer Height** | 0.050 mm | Fine detail for O-ring grooves and board rails |
| **Build Orientation** | Plug upright, endcap face down on build plate | Best surface finish on visible endcap face |
| **Supports** | Auto-generated, light touchpoints | Keep supports away from O-ring groove surfaces |
| **Post-Cure** | 60 minutes UV at 60°C | Required for full mechanical properties |

## Alternative Materials

| Material | Pros | Cons | Use Case |
|----------|------|------|----------|
| **Rigid 10K** | Stiff, precise, heat-resistant | Brittle under high impact | Final game-ready prototype |
| **Tough 2000** | Impact-resistant, slight flex | Less precise groove tolerance | Drop/impact testing |
| **Durable** | Flexible, fatigue-resistant | Too soft for O-ring retention | Grip testing only |
| **Standard** | Cheapest, good detail | Brittle, not UV-stable | Fit-check prints only |

## Tolerance Notes

- SLA accuracy: **±0.1mm** (excellent for O-ring grooves and board rail fits)
- Design the plug OD to be **~0.5–1mm smaller** than the minimum expected shaft ID
- O-rings provide the grip and seal — the plug body itself should slide in freely without O-rings
- If the fit is too loose with O-rings: use thicker O-rings (next size up in cross-section)
- If the fit is too tight: lightly sand the plug exterior or use thinner O-rings

## Xometry Order Guide

1. Go to https://www.xometry.com/ → **Get Instant Quote**
2. Upload STL files:
   - `laxpod_plug_mens_1inch.stl` × 3
   - `laxpod_plug_womens_7_8inch.stl` × 2
3. Select: **SLA** → **Rigid 10K** (or nearest equivalent)
4. Finish: **Standard** (no post-processing needed)
5. Expected turnaround: **5–7 business days**
6. Expected cost: **~$12–20 per plug** (single body, no separate lid)

### Fit-Check Order (Optional First Step)

Before ordering Rigid 10K, consider a cheaper fit-check print:

1. Order **1× men's + 1× women's** in **Standard resin** (~$8–12 each)
2. Test fit in your lacrosse shaft(s) with O-rings installed
3. Verify O-ring grip, board rail fit, and battery pocket clearance
4. Adjust dimensions in Fusion 360 if needed, then order final Rigid 10K batch

## O-Ring Sizing Reference

| Version | Plug OD | Groove ID | O-Ring ID | O-Ring Cross-Section | AS568 Size |
|---------|---------|-----------|-----------|---------------------|------------|
| **Men's** | 21.5mm | 19.5mm | ~19mm | 1.5mm | ~AS568-010 |
| **Women's** | 18.5mm | 16.5mm | ~16mm | 1.5mm | ~AS568-007 |

- Material: **Nitrile (NBR)** or **Silicone** — both work well
- Quantity needed: **2 per plug** (10 total for 5 units + spares)
- Grooves are **1.5mm wide × 1.0mm deep** — O-ring sits ~0.5mm proud of the plug surface

## Self-Print Guide (if you have an SLA printer)

1. Import STL into your slicer (PreForm for Formlabs, Chitubox for others)
2. Orient plug upright — endcap face flat on the build plate
3. Generate supports (0.4mm touchpoints), avoid supports inside O-ring grooves
4. Print at 0.05mm layer height
5. Wash in IPA for 10 minutes
6. Air dry 15 minutes
7. UV cure: 60 minutes at 60°C (Form Cure or UV nail lamp)
8. Remove supports carefully, sand any nubs with 400-grit
9. Test fit O-rings in grooves immediately — they should snap in and sit snug
10. Test fit in shaft with O-rings — adjust if needed before printing more
