# Member 1 — Core, DB, Auth & App Shell

## Member Summary
- **Title**: Core & Foundation Engineer
- **Owned module**: Core infrastructure, database, authentication, app shell
- **Main goal**: Keep the entire project's foundation — DB schema, seed data, session state, routing, theme, and login flow — stable and correct so the other 3 members can build on top without surprises.

---

## Scope

### In scope
- `lib/main.dart` — app entry point, routing table, provider setup
- `lib/core/` — all constants, DB helper, enums, routes, utilities
- `lib/features/auth/` — login screen, session provider
- `lib/features/dashboard/` — all 3 role dashboards (Admin, Receptionist, Housekeeping)
- `lib/shared/` — global theme and shared widgets
- DB schema definition and seed data
- Navigation routing for the whole app

### Out of scope
- Booking screens or logic → Member 2
- Room, room type, or housekeeping screens → Member 3
- Staff management screens → Member 4
- Stay operations (check-in, checkout, invoice) screens → Member 4

---

## Owned Files and Folders

You are the **sole owner** of these files. Only you should edit them:

```
lib/main.dart
lib/core/constants/app_constants.dart
lib/core/constants/app_enums.dart
lib/core/constants/app_routes.dart
lib/core/constants/db_schema.dart
lib/core/database/database_helper.dart
lib/core/utils/date_formatter.dart
lib/features/auth/session_provider.dart
lib/features/auth/screens/login_screen.dart
lib/features/dashboard/screens/dashboard_screens.dart
lib/shared/themes/app_theme.dart
lib/shared/widgets/primary_button.dart
```

> **Likely new files you may need to create** (label as needed):
> - `lib/shared/widgets/loading_overlay.dart` — reusable loading indicator
> - `lib/shared/widgets/error_snackbar.dart` — consistent error display helper

---

## Forbidden Files and Caution Files

| File | Rule |
|------|------|
| `lib/data/models/booking_model.dart` | FORBIDDEN — Member 2 owns |
| `lib/data/repositories/booking_repository.dart` | FORBIDDEN — Member 2 owns |
| `lib/features/bookings/screens/booking_screens.dart` | FORBIDDEN — Member 2 owns |
| `lib/data/models/room_model.dart` | FORBIDDEN — Member 3 owns |
| `lib/data/repositories/room_repository.dart` | FORBIDDEN — Member 3 owns |
| `lib/features/rooms/screens/room_screens.dart` | FORBIDDEN — Member 3 owns |
| `lib/data/models/invoice_model.dart` | FORBIDDEN — Member 4 owns |
| `lib/features/checkin_checkout/` | FORBIDDEN — Member 4 owns |
| `lib/features/staff/screens/staff_screens.dart` | FORBIDDEN — Member 4 owns |

> **Your own caution files within your ownership zone:**
> - `lib/core/constants/db_schema.dart` — This is the single source of truth for ALL table definitions. Never add columns without checking with all members, as every model depends on these column names.
> - `lib/core/database/database_helper.dart` — Seed data changes here affect every member's first-run experience.

---

## Main Screens

All screens below are in your ownership zone. The stubs from Phase B are in place — replace each stub body with real UI:

| Screen | File | Status |
|--------|------|--------|
| Login Screen | `lib/features/auth/screens/login_screen.dart` | Functional (Phase B) — polish UX |
| Admin Dashboard | `lib/features/dashboard/screens/dashboard_screens.dart` | Functional (Phase B) — finalize tiles |
| Receptionist Dashboard | same file | Functional (Phase B) — finalize tiles |
| Housekeeping Dashboard | same file | Functional (Phase B) — finalize tile |

---

## Main Models / Tables / Repositories / Services

| Item | File | Your role |
|------|------|-----------|
| `user_model.dart` | `lib/data/models/user_model.dart` | **Own** — used by auth |
| `auth_repository.dart` | `lib/data/repositories/auth_repository.dart` | **Own** |
| `SessionProvider` | `lib/features/auth/session_provider.dart` | **Own** |
| `DatabaseHelper` | `lib/core/database/database_helper.dart` | **Own** |
| `DbSchema` | `lib/core/constants/db_schema.dart` | **Own** |
| `AppEnums` | `lib/core/constants/app_enums.dart` | **Own** |
| `DateFormatter` | `lib/core/utils/date_formatter.dart` | **Own** |

> Note: `user_model.dart` is used by Member 4 for staff management (`user_repository.dart`). **Do not rename fields or remove the `role` property**. Coordinate with Member 4 if adding new fields.

---

## Business Rules to Respect

1. **Three roles only**: `admin`, `receptionist`, `housekeeping` — stored as lowercase TEXT in SQLite.
2. **Login only for active staff**: `WHERE isActive = 1` — already enforced in `auth_repository.dart`.
3. **Session is in-memory only**: `SessionProvider` holds the current user; cleared on logout. No persistence across app restarts.
4. **Role-based routing**: After login, route to the correct dashboard based on `session.role`.
5. **Password hashing**: Always use `UserModel.hashPassword()` (MD5). Never store plain text passwords.
6. **Schema is immutable by non-Module-A members**: If another member asks for a schema change, you evaluate and apply it.
7. **All dates are stored as Unix milliseconds** (INTEGER). Use `DateFormatter.toMs()` and `DateFormatter.fromMs()` consistently.

---

## Recommended Implementation Steps

1. **Verify the app runs** — `flutter run` with seed data OK (admin/admin123, receptionist/recep123, housekeeping/house123).
2. **Polish login screen** — Form validation messages, focus behavior, keyboard submit.
3. **Finalize dashboard tiles** — Ensure all tiles navigate to the correct routes (already hotfixed in Phase B).
4. **Add shared widgets** — `LoadingOverlay`, `ErrorSnackbar` so other members can use them immediately.
5. **Update `DateFormatter`** if any utility gap is found during integration (e.g., a `formatDate` for display).
6. **Expose `AppConstants`** for anything every module neeeds (e.g., status color map).
7. **Integration pass** — After other members have stubs working, test that login→dashboard→feature navigation is seamless.

---

## Dependencies on Other Members

### What you depend on from others
- Nothing blocking — you own the foundation layer.

### What others depend on from you
| What | Dependant | Priority |
|------|-----------|----------|
| `SessionProvider.userId` (current user's ID) | Members 2, 3, 4 | HIGH — needed for `createdBy` / `issuedBy` fields |
| `AppRoutes` constants | All members | HIGH — must not rename routes |
| `DateFormatter.toMs()` / `fromMs()` | All members | HIGH |
| `AppEnums` (`BookingStatus`, `RoomStatus`, `StaffRole`) | All members | HIGH |
| `DatabaseHelper.instance.database` | All members | HIGH |
| `PrimaryButton` widget | Members 2, 3, 4 | MEDIUM |
| Seed data working on first run | All members | HIGH — needed for demo |

### Fragile interface
> `AppRoutes` constant names must not change after other members wire their `Navigator.pushNamed()` calls. Treat these as a public API.

---

## Acceptance Criteria

- [ ] App launches, Login screen appears.
- [ ] `admin` / `admin123` logs in → Admin Dashboard (6 tiles).
- [ ] `receptionist` / `recep123` logs in → Receptionist Dashboard (4 tiles).
- [ ] `housekeeping` / `house123` logs in → Housekeeping Dashboard (1 tile).
- [ ] Wrong credentials → error message shown, no crash.
- [ ] Logout from any dashboard → returns to Login screen, session is cleared.
- [ ] All tile routes navigate without crashing (even to stub screens).
- [ ] Seed data is present on first launch (can be verified by logging in).
- [ ] `SessionProvider.userId` returns the logged-in user's database ID (non-null).
- [ ] `flutter analyze` shows 0 errors.

---

## Demo Checklist

- [ ] Open app fresh → Login screen appears with HMS branding.
- [ ] Login as admin → 6 dashboard tiles visible.
- [ ] Tap "Bookings" → Booking list screen opens.
- [ ] Tap "Check-In" → Check-In screen opens.
- [ ] Logout → back to Login.
- [ ] Login as receptionist → 4 tiles.
- [ ] Login as housekeeping → 1 tile ("Cleaning Tasks").
- [ ] Tap "Cleaning Tasks" → Housekeeping screen opens.

---

## Branch and Commit Guidance

**Branch name**: `feature/module-a-core-auth`

**Commit message style** (conventional commits):
```
feat(auth): implement login form validation
fix(dashboard): correct receptionist tile count
feat(core): add LoadingOverlay shared widget
chore(seed): update seed passwords for demo
```

---

## Merge Conflict Prevention Rules

- **Never edit** any file under `lib/features/bookings/`, `lib/features/rooms/`, `lib/features/housekeeping/`, `lib/features/checkin_checkout/`, `lib/features/staff/`.
- **Never edit** any `lib/data/models/*.dart` except `user_model.dart`.
- **Never edit** any repository except `auth_repository.dart`.
- If you need to add a shared utility, add it to `lib/core/utils/` or `lib/shared/widgets/` — never to a feature folder.
- If you add a new route to `AppRoutes`, announce it to the team immediately so members can use it.

---

## AI Handoff Prompt Starter

```
You are implementing Module A (Core, DB, Auth & App Shell) for the HMS Flutter project.

Allowed files:
- lib/main.dart
- lib/core/ (all files)
- lib/features/auth/ (all files)
- lib/features/dashboard/screens/dashboard_screens.dart
- lib/shared/ (all files)
- lib/data/models/user_model.dart
- lib/data/repositories/auth_repository.dart

Forbidden files (do not touch):
- lib/data/repositories/booking_repository.dart
- lib/data/repositories/room_repository.dart
- lib/data/repositories/invoice_repository.dart
- lib/data/repositories/surcharge_repository.dart
- lib/data/repositories/user_repository.dart
- lib/features/bookings/
- lib/features/rooms/
- lib/features/housekeeping/
- lib/features/checkin_checkout/
- lib/features/staff/

Rules:
- Do not redesign architecture.
- Do not modify DB schema (lib/core/constants/db_schema.dart) unless explicitly instructed by the team.
- Keep compile safety at all times.
- Use SessionProvider for all session-related state.
- Use AppRoutes constants for all navigation.
```
