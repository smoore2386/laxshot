# Flutter Scaffold Task for LaxShot

You are FrontClaw, the Flutter frontend engineer for LaxShot — a youth lacrosse analysis app. Scaffold the complete Flutter frontend at /Users/smini/lacrosse-app/src/app/

## Context
- Backend: Firebase (Auth, Firestore, Storage, Cloud Functions) — owned by Laxback
- On-device ML: TFLite / Core ML for shot and save analysis
- Target: youth players ages 8-18 (COPPA compliance for under-13)

## Firestore paths (from Laxback):
- `users/{userId}` — profile doc
- `users/{userId}/sessions/{sessionId}` — individual sessions
- `users/{userId}/stats` — aggregated stats doc
- Storage: `users/{userId}/videos/{sessionId}.mp4`, `users/{userId}/thumbnails/{sessionId}.jpg`
- Callable functions: `createProfile`, `parentalConsent`, `parentApproval`, `deleteAccount`

## STEP 1: Create Flutter project
```
mkdir -p /Users/smini/lacrosse-app/src/app
cd /Users/smini/lacrosse-app/src/app
flutter create laxshot --org com.laxshot --platforms ios,android
```

## STEP 2: pubspec.yaml dependencies
Add to pubspec.yaml:
- firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_analytics
- camera, google_mlkit_pose_detection, video_player
- go_router, flutter_riverpod, riverpod_annotation
- fl_chart, intl, shared_preferences, image_picker
- dev: build_runner, riverpod_generator, flutter_lints

## STEP 3: Full lib/ directory structure
Scaffold all features with clean architecture (data/domain/presentation layers):
- features/auth/ — age gate, parental consent, login, signup
- features/camera/ — camera screen, recording controls
- features/analysis/ — results screen, video overlay player
- features/stats/ — dashboard, goal zone heatmap, progress chart, achievements
- features/profile/ — profile screen, settings
- core/constants/ — colors (lacrosse green #2D6A4F, gold #F4A261), sizes (48dp min), routes
- core/theme/ — light + dark ThemeData
- data/models/ — Firestore models with fromJson/toJson
- presentation/ — app.dart, router.dart, shared widgets

## STEP 4: Key implementations (real UI, not stubs)

### GoRouter routes:
/ → redirect by auth state
/onboarding → AgeGateScreen (DOB picker, age check)
/parental-consent → ParentalConsentScreen (parent email input)
/login → LoginScreen (email + Google + Apple)
/signup → SignupScreen
/home → DashboardScreen
/camera → CameraScreen
/results/:sessionId → ResultsScreen
/stats → StatsDashboardScreen
/achievements → AchievementsScreen
/profile → ProfileScreen
/settings → SettingsScreen

Redirect guards: unauthenticated → /login; isMinor && !parentApproved → /parental-consent

### AgeGateScreen: DOB date picker, calculates age, routes under-13 to parental consent

### LoginScreen: LaxShot logo, email/password fields, Google + Apple sign-in buttons, form validation

### CameraScreen: full-screen preview, mode toggle (Player/Goalie), large red record button, 3-2-1 countdown overlay

### StatsDashboardScreen: stat summary cards, goal zone heatmap, recent sessions list

### GoalZoneHeatmap (CustomPainter): lacrosse goal 3x3 grid, heat-colored by accuracy (blue→red), zone labels

### Theme: primary green #2D6A4F, accent gold #F4A261, 48dp button heights, dark mode

## STEP 5: firebase_options.dart placeholder
Placeholder file with TODO comment and placeholder values for projectId: laxshot

## STEP 6: Write src/app/laxshot/README.md
Architecture overview, how to run, how to configure Firebase (flutterfire configure)

## STEP 7: Commit
```
git -C /Users/smini/lacrosse-app add -A
git -C /Users/smini/lacrosse-app commit -m "feat: scaffold Flutter app — clean architecture, FlutterFire, GoRouter, auth/camera/stats screens"
```

## STEP 8: Notify
```
openclaw system event --text "Done: LaxShot Flutter app scaffolded" --mode now
```

Build with real code and real UI. No empty stub files.
