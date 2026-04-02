# SLA Print Settings — LaxPod Enclosure

## Recommended Settings

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Process** | SLA (Stereolithography) | Not FDM — need tight tolerances |
| **Material** | Formlabs Rigid 10K Resin | High stiffness, heat-resistant, IP67-capable |
| **Layer Height** | 0.050 mm | Fine detail for friction-fit bore |
| **Build Orientation** | Body upside-down (bore opening facing up) | Best surface finish on outer shell |
| **Supports** | Auto-generated, light touchpoints | Minimize scars on friction surfaces |
| **Post-Cure** | 60 minutes UV at 60°C | Required for full mechanical properties |

## Alternative Materials

| Material | Pros | Cons | Use Case |
|----------|------|------|----------|
| **Rigid 10K** | Stiff, precise, heat-resistant | Brittle under high impact | Final game-ready prototype |
| **Tough 2000** | Impact-resistant, slight flex | Less precise bore tolerance | Drop/impact testing |
| **Durable** | Flexible, fatigue-resistant | Too soft for friction fit | Grip testing only |
| **Standard** | Cheapest, good detail | Brittle, not UV-stable | Fit-check prints only |

## Tolerance Notes

- SLA accuracy: **±0.1mm** (excellent for friction fits)
- Design the bore to be **exact shaft OD** (1.000" or 0.875") — the grip ribs provide the clamping force
- If the fit is too loose: sand the inner bore ribs lightly
- If the fit is too tight: file the grip ribs down 0.01–0.02"

## Xometry Order Guide

1. Go to https://www.xometry.com/ → **Get Instant Quote**
2. Upload STL files:
   - `laxpod_body_mens_1inch.stl` × 3
   - `laxpod_body_womens_7_8inch.stl` × 2
   - `laxpod_lid.stl` × 5
3. Select: **SLA** → **Rigid 10K** (or nearest equivalent)
4. Finish: **Standard** (no post-processing needed)
5. Expected turnaround: **5–7 business days**
6. Expected cost: **~$15–25 per body, ~$5–8 per lid**

## Self-Print Guide (if you have an SLA printer)

1. Import STL into your slicer (PreForm for Formlabs, Chitubox for others)
2. Orient body upside-down, lid flat
3. Generate supports (0.4mm touchpoints)
4. Print at 0.05mm layer height
5. Wash in IPA for 10 minutes
6. Air dry 15 minutes
7. UV cure: 60 minutes at 60°C (Form Cure or UV nail lamp)
8. Remove supports carefully, sand any nubs with 400-grit
9. Test fit on shaft immediately — adjust if needed before printing more
