# Shine Gold App

Flutter mobile app for **Shine Gold Organic Agro Invention** — field executive and super admin workflows.

## Run

```bash
flutter pub get
flutter run
```

## Demo login

| Role | Employee ID | Password |
|------|-------------|----------|
| Executive | `EMP001` | `password123` |
| Super Admin | `ADMIN001` | `password123` |

## Architecture

- **UI:** Flutter + Riverpod + go_router
- **Theme:** Dark premium field UI — gold `#C9A227`, natural green, Inter typography
- **Data:** Mock datasources (default). Swap to FastAPI by setting `AppConfig.useMockData = false` and updating `ApiEndpoints`.

## API integration (later)

1. Edit `lib/core/config/app_config.dart` — set `useMockData = false`, `baseUrl`
2. Edit `lib/core/network/api_endpoints.dart` — match FastAPI routes
3. Implement classes in `lib/data/datasources/remote/`

## Features

**Executive:** Home dashboard, farms (GPS sort + filters), check-in (photos, voice, condition), my visits, onboard farm, profile

**Super Admin:** Dashboard, farms, executives, harvests calendar, farmers & profile via More menu
