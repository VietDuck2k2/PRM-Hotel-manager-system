# Member 2 — Booking

## Member Summary
- **Title**: Booking Engineer
- **Owned module**: Booking lifecycle — create, list, detail, assign room, cancel
- **Main goal**: Allow receptionists and admins to manage bookings from creation through cancellation, with correct status transitions and room assignment.

---

## Scope

### In scope
- `lib/features/bookings/screens/booking_screens.dart` — all booking screens
- `lib/data/models/booking_model.dart` — read-only during Phase C; extend if needed
- `lib/data/repositories/booking_repository.dart` — implement repository methods as needed
- Price snapshotting at booking creation
- Room assignment (sets `roomId` on a BOOKED booking)
- Booking cancellation with reason (clears `roomId`)
- Booking list with status filter
- Booking detail view

### Out of scope
- Room availability SQL — implemented by Member 3 in `room_repository.dart`
- Check-in / checkout — Member 4
- Invoice — Member 4
- Staff management — Member 4
- Room CRUD — Member 3
- Login / session — Member 1

---

## Owned Files and Folders

You are the **sole owner** of these files:

```
lib/features/bookings/screens/booking_screens.dart
lib/data/repositories/booking_repository.dart
lib/data/models/booking_model.dart
```

> **Likely new files you may need to create**:
> - `lib/features/bookings/providers/booking_provider.dart` — state management for booking list and active booking
> - `lib/features/bookings/widgets/booking_card.dart` — reusable card for the booking list

---

## Forbidden Files and Caution Files

| File | Rule |
|------|------|
| `lib/core/constants/db_schema.dart` | FORBIDDEN — Module A owns schema |
| `lib/core/database/database_helper.dart` | FORBIDDEN — Module A only |
| `lib/features/auth/session_provider.dart` | FORBIDDEN — read-only; use `context.read<SessionProvider>()` |
| `lib/data/models/room_model.dart` | FORBIDDEN — Member 3 owns |
| `lib/data/repositories/room_repository.dart` | CAUTION — read-only; call `getAvailableRoomsForDateRange()` but do not edit |
| `lib/data/repositories/room_type_repository.dart` | CAUTION — read-only; call `getAllRoomTypes()` only |
| `lib/data/repositories/invoice_repository.dart` | FORBIDDEN — Member 4 owns |
| `lib/features/checkin_checkout/` | FORBIDDEN — Member 4 owns |
| `lib/features/staff/` | FORBIDDEN — Member 4 owns |
| `lib/features/rooms/` | FORBIDDEN — Member 3 owns |

---

## Main Screens

All screens live in `lib/features/bookings/screens/booking_screens.dart` (stub file from Phase B — replace stub bodies):

| Screen | Current status | Your task |
|--------|----------------|-----------|
| `BookingListScreen` | Stub | Implement list with status filter tabs/chips |
| `BookingDetailScreen` | Stub | Show all booking fields; action buttons based on status |
| `CreateBookingScreen` | Stub | Form: guest name, phone, room type, check-in/out dates |
| `AssignRoomScreen` | Stub | List available rooms from `RoomRepository`; tap to assign |
| `CancelBookingScreen` | Stub | Form: cancellation reason field; confirm action |

---

## Main Models / Tables / Repositories / Services

| Item | File | Your role |
|------|------|-----------|
| `BookingModel` | `lib/data/models/booking_model.dart` | **Own** — extend only if needed |
| `BookingRepository` | `lib/data/repositories/booking_repository.dart` | **Own** |
| `RoomRepository` | `lib/data/repositories/room_repository.dart` | **Read-only** — call `getAvailableRoomsForDateRange()` |
| `RoomTypeRepository` | `lib/data/repositories/room_type_repository.dart` | **Read-only** — call `getAllRoomTypes()` for the create-booking form |
| `SessionProvider` | provided by Member 1 | **Read-only** — get `session.userId` for `createdBy` |

### Key fields in `BookingModel` to respect

| Field | Type | Rule |
|-------|------|-------|
| `roomId` | `int?` | nullable — booking can be created without room |
| `bookedPricePerNight` | `double` | snapshotted from `RoomType.pricePerNight` at creation time; never updated after |
| `createdBy` | `int` | set to `SessionProvider.userId` at creation |
| `checkInDate` / `checkOutDate` | `int` | Unix milliseconds — use `DateFormatter.toMs()` |
| `status` | `String` | use `BookingStatus.booked.toDbString()` etc. |

---

## Business Rules to Respect

1. **Booking can be created without a room** — `roomId` is nullable; never enforce room selection on creation.
2. **Price snapshot**: at creation, copy `roomType.pricePerNight` into `booking.bookedPricePerNight`. Do NOT look up the current price later.
3. **Room assignment** is a separate step after creation: only allowed when `booking.status == BOOKED`.
4. **Cancellation**: sets status to `CANCELLED`, clears `roomId` (sets to null), records `cancelReason`. Only allowed when `status == BOOKED`.
5. **No editing** a booking's dates or room type after creation (not in scope for MVP).
6. **Status flow**: `BOOKED` → (optionally assign room) → `CHECKED_IN` (done by Member 4) → `CHECKED_OUT` (done by Member 4). Member 2 only drives `BOOKED` and `CANCELLED`.
7. **Guest data**: collect `guestName` (TEXT) and `guestPhone` (TEXT). No ID / passport storage.
8. **Check-in date must be before check-out date** — validate in the form.

---

## Recommended Implementation Steps

1. **Read the stubs** in `booking_screens.dart` carefully to understand what each screen expects.
2. **Implement `CreateBookingScreen`**:
   - Fetch room types via `RoomTypeRepository.getAllRoomTypes()` for the dropdown.
   - Date pickers → store as Unix ms via `DateFormatter.toMs()`.
   - On submit, call `BookingRepository.createBooking(booking)` with `bookedPricePerNight = selectedRoomType.pricePerNight`.
3. **Implement `BookingListScreen`**:
   - Call `BookingRepository.getAllBookings()`.
   - Status filter (BOOKED / CANCELLED / CHECKED_IN / CHECKED_OUT) as tab or chip.
4. **Implement `BookingDetailScreen`**:
   - Shows all booking fields.
   - "Assign Room" button (visible when status == BOOKED and roomId == null).
   - "Cancel" button (visible when status == BOOKED).
5. **Implement `AssignRoomScreen`**:
   - Calls `RoomRepository.getAvailableRoomsForDateRange(roomTypeId, checkInMs, checkOutMs)`.
   - Shows a list of available rooms.
   - On tap → calls `BookingRepository.assignRoom(bookingId, roomId)`.
6. **Implement `CancelBookingScreen`**:
   - Text field for reason.
   - On confirm → calls `BookingRepository.cancelBooking(bookingId, reason)`.
7. **Add state management** — create `booking_provider.dart` with `ChangeNotifier` if needed.
8. **Wire navigation** in existing screens (use `AppRoutes` constants with `arguments` for IDs).

---

## Dependencies on Other Members

### What you depend on from others

| What | From | When needed |
|------|------|-------------|
| `RoomRepository.getAvailableRoomsForDateRange()` | Member 3 | When implementing AssignRoomScreen |
| `RoomTypeRepository.getAllRoomTypes()` | Member 3 | When implementing CreateBookingScreen |
| `SessionProvider.userId` | Member 1 | At booking creation (set `createdBy`) |
| `DateFormatter` utilities | Member 1 | Throughout |
| `AppRoutes` constants | Member 1 | Navigation |

> ⚠️ **Blocker risk**: `getAvailableRoomsForDateRange()` is stubbed (returns `[]`). Coordinate with Member 3 on when the real implementation lands so you can test AssignRoomScreen properly. In the meantime, use all rooms of matching type as a placeholder.

### What others depend on from you

| What | Dependant | Notes |
|------|-----------|-------|
| `BookingModel` shape | Member 4 | Member 4 reads bookings to run check-in/checkout |
| `BookingRepository.updateStatus()` | Member 4 (StayService) | Must not change signature |
| `BookingRepository.getBookingsByStatus(BookingStatus.checkedIn)` | Member 4 | Used to populate check-in list |

---

## Acceptance Criteria

- [ ] Receptionist can create a booking with guest name, phone, room type, and dates.
- [ ] `bookedPricePerNight` in the DB equals the room type's price at the time of booking (not 0).
- [ ] Booking can be created without assigning a room.
- [ ] Booking appears in the list with status `BOOKED`.
- [ ] Admin can assign an available room to a `BOOKED` booking.
- [ ] After room assignment, `roomId` is set in the DB and displayed in the detail screen.
- [ ] Booking can be cancelled with a reason; `status` → `CANCELLED`, `roomId` → null.
- [ ] Cancelled booking appears in the list with status `CANCELLED`.
- [ ] Create booking form rejects check-out date ≤ check-in date.
- [ ] `createdBy` field is set to the current user's ID.
- [ ] `flutter analyze` shows 0 errors.

---

## Demo Checklist

- [ ] Login as receptionist → tap "Bookings" → list is visible.
- [ ] Tap "+" → Create Booking form opens with room type dropdown.
- [ ] Fill in guest info, pick dates, pick room type → save → booking appears in list as "BOOKED".
- [ ] Open booking detail → "Assign Room" button visible.
- [ ] Tap "Assign Room" → list of available rooms shown → select one → room assigned.
- [ ] Open booking detail again → room number now shown.
- [ ] Tap "Cancel" → enter reason → booking status changes to "CANCELLED".

---

## Branch and Commit Guidance

**Branch name**: `feature/module-b-booking`

**Commit message style**:
```
feat(booking): implement create booking form
feat(booking): implement booking list with status filter
feat(booking): implement assign room flow
feat(booking): implement cancel booking with reason
fix(booking): validate check-out after check-in date
```

---

## Merge Conflict Prevention Rules

- **Never edit** `lib/core/`, `lib/shared/`, `lib/main.dart` — request changes from Member 1.
- **Never edit** `lib/features/rooms/`, `lib/features/housekeeping/`, `lib/features/checkin_checkout/`, `lib/features/staff/`.
- **Never edit** `room_repository.dart`, `room_type_repository.dart` — read them but do not write to them.
- **Only create new files inside** `lib/features/bookings/`.
- If you need a constant or utility, ask Member 1 to add it to `lib/core/` or `lib/shared/`.

---

## AI Handoff Prompt Starter

```
You are implementing Module B (Booking) for the HMS Flutter project.

Allowed files (read + write):
- lib/features/bookings/screens/booking_screens.dart
- lib/data/repositories/booking_repository.dart
- lib/data/models/booking_model.dart
- lib/features/bookings/ (new files you create here are fine)

Read-only (call methods, do not edit):
- lib/data/repositories/room_repository.dart
- lib/data/repositories/room_type_repository.dart
- lib/features/auth/session_provider.dart (use context.read<SessionProvider>())

Forbidden files (do not touch):
- lib/core/constants/db_schema.dart
- lib/core/database/database_helper.dart
- lib/features/rooms/
- lib/features/housekeeping/
- lib/features/checkin_checkout/
- lib/features/staff/
- lib/data/repositories/invoice_repository.dart
- lib/data/repositories/surcharge_repository.dart
- lib/data/repositories/user_repository.dart

Rules:
- Do not redesign architecture.
- Do not modify DB schema unless explicitly instructed.
- Keep compile safety at all times.
- Use AppRoutes constants for all navigation.
- Use DateFormatter.toMs() for all date storage.
- Snapshot bookedPricePerNight from the room type at booking creation time.
- roomId is nullable — never require a room at booking creation.
```
