# Flutter Integration Status

> Audit snapshot after backend integration pass (Jul 2026).

## ✅ Already wired

| Area | Status |
|------|--------|
| Auth login / refresh / logout | ✅ |
| `GET /users/me`, setup home location | ✅ |
| Farm list + detail (`lat`/`lng`, assignments) | ✅ |
| Executive onboard farm | ✅ |
| Visit check-in + submit + presign uploads | ✅ |
| Executive my visits | ✅ |
| Dashboards, farmers, harvests calendar | ✅ |
| Mock mode (`AppConfig.useMockData`) | ✅ |

## 🔧 Fixed in this pass

| Issue | Fix |
|-------|-----|
| Admin executive profile visits | `GET /users/{id}/visits` via `getExecutiveVisits()` |
| Forgot-password poll | `GET /auth/password-reset-requests/status?employee_id=` |
| Farm model | Parses `assigned_executives[]` |
| Executive farm list filter | Removed redundant `assigned_to` — backend auto-filters |

## 🆕 Added in this pass

| Feature | Implementation |
|---------|----------------|
| Dynamic visit report form | `GET /visit-forms/visits/{id}/context`, `PATCH` progressive save, all 7 question types |
| Farm invitations | `FarmInvitationsScreen` — list + accept |
| Admin assign executives | Farm detail → assign sheet (`PATCH /farms/{id}/assign`) |
| Admin create farm | FAB on admin farms → `POST /farms/admin` |
| Visit `form_answers` on model | Parsed on `Visit.fromJson` |

## ⏳ Optional / not in v1

| Feature | Notes |
|---------|-------|
| Admin password reset list UI | Backend ready |
| Profile edit (`PATCH /users/me`) | Read-only profile today |
| Visit form builder admin UI | Backend CRUD under `/visit-forms/templates` |
| Bulk executive import, farm transfer | Backend ready |

## Key files

- `lib/core/network/api_endpoints.dart` — all v1 paths
- `lib/data/models/visit_form.dart` — form models
- `lib/features/executive/checkin/checkin_screen.dart` — dynamic form flow
- `lib/features/visits/presentation/widgets/dynamic_visit_form.dart` — question widgets
- `lib/features/executive/farms/farm_invitations_screen.dart` — proximity accept
- `lib/features/super_admin/farms/admin_farm_assign_sheet.dart` — multi-assign UI
