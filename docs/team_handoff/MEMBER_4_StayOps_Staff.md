# Member 4 — Stay Operations & Staff Management

## Member Summary
- **Title**: Stay Operations & Staff Engineer
- **Owned module**: Check-in, surcharges, checkout, invoice generation, and staff CRUD
- **Main goal**: Allow receptionists and admins to check guests in and out with correct invoice generation, and allow admins to manage staff accounts.

---

## Scope

### In scope
- `lib/features/checkin_checkout/screens/checkin_checkout_screens.dart` — check-in, surcharge, checkout, invoice screens
- `lib/features/checkin_checkout/services/stay_service.dart` — full checkout transaction logic
- `lib/features/staff/screens/staff_screens.dart` — staff list and form screens
- `lib/data/models/surcharge_model.dart` — extend if needed
- `lib/data/models/invoice_model.dart` — extend if needed
- `lib/data/repositories/surcharge_repository.dart` — fully implement
- `lib/data/repositories/invoice_repository.dart` — fully implement
- `lib/data/repositories/user_repository.dart` — fully implement (staff CRUD)

### Out of scope
- Booking creation / assignment / cancellation → Member 2
- Room CRUD / housekeeping → Member 3
- Login / session / app shell → Member 1
- Room availability query → Member 3

---

## Owned Files and Folders

You are the **sole owner** of these files:

```
lib/features/checkin_checkout/screens/checkin_checkout_screens.dart
lib/features/checkin_checkout/services/stay_service.dart
lib/features/staff/screens/staff_screens.dart
lib/data/models/invoice_model.dart
lib/data/models/surcharge_model.dart
lib/data/repositories/invoice_repository.dart
lib/data/repositories/surcharge_repository.dart
lib/data/repositories/user_repository.dart
```

> **Likely new files you may need to create**:
> - `lib/features/checkin_checkout/providers/stay_provider.dart` — state management for active stay
> - `lib/features/staff/providers/staff_provider.dart` — state management for staff list
> - `lib/features/checkin_checkout/widgets/surcharge_list_tile.dart` — reusable surcharge item

---

## Ownership Boundary: Users vs Auth

> **Important split**: `user_model.dart` and `auth_repository.dart` are Member 1's files.
> `user_repository.dart` is **yours** (Member 4) — it handles staff CRUD (create, list, deactivate).
> **Do not touch** `auth_repository.dart` or `session_provider.dart`.
> For display only: call `UserRepository.getAllUsers()` and `UserRepository.getUserById()`.
> For creating a staff member: call `UserRepository.createUser()`.
> For deactivating (soft delete): call `UserRepository.deactivateUser()`.
> **Never hard-delete** a user row — use `isActive = 0`.

---

## Forbidden Files and Caution Files

| File | Rule |
|------|------|
| `lib/core/constants/db_schema.dart` | FORBIDDEN — Module A owns schema |
| `lib/core/database/database_helper.dart` | FORBIDDEN — Module A only |
| `lib/features/auth/session_provider.dart` | FORBIDDEN — read-only via `context.read<SessionProvider>()` |
| `lib/data/repositories/auth_repository.dart` | FORBIDDEN — Member 1 owns |
| `lib/data/models/user_model.dart` | CAUTION — Member 1 owns; read-only for you; coordinate if you need new fields |
| `lib/data/repositories/booking_repository.dart` | CAUTION — read-only; call `getBookingById()` and `updateStatus()` only |
| `lib/data/repositories/room_repository.dart` | CAUTION — read-only; call `updateStatus()` and `markRoomAvailable()` only |
| `lib/features/bookings/` | FORBIDDEN — Member 2 owns |
| `lib/features/rooms/` | FORBIDDEN — Member 3 owns |
| `lib/features/housekeeping/` | FORBIDDEN — Member 3 owns |

---

## Main Screens

All screens live in the files listed above (stubs from Phase B — replace stub bodies):

| Screen | File | Your task |
|--------|------|-----------|
| `CheckInScreen` | `checkin_checkout_screens.dart` | List BOOKED+assigned bookings; perform check-in |
| `SurchargeFormScreen` | `checkin_checkout_screens.dart` | Add a surcharge to an active stay |
| `CheckoutScreen` | `checkin_checkout_screens.dart` | Show stay summary/total; confirm and run checkout |
| `InvoiceDetailScreen` | `checkin_checkout_screens.dart` | Display a completed invoice |
| `StaffListScreen` | `staff_screens.dart` | List all active staff with role badge |
| `StaffFormScreen` | `staff_screens.dart` | Create / edit / deactivate staff account |

---

## Main Models / Tables / Repositories / Services

| Item | File | Your role |
|------|------|-----------|
| `SurchargeModel` | `lib/data/models/surcharge_model.dart` | **Own** |
| `InvoiceModel` | `lib/data/models/invoice_model.dart` | **Own** |
| `SurchargeRepository` | `lib/data/repositories/surcharge_repository.dart` | **Own** |
| `InvoiceRepository` | `lib/data/repositories/invoice_repository.dart` | **Own** |
| `UserRepository` | `lib/data/repositories/user_repository.dart` | **Own** |
| `StayService` | `lib/features/checkin_checkout/services/stay_service.dart` | **Own** |
| `BookingRepository` | provided by Member 2 | **Read-only** — `getBookingById()`, `updateStatus()` |
| `RoomRepository` | provided by Member 3 | **Read-only** — `updateStatus()`, `markRoomAvailable()` (may not be needed — see below) |
| `SessionProvider` | provided by Member 1 | **Read-only** — get `session.userId` for `issuedBy` / `createdBy` |

---

## StayService Implementation Guide

> `stay_service.dart` currently has stub methods with `TODO: [Module D]` comments. You must replace these with the real logic.

### `checkIn(int bookingId, int roomId)`
1. Validate: `booking.status == BOOKED` and `booking.roomId != null`.
2. Call `BookingRepository.updateStatus(bookingId, BookingStatus.checkedIn)`.
3. Call `RoomRepository.updateStatus(roomId, RoomStatus.occupied)`.

### `checkout({...})`
Run as a **single SQLite transaction** via `db.transaction()`:
1. Calculate `nights = DateFormatter.calculateNights(checkInMs, checkOutMs)`.
2. Calculate `roomCharge = nights * bookedPricePerNight`.
3. Fetch `surchargeTotal = await SurchargeRepository.getTotalSurcharge(bookingId)`.
4. Calculate `totalAmount = roomCharge + surchargeTotal`.
5. Insert into `invoices` table: `{bookingId, roomCharge, surchargeTotal, totalAmount, issuedBy, issuedAt}`.
6. Update booking status: `CHECKED_OUT`.
7. Update room status: `DIRTY`.
8. Return the created `InvoiceModel`.

> If any step fails, the whole transaction rolls back — sqflite handles this automatically inside `db.transaction()`.

---

## Business Rules to Respect

1. **Check-in requires an assigned room**: `booking.roomId` must not be null. Show an error if null.
2. **Check-in only from BOOKED**: `booking.status` must be `BOOKED` before check-in.
3. **Checkout only from CHECKED_IN**: validate status before running checkout.
4. **Invoice is created once, at checkout only**. The `invoices` table has a UNIQUE constraint on `bookingId` — do not attempt to create an invoice twice.
5. **Surcharges** can be added any time during the stay (between check-in and checkout). Each surcharge has a description and amount.
6. **Checkout is atomic**: all 3 DB operations (insert invoice, update booking, update room) must succeed together or not at all. Use `db.transaction()`.
7. **Cash only**: no payment gateway, no card storage. Invoice is for display/printing only.
8. **Staff management (admin only)**:
   - Admin can create, view, and deactivate (soft delete) staff.
   - `isActive = 0` counts as deactivated — the user cannot log in.
   - Passwords must be hashed using `UserModel.hashPassword()` before saving.
   - Never delete a user row from the DB.

---

## Recommended Implementation Steps

1. **Implement `UserRepository`** methods — `getAllUsers()`, `createUser()`, `getUserById()`, `deactivateUser()`.
2. **Implement `StaffListScreen`** — list all active users with role badge (Admin only).
3. **Implement `StaffFormScreen`** — create new staff (name, username, password, role dropdown). Hash password before save.
4. **Implement `SurchargeRepository`** — `addSurcharge()`, `getSurchargesForBooking()`, `getTotalSurcharge()`.
5. **Implement `CheckInScreen`**:
   - Fetch bookings with status `BOOKED` that have a `roomId` assigned.
   - Display list; tap to confirm check-in.
   - On confirm: call `StayService.checkIn(bookingId, roomId)`.
6. **Implement `SurchargeFormScreen`**:
   - Input description + amount.
   - On save: call `SurchargeRepository.addSurcharge(surcharge)`.
7. **Implement `CheckoutScreen`**:
   - Show breakdown: room charge (nights × rate), surcharge total, grand total.
   - On confirm: call `StayService.checkout(...)`.
   - On success: navigate to `InvoiceDetailScreen` with the returned invoice.
8. **Implement `InvoiceDetailScreen`** — display invoice fields.
9. **Implement `StayService.checkIn()` and `StayService.checkout()`** (replace TODO stubs with real logic as described above).
10. **Implement `InvoiceRepository`** — `createInvoice()`, `getInvoiceByBookingId()`.

---

## Dependencies on Other Members

### What you depend on from others

| What | From | When needed |
|------|------|-------------|
| `BookingRepository.getBookingById()` | Member 2 | Check-in and checkout |
| `BookingRepository.updateStatus()` | Member 2 | Inside StayService |
| `BookingRepository.getBookingsByStatus(BookingStatus.checkedIn)` | Member 2 | Populate checkout list |
| `RoomRepository.updateStatus()` | Member 3 | Inside StayService |
| `SessionProvider.userId` | Member 1 | `issuedBy` in invoice, `createdBy` in staff creation |
| `UserModel.hashPassword()` | Member 1 | Staff creation |
| `DateFormatter.calculateNights()` | Member 1 | Checkout calculation |
| `AppRoutes` constants | Member 1 | Navigation |

### What others depend on from you

| What | Dependant | Notes |
|------|-----------|-------|
| Nothing critical upstream | — | This is a leaf module |

---

## Acceptance Criteria

- [ ] Admin can create a staff account with username, password (hashed), full name, and role.
- [ ] Admin can deactivate a staff account → deactivated user cannot log in.
- [ ] A `BOOKED` booking with an assigned room can be checked in.
- [ ] Check-in attempt on a booking with no room assigned shows an error.
- [ ] After check-in: booking status = `CHECKED_IN`, room status = `OCCUPIED` in DB.
- [ ] Receptionist can add a surcharge to a `CHECKED_IN` booking.
- [ ] `CheckoutScreen` shows correct room charge (nights × snapshot price) and surcharge total.
- [ ] After checkout: booking status = `CHECKED_OUT`, room status = `DIRTY`, invoice record created.
- [ ] Invoice detail screen shows all breakdown fields.
- [ ] Invoice cannot be created twice for the same booking (constraint prevents it).
- [ ] `StayService.checkout()` runs as a single DB transaction.
- [ ] `flutter analyze` shows 0 errors.

---

## Demo Checklist

- [ ] Login as admin → tap "Staff" → staff list shows 3 seeded accounts.
- [ ] Create a new staff account → it appears in the list.
- [ ] Login as receptionist → create a booking → assign a room.
- [ ] Tap "Check-In" on dashboard → booking appears → tap to check in.
- [ ] Room status changes to `OCCUPIED`.
- [ ] Add a surcharge to the stay.
- [ ] Tap "Checkout" → see breakdown with surcharge.
- [ ] Confirm → invoice is shown with correct total.
- [ ] Room status changes to `DIRTY`.

---

## Branch and Commit Guidance

**Branch name**: `feature/module-d-stay-ops-staff`

**Commit message style**:
```
feat(staff): implement staff list and create form
feat(checkin): implement check-in flow
feat(surcharge): implement add surcharge form
feat(checkout): implement checkout transaction in StayService
feat(invoice): implement invoice detail screen
fix(stay): validate booking has assigned room before check-in
```

---

## Merge Conflict Prevention Rules

- **Never edit** `lib/core/`, `lib/shared/`, `lib/main.dart`.
- **Never edit** `lib/features/bookings/`, `lib/features/rooms/`, `lib/features/housekeeping/`.
- **Never edit** `booking_repository.dart` or `room_repository.dart` — call their methods only.
- **Never edit** `auth_repository.dart` or `session_provider.dart`.
- Only create new files inside `lib/features/checkin_checkout/` or `lib/features/staff/`.
- Coordinate with Member 1 before touching `user_model.dart`.

---

## AI Handoff Prompt Starter

```
You are implementing Module D (Stay Operations & Staff Management) for the HMS Flutter project.

Allowed files (read + write):
- lib/features/checkin_checkout/screens/checkin_checkout_screens.dart
- lib/features/checkin_checkout/services/stay_service.dart
- lib/features/staff/screens/staff_screens.dart
- lib/data/repositories/invoice_repository.dart
- lib/data/repositories/surcharge_repository.dart
- lib/data/repositories/user_repository.dart
- lib/data/models/invoice_model.dart
- lib/data/models/surcharge_model.dart
- lib/features/checkin_checkout/ (new files you create here are fine)
- lib/features/staff/ (new files you create here are fine)

Read-only (call methods, do not edit):
- lib/data/repositories/booking_repository.dart
- lib/data/repositories/room_repository.dart
- lib/features/auth/session_provider.dart
- lib/data/models/user_model.dart
- lib/core/utils/date_formatter.dart

Forbidden files (do not touch):
- lib/core/constants/db_schema.dart
- lib/core/database/database_helper.dart
- lib/data/repositories/auth_repository.dart
- lib/features/bookings/
- lib/features/rooms/
- lib/features/housekeeping/

Rules:
- Do not redesign architecture.
- Do not modify DB schema unless explicitly instructed.
- Keep compile safety at all times.
- StayService.checkout() MUST use db.transaction() for atomicity.
- Invoice is created ONLY during checkout, never earlier.
- Use UserModel.hashPassword() for all staff password creation.
- Never hard-delete a user row — use isActive = 0.
- Use AppRoutes constants for all navigation.
- Use SessionProvider.userId for issuedBy and createdBy fields.
```
