# Frontend Tools Notes

## Dev Environment
- Update this file as the stack is set up
- Primary workspace: `${LACROSSE_APP_PATH}/src/`

## Common Commands
<!-- Populate once stack is chosen -->
<!-- Examples:
- `pnpm start`         — start Expo/Metro dev server
- `pnpm ios`           — run iOS simulator
- `pnpm android`       — run Android emulator
- `pnpm test`          — run Jest tests
- `pnpm lint`          — ESLint + Prettier check
- `pnpm typecheck`     — TypeScript check (no emit)
- `eas build --local`  — local EAS build
-->

## API Connection
- Backend local URL: `http://localhost:3000` (or update)
- API client located at: `src/services/` (or update)
- Auth token storage: (SecureStore / AsyncStorage — update when chosen)

## Design Tokens
<!-- Link to Figma or design system when available -->
- Colors, spacing, typography: `src/utils/theme.ts` (or update)

## Device Testing Notes
<!-- Note any device-specific quirks discovered during development -->
- iOS safe area insets: handled via SafeAreaProvider
- Android back button: handled in navigation config

## Useful Debugging
<!-- Tools and techniques that work in this project -->
- Flipper / React Native DevTools for state and network inspection
- `useFocusEffect` + `console.log` for navigation debugging
