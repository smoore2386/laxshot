# LaxShot — Flutter App

Youth lacrosse analysis app with on-device AI shot and save analysis.

## Architecture

Clean architecture with Riverpod state management and GoRouter navigation.

```
lib/
  core/           – constants (colors, sizes, routes), theme, utils
  features/       – feature modules (auth, camera, analysis, stats, profile)
    <feature>/
      data/       – repositories, data sources
      domain/     – entities, use cases
      presentation/ – screens, widgets, providers
  data/           – shared models (Firestore), repository interfaces
  presentation/   – app root, GoRouter, shared widgets
  main.dart       – entry point
```

**Stack:**
- **State**: `flutter_riverpod` — `StreamProvider`, `FutureProvider`, `AsyncNotifier`
- **Navigation**: `go_router` — named routes with auth + COPPA redirect guards
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions)
- **ML**: `google_mlkit_pose_detection` (on-device, no video upload)
- **Charts**: `fl_chart` — line charts + custom `GoalZoneHeatmap` painter

## Screens

| Route | Screen | Notes |
|---|---|---|
| `/onboarding` | AgeGateScreen | DOB picker → COPPA gate for under-13 |
| `/parental-consent` | ParentalConsentScreen | Parent email → Cloud Function |
| `/login` | LoginScreen | Email + Google + Apple |
| `/signup` | SignupScreen | Display name, DOB, position |
| `/home` | HomeScreen | Dashboard: stats, record CTA, sessions |
| `/camera` | CameraScreen | Record shot/save, 3-2-1 countdown |
| `/results/:id` | ResultsScreen | Score ring, form breakdown cards |
| `/stats` | StatsDashboardScreen | Heatmap, progress chart, sessions |
| `/achievements` | AchievementsScreen | Badge grid with unlock progress |
| `/profile` | ProfileScreen | Mode toggle (Player/Goalie), info |
| `/settings` | SettingsScreen | Notifications, privacy, account |

## COPPA Compliance

- Age gate at signup — DOB required
- Under-13: `isMinor: true` on user doc
- Router guard redirects minors to `/parental-consent` until `parentApproved: true`
- Parental consent email sent via `parentalConsent` Cloud Function
- Minimal data collection for minors; no social features without parent approval

## Getting Started

### 1. Install Flutter
```bash
flutter --version  # requires Flutter 3.x
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (creates lib/firebase_options.dart with real values)
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

### 4. Run the app
```bash
flutter run
```

### 5. Run tests
```bash
flutter test
```

## Key Design Decisions

- **On-device ML** — TFLite/MLKit runs locally, no video leaves the device (privacy for minors)
- **Riverpod over Bloc** — less boilerplate, better fit for Firebase streams
- **GoRouter** — declarative routing with redirect guards for auth and COPPA states
- **48dp touch targets** — WCAG and youth UX requirement; enforced via `AppSizes.minTouchTarget`
- **Dark mode** — for outdoor visibility at practice fields
