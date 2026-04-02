# LaxShot — Flutter App

> **v1.0.0-beta** — Youth lacrosse analysis app with AI-powered shot coaching.

---

## Architecture

Clean architecture with Riverpod state management and GoRouter navigation.

```
lib/
├── core/             ← Config, constants, theme, utils
│   ├── constants/    ← AppColors, AppSizes, AppRoutes
│   ├── theme/        ← Material theme configuration
│   └── utils/        ← Shared utilities
├── data/
│   ├── models/       ← Firestore-backed data classes
│   ├── repositories/ ← Firestore read/write layer
│   └── services/     ← Auth, ML analysis, coaching engine
├── features/
│   ├── auth/         ← Login, signup, age gate, parental consent
│   ├── camera/       ← Video recording (player & goalie modes)
│   ├── analysis/     ← ML analysis, coaching report, results UI
│   ├── stats/        ← Dashboard, heatmap, achievements
│   └── profile/      ← Profile, settings
├── presentation/     ← App root, GoRouter, shared widgets
└── main.dart
```

### Stack

| Layer | Technology |
|-------|------------|
| State | `flutter_riverpod` — StreamProvider, FutureProvider, AsyncNotifier |
| Navigation | `go_router` — declarative routes with auth + COPPA redirect guards |
| Backend | Firebase (Auth, Firestore, Storage, Analytics, Cloud Functions) |
| ML | On-device TFLite inference (placeholder scoring in beta) |
| Charts | `fl_chart` + custom `GoalZoneHeatmap` painter |
| Auth | Email/Password, Google Sign-In, Sign In with Apple |

---

## Screens

| Route | Screen | Notes |
|---|---|---|
| `/onboarding` | AgeGateScreen | DOB picker → COPPA gate for under-13 |
| `/parental-consent` | ParentalConsentScreen | Parent email → Cloud Function notification |
| `/login` | LoginScreen | Email + Google + Apple sign-in |
| `/signup` | SignupScreen | Display name, DOB, position picker |
| `/home` | HomeScreen | Dashboard: stats summary, record CTA, recent sessions |
| `/camera` | CameraScreen | Record shot/save with 3-2-1 countdown |
| `/results/:id` | ResultsScreen | Score ring, form breakdown, coaching tips, strengths, drills |
| `/stats` | StatsDashboardScreen | Zone heatmap, progress chart, session history |
| `/achievements` | AchievementsScreen | 6-badge grid with unlock progress |
| `/profile` | ProfileScreen | Player info, mode toggle (Player/Goalie) |
| `/settings` | SettingsScreen | Notifications, privacy, account deletion |
| `/dev/bypass` | — | Debug-only route to skip auth |

### Router Redirect Logic

1. Show loading during auth/user fetch
2. Unauthenticated → `/login`
3. Authenticated minors without `parentApproved` → `/parental-consent`
4. Dev bypass: `/dev/bypass` skips auth (debug builds only)

---

## Data Models

### UserModel
| Field | Type | Notes |
|-------|------|-------|
| `uid` | String | Firebase Auth UID |
| `email` | String | |
| `displayName` | String | |
| `dateOfBirth` | DateTime | Required for COPPA |
| `position` | PlayerPosition | attacker / midfielder / defender / goalie |
| `isMinor` | bool | age < 13 |
| `parentApproved` | bool | COPPA consent granted |
| `parentEmail` | String? | |
| `avatarUrl` | String? | |
| `createdAt` | DateTime | |

### SessionModel
| Field | Type | Notes |
|-------|------|-------|
| `sessionId` | String | Firestore doc ID |
| `userId` | String | |
| `mode` | SessionMode | player / goalie |
| `recordedAt` | DateTime | |
| `duration` | Duration | |
| `totalShots` | int | |
| `successfulShots` | int | |
| `zoneAccuracy` | ZoneAccuracy | 3×3 grid (9 values, 0.0–1.0) |
| `videoUrl` | String? | |
| `thumbnailUrl` | String? | |
| `analysisComplete` | bool | |

### StatsModel
| Field | Type | Notes |
|-------|------|-------|
| `userId` | String | |
| `totalSessions` | int | |
| `totalShots` / `totalSuccessful` | int | |
| `lifetimeZoneAccuracy` | ZoneAccuracy | |
| `bestAccuracy` | double | |
| `currentStreak` / `longestStreak` | int | Days |
| `unlockedAchievements` | List\<String\> | |

### Shot Classification System
- **17 shot types** across men's and women's lacrosse
- **8 mechanics categories**: Hip Rotation, Shoulder Turn, Release Point, Wrist Snap, Follow-through, Footwork, Balance, Stick Protection
- Each `ShotDefinition` includes: description, key criteria, common faults, release angle, quick coaching cue
- `ShotCoachingReport`: prioritized tips, strengths, drill suggestions, session-over-session comparison

### Achievements (6)
| ID | Title | Criteria |
|----|-------|----------|
| `first_shot` | First Shot 🥍 | Record first session |
| `sharpshooter` | Sharpshooter 🎯 | High accuracy session |
| `streak_7` | 7-Day Streak 🔥 | Practice 7 days straight |
| `century` | Century Club 💯 | 100 total shots |
| `all_zones` | All Zones ✅ | Hit every zone |
| `consistent` | Consistent 📈 | Sustained performance |

---

## Services

### AuthService
- `signInWithEmail()`, `createWithEmail()`, `sendPasswordReset()`
- `signInWithGoogle()`, `signInWithApple()`, `signOut()`
- `isMinorAwaitingConsent()`, `deleteAccount()`

### MlAnalysisService
- `initialize()`, `dispose()`, `analyzeFrame(imagePath)` → `ShotAnalysisResult`
- Returns: overall score, keypoints, per-category breakdown, tip, goal zone
- **Beta status**: placeholder heuristic scoring (TFLite pending Dart 3.11 compat)

### ShotCoachingService
- `generateReport(breakdown, overallScore, shotType, discipline)` → `ShotCoachingReport`
- `compareMechanics(previous, current)` → per-category deltas
- `suggestDrill(report)` → targeted drill for weakest area

---

## COPPA Compliance

- Age gate at signup — DOB required
- Under-13: `isMinor: true` on user doc
- Router guard redirects minors to `/parental-consent` until `parentApproved: true`
- Parental consent email sent via `parentalConsent` Cloud Function
- Minimal data collection for minors; no social features without parent approval
- 48dp touch targets (WCAG + youth UX)

---

## Getting Started

### Prerequisites
- Flutter 3.41+ (stable channel)
- Xcode 26+ (iOS/macOS)
- Firebase project with Auth, Firestore, Cloud Functions

### Install & run

```bash
flutter pub get
flutter run -d "iPhone 17"    # iOS simulator
flutter run -d macos           # macOS desktop
```

### Configure Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=laxshot-app-d44c9
```

### Tests

```bash
flutter test
flutter analyze
```

---

## Key Design Decisions

- **On-device ML** — TFLite/MLKit runs locally; no video leaves the device (privacy for minors)
- **Riverpod over Bloc** — less boilerplate, better fit for Firebase streams
- **GoRouter** — declarative routing with redirect guards for auth and COPPA states
- **48dp touch targets** — WCAG and youth UX requirement; enforced via `AppSizes.minTouchTarget`
- **Portrait-only** — locked orientation for consistent camera UX
- **Dark mode** — for outdoor visibility at practice fields

---

## Beta Limitations

- ML inference uses placeholder scoring — real TFLite pose detection pending `tflite_flutter` Dart 3.11 compatibility
- Shot type auto-classification from pose data not yet wired (manual selection works)
- `google_mlkit_pose_detection` disabled on iOS simulator (arm64 incompatibility; works on physical devices)
- No social or sharing features (COPPA-first design)
