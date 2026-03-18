class DbSchema {
  static const String usersTable = 'users';
  static const String createUsersTable = '''
    CREATE TABLE $usersTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      isActive INTEGER NOT NULL DEFAULT 1
    )
  ''';

  static const String roomsTable = 'rooms';
  static const String createRoomsTable = '''
    CREATE TABLE $roomsTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      roomNumber TEXT NOT NULL UNIQUE,
      typeId INTEGER NOT NULL,
      status TEXT NOT NULL
    )
  ''';

  static const String roomTypesTable = 'room_types';
  static const String createRoomTypesTable = '''
    CREATE TABLE $roomTypesTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      pricePerNight REAL NOT NULL
    )
  ''';

  static const String bookingsTable = 'bookings';
  static const String createBookingsTable = '''
    CREATE TABLE $bookingsTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      guestName TEXT NOT NULL,
      guestPhone TEXT,
      roomId INTEGER NOT NULL,
      checkInDate INTEGER NOT NULL,
      checkOutDate INTEGER NOT NULL,
      status TEXT NOT NULL,
      createdBy INTEGER NOT NULL,
      FOREIGN KEY (roomId) REFERENCES $roomsTable (id),
      FOREIGN KEY (createdBy) REFERENCES $usersTable (id)
    )
  ''';
  
  static const String invoicesTable = 'invoices';
  static const String createInvoicesTable = '''
    CREATE TABLE $invoicesTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookingId INTEGER NOT NULL,
      totalAmount REAL NOT NULL,
      issuedDate INTEGER NOT NULL,
      issuedBy INTEGER NOT NULL,
      FOREIGN KEY (bookingId) REFERENCES $bookingsTable (id),
      FOREIGN KEY (issuedBy) REFERENCES $usersTable (id)
    )
  ''';

  static const String surchargesTable = 'surcharges';
  static const String createSurchargesTable = '''
    CREATE TABLE $surchargesTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookingId INTEGER NOT NULL,
      description TEXT NOT NULL,
      amount REAL NOT NULL,
      FOREIGN KEY (bookingId) REFERENCES $bookingsTable (id)
    )
  ''';

  static const String cleaningTasksTable = 'cleaning_tasks';
  static const String createCleaningTasksTable = '''
    CREATE TABLE $cleaningTasksTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      roomId INTEGER NOT NULL,
      assignedTo INTEGER,
      status TEXT NOT NULL,
      FOREIGN KEY (roomId) REFERENCES $roomsTable (id),
      FOREIGN KEY (assignedTo) REFERENCES $usersTable (id)
    )
  ''';
}
