# Shine Gold App

Flutter mobile app for **Shine Gold Organic Agro Invention** — field executive and super admin workflows.

## Run

```bash
flutter pub get
flutter run
```

By default the app talks to the live API (`AppConfig.useMockData = false`).  
Set `useMockData = true` in `lib/core/config/app_config.dart` for offline mock data.

## Demo login

| Role | Employee ID | Password |
|------|-------------|----------|
| Executive | `EXEC001` | `ChangeMe123!` |
| Super Admin | `ADMIN001` | `ChangeMe123!` |

Mock mode also accepts `EMP001` as an alias for the executive.

## Architecture

- **UI:** Flutter + Riverpod + go_router
- **Theme:** Dark premium field UI — gold `#C9A227`, natural green
- **Data:** Live FastAPI by default; mock datasources available via `AppConfig.useMockData`

## API integration

1. Edit `lib/core/config/app_config.dart` — `useMockData`, `API_BASE_URL`
2. Routes live in `lib/core/network/api_endpoints.dart`
3. Remote datasources in `lib/data/datasources/remote/`

## Features

**Executive:** Home dashboard, farms (GPS sort + filters), check-in (photos, voice, condition), my visits, onboard farm, profile, harvest reminders

**Super Admin:** Dashboard, farms, executives, harvests calendar, farmers & profile via More menu
