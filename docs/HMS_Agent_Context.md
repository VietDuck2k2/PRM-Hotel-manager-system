# HMS Agent Context Pack

## 1. Purpose of this file
This file is the stable project context for AI agents working on the Hotel Management System (HMS) project.
It is intended to reduce hallucination, keep business rules consistent, and help multiple agents generate code/specs with less conflict.

Use this file as the **source of truth** unless a newer approved decision document overrides it.

---

## 2. Project summary
- **Project name:** Hotel Management System (HMS)
- **Project type:** mobile programming course project
- **Target platform:** **Flutter mobile app**
- **Database choice for current implementation:** **SQLite using sqflite**
- **Deployment/demo context:** demo runs on **one machine / one device only**
- **Hotel scale:** about **50 rooms**
- **Usage model:** **staff-only internal system**
- **Primary goal:** stable demo of core hotel operations, not production-scale architecture

---

## 3. Non-negotiable architecture decisions
These points are already chosen and must **not** be changed by the agent unless explicitly asked.

1. The app is a **single Flutter project**.
2. There is **no separate backend folder/service** in the current version.
3. Data is stored locally using **SQLite + sqflite**.
4. The system only needs to support **single-device demo usage**.
5. Do **not** redesign the app into Firebase / Supabase / client-server architecture.
6. Do **not** add unnecessary enterprise features beyond the approved scope.

---

## 4. Business scope

### 4.1 In scope
- authentication for staff users
- role-based access for staff
- manage room types
- manage rooms
- manage staff users
- create internal booking
- view booking list and booking detail
- assign room to booking
- cancel booking with cancel reason
- check-in
- add surcharge
- check-out
- generate invoice
- confirm cash payment
- housekeeping cleaning task list
- housekeeping updates room from DIRTY to AVAILABLE

### 4.2 Out of scope
- customer self-registration / self-login
- public booking website/app
- OTA integration (Booking.com, Agoda, etc.)
- online payment
- deposit/prepayment
- storing CCCD/Passport in system
- advanced analytics/dashboard outside MVP
- multi-branch / multi-hotel architecture
- realtime multi-device synchronization

---

## 5. Actors and permissions

### 5.1 Receptionist
Main functions:
- login/logout
- create booking
- view booking list/detail
- assign room
- cancel booking with reason
- check-in
- add surcharge
- check-out
- generate invoice
- confirm cash payment
- view room list (read-only if management actions are restricted)

### 5.2 Housekeeping
Main functions:
- login/logout
- view cleaning task list
- update room cleaning status
- only handles cleaning workflow for dirty rooms

### 5.3 Manager/Admin
Main functions:
- has **all Receptionist permissions**
- plus management permissions:
  - manage room types
  - manage rooms
  - update room status including OUT_OF_SERVICE
  - manage staff users

### 5.4 Important role note
- **Manager/Admin includes all Receptionist capabilities.**
- **Housekeeping does not need the general room management screens.**

---

## 6. Core business rules

### 6.1 Payment
- **cash only**
- **no deposit**
- total amount includes:
  - room charge
  - surcharge total

### 6.2 Guest information
Store only:
- `guestName`
- `guestPhone`

Do not store:
- CCCD
- Passport

### 6.3 Booking statuses
- `BOOKED`
- `CANCELLED`
- `CHECKED_IN`
- `CHECKED_OUT`

### 6.4 Room statuses
- `AVAILABLE`
- `OCCUPIED`
- `DIRTY`
- `OUT_OF_SERVICE`

### 6.5 Booking creation and room assignment
- a booking **can be created without assigning a room immediately**
- `Booking.roomId` can be nullable during initial creation
- room assignment can happen later
- this separation is intentional and matches the approved business flow

### 6.6 Cancel booking rule
- booking can only be cancelled when status is `BOOKED`
- cancel reason is mandatory
- if a room was assigned, it must be released immediately

### 6.7 Check-in rule
- only allowed when booking status is `BOOKED`
- booking must already have an assigned room
- after check-in:
  - booking -> `CHECKED_IN`
  - room -> `OCCUPIED`

### 6.8 Add surcharge rule
- surcharge is tied to a booking
- surcharge is normally added during or after stay, before checkout finalization

### 6.9 Check-out rule
- only allowed when booking status is `CHECKED_IN`
- checkout must:
  - calculate room charge
  - calculate surcharge total
  - generate invoice
  - confirm cash payment
  - set booking -> `CHECKED_OUT`
  - set room -> `DIRTY`

### 6.10 Housekeeping rule
- housekeeping only updates room from:
  - `DIRTY -> AVAILABLE`

### 6.11 Room price rule
- room price is based on `RoomType`
- approved design is to store a **snapshot** on booking:
  - `bookedPricePerNight`
- purpose:
  - if room type price changes later, old bookings are not affected

### 6.12 Audit rule
- `Booking.createdBy` references a user
- `Invoice.issuedBy` references a user

---

## 7. Approved data model direction

### 7.1 Main entities
- `User`
- `RoomType`
- `Room`
- `Booking`
- `Surcharge`
- `Invoice`

### 7.2 Key relationships
- `RoomType 1 - n Room`
- `Room 1 - n Booking` (room can be nullable at booking creation time)
- `User 1 - n Booking`
- `Booking 1 - n Surcharge`
- `Booking 1 - 0..1 Invoice`
- `User 1 - n Invoice`

### 7.3 User table design rule
- use **one `User` entity/table** with a `role` field
- do **not** split Manager / Receptionist / Housekeeping into separate tables unless explicitly requested later

---

## 8. Suggested module boundaries for the codebase
These module boundaries are intended to reduce merge conflict.

### Module A — Core / App shell / DB integration
- app bootstrap
- routes/navigation
- theme/shared widgets
- local database init
- table creation
- seed data
- auth/session basics
- dashboard by role

### Module B — Booking
- booking list
- booking detail
- create booking
- assign room
- cancel booking

### Module C — Room + Housekeeping
- room type management
- room management
- room status management
- cleaning task list
- mark room available after cleaning

### Module D — Check-in / Checkout / Invoice
- check-in
- surcharge
- checkout
- invoice generation
- cash payment confirmation

---

## 9. Recommended folder structure direction
This is a direction, not a strict final file map.

```text
lib/
  core/
    constants/
    utils/
    database/
  data/
    models/
    repositories/
    datasources/local/
  features/
    auth/
    dashboard/
    bookings/
    rooms/
    housekeeping/
    checkin_checkout/
    invoices/
    staff/
  shared/
    widgets/
    themes/
  main.dart
```

Important:
- this is **not** a web-style `fe/` + `be/` split
- this is a **single Flutter application** with local persistence

---

## 10. Constraints for AI-generated output
When generating analysis, architecture, or skeleton code, the agent must follow these rules:

1. Do not invent extra modules outside project scope.
2. Do not change business rules that are already approved.
3. If the SRS draft contains inconsistent wording, identify it explicitly instead of silently overwriting it.
4. Prefer **simple, demo-friendly implementation** over enterprise complexity.
5. Use naming and structure that are easy for a 4-person student team to maintain.
6. Minimize merge conflict by keeping ownership per feature/module clear.
7. Focus on stable CRUD + business flow first, polish later.
8. Do not generate hidden dependencies between unrelated modules.

---

## 11. Known draft inconsistencies to watch for
The existing SRS draft may contain:
- inconsistent naming such as `Manager`, `Admin`, or `Manager/Admin`
- copied use-case sections that do not fully match final business rules
- screen/action descriptions that are broader than the approved MVP
- wording based on earlier design stages before SQLite/local-only was chosen

The agent should **flag inconsistencies** and propose corrections, but not arbitrarily rewrite approved decisions.

---

## 12. Expected output style from AI
For analysis tasks, the preferred output is:
- concise but structured
- explicit assumptions
- tables/checklists when helpful
- clear separation between:
  - confirmed facts
  - detected inconsistencies
  - recommendations
  - next-step implementation plan

---

## 13. Final reminder
This project is an academic Flutter mobile project. The best solution is not the most scalable architecture; it is the one that is:
- easiest to implement correctly
- easiest to demo on one machine
- easiest for a small team to divide into modules
- least likely to cause merge conflict

