# LaxShot

> **Beta** — Youth lacrosse shot analysis app with AI-powered coaching.

LaxShot records a player's (or goalie's) shot on video, analyzes shooting form using on-device ML, classifies the shot type across men's and women's lacrosse, and delivers personalized coaching tips so players can improve every session.

---

## Beta Status

| Area | Status | Notes |
|------|--------|-------|
| Auth (Email / Google / Apple) | ✅ Functional | Firebase Auth |
| COPPA compliance | ✅ Functional | Age gate, parental consent flow |
| Camera / video recording | ✅ Functional | 3-2-1 countdown, player & goalie modes |
| Shot analysis engine | ⚠️ Placeholder | Heuristic scoring — real TFLite inference pending |
| Shot classification (17 types) | ✅ Complete | Men's & women's lacrosse |
| Coaching tips engine | ✅ Complete | Per-shot-type tips, drills, strengths |
| Stats dashboard & heatmap | ✅ Functional | Lifetime stats, zone accuracy, streaks |
| Achievements | ✅ Functional | 6 badges (first_shot → consistent) |
| Profile & settings | ✅ Functional | Position, mode toggle, account delete |
| CI pipeline | ✅ Active | GitHub Actions: analyze, test, build |

---

## Features

### Shot Recording
Record shots or saves through the in-app camera with a 3-2-1 countdown timer. Toggle between **Player** and **Goalie** modes. Videos stay on-device — nothing is uploaded without explicit action.

### Shot Classification
17 recognized shot types across men's and women's lacrosse:

| Shared (7) | Men's Only (5) | Women's Only (4) |
|------------|----------------|-------------------|
| Overhand | Shovel Shot | Draw Shot |
| Sidearm | Bat Down / Deflection | Free Position (8m) |
| Underhand | Air Gait (Dive Shot) | 12-Metre Fan Shot |
| Behind the Back | Worm Burner | Shovel (Women's) |
| On the Run | Fake & Shoot | |
| Quick Stick | | |
| Bounce Shot | | |

### AI Coaching
After each analysis, the coaching engine generates:
- **Overall score** (0–100) with per-mechanic breakdown (hip rotation, wrist snap, follow-through, etc.)
- **Prioritized coaching tips** — weakest mechanics first, with shot-type-specific context
- **Strengths** — what you're already doing well
- **Drill recommendations** — targeted practice for your weakest area
- **Quick cue** — one-line reminder for the field

### Stats & Progress
- 3×3 goal zone accuracy heatmap
- Session history with score trends
- Lifetime accuracy tracking
- Streak tracking (consecutive practice days)

### Achievements
Six unlockable badges: First Shot 🥍, Sharpshooter 🎯, 7-Day Streak 🔥, Century Club 💯, All Zones ✅, Consistent 📈

### COPPA Compliance
Built for youth players from the ground up:
- Age gate at signup (DOB required)
- Automatic minor detection (age < 13)
- Parental consent flow via Cloud Function email
- Router guards block minors until parent approves
- Minimal data collection, no social features for minors
- 48dp touch targets (WCAG + youth UX)

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.41+ / Dart 3.11+ |
| State | Riverpod (StreamProvider, FutureProvider, AsyncNotifier) |
| Navigation | GoRouter with auth + COPPA redirect guards |
| Backend | Firebase (Auth, Firestore, Storage, Analytics, Cloud Functions) |
| ML | On-device inference (TFLite — placeholder in beta) |
| Charts | fl_chart + custom GoalZoneHeatmap painter |
| Auth | Email/Password, Google Sign-In, Sign In with Apple |
| CI | GitHub Actions (analyze, test, build iOS/Android) |

---

## Project Structure

```
lacrosse-app/
├── .github/workflows/     ← CI pipeline (flutter-ci.yml)
├── .openclaw/              ← OpenClaw agent configurations
├── src/
│   └── app/laxshot/        ← Flutter application
│       ├── lib/
│       │   ├── core/       ← Theme, colors, sizes, routes, utils
│       │   ├── data/       ← Models, repositories, services
│       │   ├── features/   ← Auth, camera, analysis, stats, profile
│       │   ├── presentation/ ← App root, router, shared widgets
│       │   └── main.dart
│       ├── ios/            ← iOS platform config
│       ├── macos/          ← macOS platform config
│       ├── android/        ← Android platform config
│       └── pubspec.yaml
├── setup-openclaw.sh       ← Agent wiring script
└── README.md
```

---

## Getting Started

### Prerequisites
- Flutter 3.41+ (stable channel)
- Xcode 26+ (for iOS/macOS)
- A Firebase project with Auth, Firestore, and Cloud Functions enabled

### 1. Clone & install

```bash
git clone <this-repo> lacrosse-app
cd lacrosse-app/src/app/laxshot
flutter pub get
```

### 2. Configure Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

Or use the existing `lib/firebase_options.dart` if you have the `laxshot-app-d44c9` project access.

### 3. Run

```bash
# iOS simulator
flutter run -d "iPhone 17"

# macOS desktop
flutter run -d macos

# Android
flutter run -d <device>
```

### 4. Run tests & analysis

```bash
flutter test
flutter analyze
```

---

## OpenClaw Agents

Four AI agents collaborate on this project via [OpenClaw](https://docs.openclaw.ai):

| Agent | ID | Emoji | Role |
|---|---|---|---|
| **BackClaw** | `engineering-backend` | ⚙️ | API, database, server infrastructure |
| **FrontClaw** | `engineering-frontend` | 🎨 | Mobile app, UI, components |
| **LaxForge** | `hardware` | 🔧 | Sensor pod firmware, enclosure, BLE protocol |
| **PitchClaw** | `marketing` | 📣 | Campaigns, copy, ASO, growth |

### Agent setup

```bash
npm install -g openclaw@latest   # Node 22.16+
chmod +x setup-openclaw.sh
./setup-openclaw.sh
openclaw gateway
```

### Talking to agents

```bash
openclaw agent --message "What's the data model?"                              # → BackClaw (default)
openclaw agent --agent marketing --message "Draft an App Store description"     # → PitchClaw
openclaw agent --agent engineering-frontend --message "What screens exist?"     # → FrontClaw
openclaw agent --agent hardware --message "What's the latest sensor protocol?"   # → LaxForge
```

Agents can message each other using `sessions_send` (cross-agent messaging is enabled). Agent workspaces live in `.openclaw/workspace-*/`.

---

## Known Beta Limitations

- **ML inference is placeholder** — the analysis engine returns heuristic scores with realistic ranges. Real TFLite pose detection will be integrated once `tflite_flutter` is compatible with Dart 3.11+.
- **Shot type auto-classification not yet wired** — users will eventually be able to have their shot type auto-detected from pose data. Currently the coaching engine accepts a manually specified shot type.
- **`google_mlkit_pose_detection` disabled** — incompatible with iOS simulator on Apple Silicon (arm64). Works on physical devices.
- **No social / sharing features** — by design for COPPA compliance in beta.

---

## License

Private — all rights reserved.
