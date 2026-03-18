# Member 3 — Rooms, Room Types & Housekeeping

## Member Summary
- **Title**: Room & Housekeeping Engineer
- **Owned module**: Room management, room type management, and housekeeping task flow
- **Main goal**: Allow admins to manage room types and rooms, allow receptionists to see room availability, and allow housekeeping staff to mark dirty rooms as available.

---

## Scope

### In scope
- `lib/features/rooms/screens/room_screens.dart` — all room and room type screens
- `lib/features/housekeeping/screens/housekeeping_task_list_screen.dart` — housekeeping task list
- `lib/data/models/room_model.dart` — extend if needed
- `lib/data/models/room_type_model.dart` — extend if needed
- `lib/data/repositories/room_repository.dart` — implement all methods including availability query
- `lib/data/repositories/room_type_repository.dart` — implement all methods

### Out of scope
- Booking logic → Member 2
- Check-in / checkout / invoices → Member 4
- Staff management → Member 4
- Login / session → Member 1
- App shell / routing → Member 1

---

## Owned Files and Folders

You are the **sole owner** of these files:

```
lib/features/rooms/screens/room_screens.dart
lib/features/housekeeping/screens/housekeeping_task_list_screen.dart
lib/data/models/room_model.dart
lib/data/models/room_type_model.dart
lib/data/repositories/room_repository.dart
lib/data/repositories/room_type_repository.dart
```

> **Likely new files you may need to create**:
> - `lib/features/rooms/providers/room_provider.dart` — state management for room/room type lists
> - `lib/features/housekeeping/providers/housekeeping_provider.dart` — state for the dirty-room list
> - `lib/features/rooms/widgets/room_status_badge.dart` — color-coded status indicator widget

---

## Forbidden Files and Caution Files

| File | Rule |
|------|------|
| `lib/core/constants/db_schema.dart` | FORBIDDEN — Module A owns schema |
| `lib/core/database/database_helper.dart` | FORBIDDEN — Module A only |
| `lib/features/auth/session_provider.dart` | FORBIDDEN — read-only via `context.read<SessionProvider>()` |
| `lib/data/repositories/booking_repository.dart` | FORBIDDEN — Member 2 owns |
| `lib/data/models/booking_model.dart` | FORBIDDEN — Member 2 owns |
| `lib/features/bookings/` | FORBIDDEN — Member 2 owns |
| `lib/data/repositories/invoice_repository.dart` | FORBIDDEN — Member 4 owns |
| `lib/features/checkin_checkout/` | FORBIDDEN — Member 4 owns |
| `lib/features/staff/` | FORBIDDEN — Member 4 owns |

> **Cross-cutting interface caution**:
> - `room_repository.dart → getAvailableRoomsForDateRange()` is called by Member 2's AssignRoomScreen. **Do not change its method signature.** The stub from Phase B returns `[]` — you must replace it with the real overlap SQL query.

---

## Main Screens

All screens live in the files listed above (stubs from Phase B — replace stub bodies):

| Screen | File | Your task |
|--------|------|-----------|
| `RoomTypeListScreen` | `room_screens.dart` | List all room types; FAB to create |
| `RoomTypeFormScreen` | `room_screens.dart` | Create / edit room type: name, price, description |
| `RoomListScreen` | `room_screens.dart` | List all rooms with status badge; FAB to add |
| `RoomFormScreen` | `room_screens.dart` | Create / edit room: number, room type, notes |
| `HousekeepingTaskListScreen` | `housekeeping_task_list_screen.dart` | Show DIRTY rooms; tap to mark AVAILABLE |

---

## Main Models / Tables / Repositories / Services

| Item | File | Your role |
|------|------|-----------|
| `RoomTypeModel` | `lib/data/models/room_type_model.dart` | **Own** |
| `RoomModel` | `lib/data/models/room_model.dart` | **Own** |
| `RoomTypeRepository` | `lib/data/repositories/room_type_repository.dart` | **Own** |
| `RoomRepository` | `lib/data/repositories/room_repository.dart` | **Own** |
| `SessionProvider` | provided by Member 1 | **Read-only** |

### Key fields to respect

**`RoomModel`**:

| Field | Type | Rule |
|-------|------|-------|
| `status` | `String` | one of `'AVAILABLE'`, `'OCCUPIED'`, `'DIRTY'`, `'OUT_OF_SERVICE'` — use `RoomStatus` enum |
| `roomTypeId` | `int` | FK to `room_types.id` |

**`RoomTypeModel`**:

| Field | Type | Rule |
|-------|------|-------|
| `pricePerNight` | `double` | Used by Member 2 for price snapshotting — must be positive |

---

## Business Rules to Respect

1. **Room status transitions** (housekeeping only does DIRTY → AVAILABLE):
   - Normal flow: `AVAILABLE` → `OCCUPIED` (done by Member 4 at check-in) → `DIRTY` (done by Member 4 at checkout) → `AVAILABLE` (done by housekeeping here).
   - Housekeeping can **only** transition `DIRTY → AVAILABLE`. Use `markRoomAvailable()` which has a `WHERE status = 'DIRTY'` guard — do not bypass it.
2. **Room type deletion guard**: `RoomTypeRepository.hasLinkedRooms(typeId)` must return `false` before deleting a room type. The scaffold already has this method — use it.
3. **Room availability query**: `getAvailableRoomsForDateRange()` must exclude rooms that have an active booking (status `BOOKED` or `CHECKED_IN`) with overlapping dates. The overlap condition is: `checkInDate < requestedCheckOut AND checkOutDate > requestedCheckIn`.
4. **Admin only** manages room types and rooms; housekeeping only uses the cleaning task list.
5. **No room deletion for simplicity**: mark rooms `OUT_OF_SERVICE` instead (or simply do not implement delete for MVP).
6. **Status is stored as a TEXT string** matching `RoomStatus` enum — use `RoomStatus.fromString()` / `.toDbString()`.

---

## Recommended Implementation Steps

1. **Implement `RoomTypeListScreen`**:
   - Call `RoomTypeRepository.getAllRoomTypes()`.
   - FAB → navigate to `RoomTypeFormScreen` (pass no arguments = create mode).
   - Tap item → navigate to `RoomTypeFormScreen` (pass type ID = edit mode).
2. **Implement `RoomTypeFormScreen`**:
   - Fields: name, pricePerNight, description.
   - On save: call `createRoomType()` or `updateRoomType()`.
   - On delete: call `hasLinkedRooms()` first; show error if true.
3. **Implement `RoomListScreen`**:
   - Call `RoomRepository.getAllRooms()`.
   - Show status badge with color (AVAILABLE = green, OCCUPIED = orange, DIRTY = red).
   - FAB → `RoomFormScreen` (create mode).
4. **Implement `RoomFormScreen`**:
   - Fields: roomNumber, roomType dropdown (from `getAllRoomTypes()`), notes.
   - On save: call `createRoom()` or `updateRoom()`.
5. **Implement `HousekeepingTaskListScreen`**:
   - Call `RoomRepository.getRoomsByStatus(RoomStatus.dirty)`.
   - Each item shows room number and a "Mark Clean" button.
   - On tap: call `RoomRepository.markRoomAvailable(roomId)` then refresh.
6. **Implement `getAvailableRoomsForDateRange()` in `RoomRepository`**:
   - Replace the `TODO` stub with the real overlap SQL (see spec in business rules above).
   - This unblocks Member 2's AssignRoomScreen.

---

## Dependencies on Other Members

### What you depend on from others

| What | From | When needed |
|------|------|-------------|
| `SessionProvider.role` | Member 1 | To hide admin-only actions from housekeeping users |
| `AppRoutes` constants for navigation | Member 1 | Throughout |
| `DateFormatter.toMs()` | Member 1 | Not directly needed unless you add date fields |

### What others depend on from you

| What | Dependant | Priority |
|------|-----------|----------|
| `RoomRepository.getAvailableRoomsForDateRange()` | Member 2 (AssignRoomScreen) | **HIGH** — implement early |
| `RoomTypeRepository.getAllRoomTypes()` | Member 2 (CreateBookingScreen) | **HIGH** — implement early |
| `RoomRepository.updateStatus()` | Member 4 (StayService) | HIGH — do not change signature |
| `RoomRepository.markRoomAvailable()` | Member 4 (StayService checkout) | HIGH — do not change signature |

> ⚠️ **Priority**: implement `getAvailableRoomsForDateRange()` and `getAllRoomTypes()` early so Member 2 and Member 4 are not blocked.

---

## Acceptance Criteria

- [ ] Admin can create a new room type (name, price, description).
- [ ] Admin can edit an existing room type.
- [ ] Deleting a room type with linked rooms shows an error message (not silent).
- [ ] Admin can create a new room with number, type, and optional notes.
- [ ] Room list shows all rooms with a color-coded status badge.
- [ ] `getAvailableRoomsForDateRange()` returns only rooms without overlapping active bookings.
- [ ] Housekeeping dashboard tile → Cleaning Tasks screen shows only `DIRTY` rooms.
- [ ] Housekeeping staff taps "Mark Clean" → room status changes to `AVAILABLE` in DB.
- [ ] Housekeeping staff cannot access Room CRUD screens (role guard in UI).
- [ ] `flutter analyze` shows 0 errors.

---

## Demo Checklist

- [ ] Login as admin → tap "Room Types" → list is visible.
- [ ] Create a new room type → it appears in the list.
- [ ] Tap "Rooms" → list shows all 5 seeded rooms with status badges.
- [ ] Create a new room → it appears in the list.
- [ ] Log out → login as housekeeping → tap "Cleaning Tasks".
- [ ] If no dirty rooms, show an empty state message (not a crash).
- [ ] If a dirty room exists, tap "Mark Clean" → room disappears from the list.

---

## Branch and Commit Guidance

**Branch name**: `feature/module-c-rooms-housekeeping`

**Commit message style**:
```
feat(rooms): implement room type list and form
feat(rooms): implement room list with status badge
feat(housekeeping): implement dirty room list and mark clean
feat(rooms): implement availability query in RoomRepository
fix(rooms): prevent deletion of room type with linked rooms
```

---

## Merge Conflict Prevention Rules

- **Never edit** `lib/core/`, `lib/shared/`, `lib/main.dart` — request changes from Member 1.
- **Never edit** `lib/features/bookings/`, `lib/features/checkin_checkout/`, `lib/features/staff/`.
- **Never edit** `booking_repository.dart`, `invoice_repository.dart`, `surcharge_repository.dart`, `user_repository.dart`.
- Only create new files inside `lib/features/rooms/` or `lib/features/housekeeping/`.
- Do not change `room_repository.dart` method signatures — coordinate with Member 2 before any change.

---

## AI Handoff Prompt Starter

```
You are implementing Module C (Rooms, Room Types & Housekeeping) for the HMS Flutter project.

Allowed files (read + write):
- lib/features/rooms/screens/room_screens.dart
- lib/features/housekeeping/screens/housekeeping_task_list_screen.dart
- lib/data/repositories/room_repository.dart
- lib/data/repositories/room_type_repository.dart
- lib/data/models/room_model.dart
- lib/data/models/room_type_model.dart
- lib/features/rooms/ (new files you create here are fine)
- lib/features/housekeeping/ (new files you create here are fine)

Read-only (call methods, do not edit):
- lib/features/auth/session_provider.dart (use context.read<SessionProvider>())
- lib/core/constants/app_enums.dart
- lib/core/utils/date_formatter.dart

Forbidden files (do not touch):
- lib/core/constants/db_schema.dart
- lib/core/database/database_helper.dart
- lib/features/bookings/
- lib/features/checkin_checkout/
- lib/features/staff/
- lib/data/repositories/booking_repository.dart
- lib/data/repositories/invoice_repository.dart
- lib/data/repositories/surcharge_repository.dart

Rules:
- Do not redesign architecture.
- Do not modify DB schema unless explicitly instructed.
- Keep compile safety at all times.
- Use RoomStatus enum from AppEnums for all status values.
- getAvailableRoomsForDateRange() must use the overlap SQL:
  checkInDate < requestedCheckOut AND checkOutDate > requestedCheckIn
- Housekeeping may only transition DIRTY → AVAILABLE via markRoomAvailable().
```
