// Centralized database schema definitions.
// ALL CREATE TABLE SQL lives here. Do NOT write CREATE TABLE elsewhere.
// OWNERSHIP: Module A (Core & DB Foundation)
// Other modules must not modify DB schema directly.

class DbSchema {
  // ─── Table Names ──────────────────────────────────────────────────────────
  static const String tableUsers = 'users';
  static const String tableRoomTypes = 'room_types';
  static const String tableRooms = 'rooms';
  static const String tableHousekeepingTasks = 'housekeeping_tasks';
  static const String tableBookings = 'bookings';
  static const String tableSurcharges = 'surcharges';
  static const String tableInvoices = 'invoices';

  // ─── Database version ─────────────────────────────────────────────────────
  static const int dbVersion = 2;

  // ─── CREATE TABLE Statements ──────────────────────────────────────────────

  static const String createUsers = '''
    CREATE TABLE $tableUsers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      passwordHash TEXT NOT NULL,
      fullName TEXT NOT NULL,
      role TEXT NOT NULL,
      isActive INTEGER NOT NULL DEFAULT 1,
      createdAt INTEGER NOT NULL
    )
  ''';
  // role values: 'admin' | 'receptionist' | 'housekeeping'
  // isActive: 1 = active, 0 = deactivated
  // dates stored as Unix ms (milliseconds since epoch)

  static const String createRoomTypes = '''
    CREATE TABLE $tableRoomTypes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      pricePerNight REAL NOT NULL,
      description TEXT
    )
  ''';

  static const String createRooms = '''
    CREATE TABLE $tableRooms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      roomNumber TEXT NOT NULL UNIQUE,
      roomTypeId INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'AVAILABLE',
      notes TEXT,
      checkoutSinceLastFloorClean INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (roomTypeId) REFERENCES $tableRoomTypes(id)
    )
  ''';
  // status values: 'AVAILABLE' | 'OCCUPIED' | 'DIRTY' | 'OUT_OF_SERVICE'

  static const String createBookings = '''
    CREATE TABLE $tableBookings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      guestName TEXT NOT NULL,
      guestPhone TEXT NOT NULL,
      roomTypeId INTEGER NOT NULL,
      roomId INTEGER,
      checkInDate INTEGER NOT NULL,
      checkOutDate INTEGER NOT NULL,
      bookedPricePerNight REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'BOOKED',
      cancelReason TEXT,
      createdBy INTEGER NOT NULL,
      createdAt INTEGER NOT NULL,
      FOREIGN KEY (roomTypeId) REFERENCES $tableRoomTypes(id),
      FOREIGN KEY (roomId) REFERENCES $tableRooms(id),
      FOREIGN KEY (createdBy) REFERENCES $tableUsers(id)
    )
  ''';
  // roomId is nullable — booking can be created without room assignment
  // status values: 'BOOKED' | 'CANCELLED' | 'CHECKED_IN' | 'CHECKED_OUT'
  // bookedPricePerNight is a snapshot of RoomType.pricePerNight at booking time

  static const String createSurcharges = '''
    CREATE TABLE $tableSurcharges (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookingId INTEGER NOT NULL,
      description TEXT NOT NULL,
      amount REAL NOT NULL,
      createdAt INTEGER NOT NULL,
      FOREIGN KEY (bookingId) REFERENCES $tableBookings(id)
    )
  ''';

  static const String createInvoices = '''
    CREATE TABLE $tableInvoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookingId INTEGER NOT NULL UNIQUE,
      roomCharge REAL NOT NULL,
      surchargeTotal REAL NOT NULL,
      totalAmount REAL NOT NULL,
      issuedBy INTEGER NOT NULL,
      issuedAt INTEGER NOT NULL,
      FOREIGN KEY (bookingId) REFERENCES $tableBookings(id),
      FOREIGN KEY (issuedBy) REFERENCES $tableUsers(id)
    )
  ''';
  // Exactly one Invoice per Booking (UNIQUE constraint on bookingId)
  // Invoice is created only during checkout — never created earlier

  static const String createHousekeepingTasks = '''
    CREATE TABLE IF NOT EXISTS $tableHousekeepingTasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      roomId INTEGER NOT NULL,
      sourceType TEXT NOT NULL,
      status TEXT NOT NULL,
      assignedHousekeeperId INTEGER,
      assignedHousekeeperName TEXT,
      dirtyAt INTEGER NOT NULL,
      startedAt INTEGER,
      finishedAt INTEGER,
      needChangeSheets INTEGER NOT NULL,
      needCleanBathroom INTEGER NOT NULL,
      needMopFloor INTEGER NOT NULL,
      doneChangeSheets INTEGER NOT NULL DEFAULT 0,
      doneCleanBathroom INTEGER NOT NULL DEFAULT 0,
      doneMopFloor INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (roomId) REFERENCES $tableRooms(id)
    )
  ''';

  static List<String> get allCreateStatements => [
        createUsers,
        createRoomTypes,
        createRooms,
        createBookings,
        createSurcharges,
        createInvoices,
        createHousekeepingTasks,
      ];
}
