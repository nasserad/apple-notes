import 'dart:async';

import 'package:apple_notes/services/crud/crud_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class NotesService {
  //THIS CLASS HANDLES TALKING TO OUR DB. SO, ONLY ONE INSTANCE IS NEEDED
  //(TO ESTABLISH A DB CONNECTION) AS MULTIPLE CONNECTIONS COULD CAUSE ERRORS/
  //UNNECESSARY OVERHEAD. (this is how we ensure that the db connection, _notes
  //cache, and streamcontroller are shared across the app).

  Database? _db;

  List<DatabaseNote> _notes = [];

  // SINGLETON
  // FIRST: Our singleton instance is first-ever created (basically the lines below) the first time the NotesService class
  // is referenced (this is how it is in Dart).
  static final NotesService _sharedInstance =
      NotesService._sharedInstanceAkaASingleton();

  NotesService._sharedInstanceAkaASingleton() {
    _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      },
    );
  }

  // SECOND: So, whenever NotesService() is called, it'll return the already created
  factory NotesService() => _sharedInstance;

  late final StreamController<List<DatabaseNote>> _notesStreamController;

  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      print('=> entered getOrCreateUser\n');
      print('=> trying to get user\n');
      final user = await getUser(email: email);
      print('=> successfully gotten the user, returning now\n');
      return user;
    } on CouldNotFindUserException {
      print('=> could not find user, attempting to create\n');
      final createdUser = await createUser(email: email);
      print('=> created successfully, returning now\n');
      return createdUser;
    } catch (e) {
      rethrow; //???
    }
  }

  Future<void> _ensureDbIsOpen() async {
    print('0> entered ensureDbIsOpen\n');
    try {
      print('0> trying to open db\n');
      await open();
    } on DatabaseAlreadyOpenException {
      print('0> db is already open, returning now\n');
      //Nothing.
    }
  }

  Future<void> open() async {
    print('@> entered openDB, checking if db already exists\n');
    if (_db != null) {
      print('@> db already exists, throwing exception\n');
      //throw DatabaseAlreadyOpenException;
      return;
    }
    print('@> db does not exist, attempting to get docs directory\n');
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      print('@> got docs directory, attempting to join db name with path\n');
      final dbPath = join(docsPath.path, dbName);
      print('@> joined db name with path, attempting to open db\n');
      final db = await openDatabase(dbPath);
      print('@> opened db successfully and saving it to local var\n');
      _db = db;

      print('@> attempting to create tables\n');
      await db.execute(createUserTable);

      await db.execute(createNoteTable);
      print('@> tables created successfully, attempting to cache notes\n');
      await _cacheNotes();
      print('@> notes cached successfully, returning now\n');
    } on MissingPlatformDirectoryException {
      print('@> could not get docs directory, throwing exception\n');
      throw UnableToGetDocumentsDirectoyException();
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteUserException();
    } else {}
  }

  Future<DatabaseUser> createUser({required String email}) async {
    print('+> entered createUser, ensuring db is open\n');
    await _ensureDbIsOpen();
    print('+> db is open, attempting to get db\n');
    final db = _getDatabaseOrThrow();
    print('+> gotten db successfully, attempting to query db for that user\n');
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      print('+> the user was found in db, creation stopped\n');
      throw UserAlreadyExistsException();
    }
    print(
        '+> the user was not found in db, attempting to insert one into db\n');
    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });
    print('+> user inserted successfully with id: ${userId}, returning now\n');

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<DatabaseUser> getUser({required String email}) async {
    print('-> entered getUser\n');
    await _ensureDbIsOpen(); //lessens overhead
    print('-> trying to get db\n');
    final db = _getDatabaseOrThrow();
    print('-> gotten the db\n');

    print('-> trying to query the db\n');
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    print('-> queryed the db\n');

    if (results.isEmpty) {
      print('-> no such user in db\n');
      throw CouldNotFindUserException();
    } else {
      print('-> found user in db and retrieved it successfully\n');
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final dbUser =
        await getUser(email: owner.email); //makes sure owner exists in db
    if (dbUser != owner) {
      throw CouldNotFindUserException();
    }

    const text = '';

    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedCount == 0) {
      throw CouldNotDeleteNoteException();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numOfDeletions = await db.delete(noteTable);

    _notes = [];
    _notesStreamController.add(_notes);

    return numOfDeletions;
  }

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (notes.isEmpty) {
      throw CouldNotFindNoteException();
    } else {
      final targetedNote = DatabaseNote.fromRow(
        notes.first,
      ); // if found translate (only first fetched) to a dart entity (instance of DatabaseNote).

      _notes.removeWhere((note) => note.id == id);
      _notes.add(targetedNote);
      _notesStreamController.add(_notes);

      return targetedNote;
    }
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);

    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
  }

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    await getNote(id: note.id);

    final updatesCount = await db.update(noteTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });

    if (updatesCount == 0) {
      throw CouldNotUpdateNoteException();
    } else {
      final updatedNote = await getNote(id: note.id);

      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);

      return updatedNote;
    }
  }
}

// Why immutable? Because this is basically like a db-translation class (translates db records to dart objects)
// so this isnt the place to change data, the logic here strictly concerns translation/fetching-data, instead of modifying it
// thus, we make it immutable to ensure that> increase code robustness+optimization> and protect it.
@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, Email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(
      // converts each db map (one row in the db) into a dart object (instance of this class (DatabaseNote))
      Map<String, Object?> map)
      : id = map[idColumn]
            as int, // accesses the value (assoc. w/ the key (idColumn)) in the map, casts into int to avoid typeMismatch error, then stores into our dart const.
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id, UserID = $userId, IsSyncedWithCloud = $isSyncedWithCloud, Text = $text';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const userTable = 'user';
const noteTable = 'note';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';
const createNoteTable = '''CREATE TABLE IF NOT EXISTS "note" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT,
        "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("user_id") REFERENCES "user"("id")
      );''';
