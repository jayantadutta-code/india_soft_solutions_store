import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  DBHelper._();

  /// Singleton instance
  static final DBHelper getInstance = DBHelper._();

  /// Table & Columns
  static const String TABLE_NOTE = "note";
  static const String COLUMN_NOTE_SNO = "s_no";
  static const String COLUMN_NOTE_TITLE = "title";
  static const String COLUMN_NOTE_DESC = "desc";

  Database? _db;

  /// Return DB instance
  Future<Database> getDB() async {
    _db ??= await _openDB();
    return _db!;
  }

  /// Open or Create DB
  Future<Database> _openDB() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String dbPath = join(appDir.path, "noteDB.db");

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        db.execute(
          """
          CREATE TABLE $TABLE_NOTE (
            $COLUMN_NOTE_SNO INTEGER PRIMARY KEY AUTOINCREMENT,
            $COLUMN_NOTE_TITLE TEXT,
            $COLUMN_NOTE_DESC TEXT
          )
          """,
        );
      },
    );
  }

  /// INSERT NOTE
  Future<bool> addNote({
    required String mTitle,
    required String mDesc,
  }) async {
    final db = await getDB();
    int rows = await db.insert(
      TABLE_NOTE,
      {
        COLUMN_NOTE_TITLE: mTitle,
        COLUMN_NOTE_DESC: mDesc,
      },
    );
    return rows > 0;
  }

  /// GET ALL NOTES
  Future<List<Map<String, dynamic>>> getALLNotes() async {
    final db = await getDB();
    return await db.query(TABLE_NOTE);
  }

  /// UPDATE NOTE
  Future<bool> updateNote({
    required int sno,
    required String mTitle,
    required String mDesc,
  }) async {
    final db = await getDB();
    int rows = await db.update(
      TABLE_NOTE,
      {
        COLUMN_NOTE_TITLE: mTitle,
        COLUMN_NOTE_DESC: mDesc,
      },
      where: "$COLUMN_NOTE_SNO = ?",
      whereArgs: [sno],
    );

    return rows > 0;
  }

  /// DELETE NOTE
  Future<bool> deleteNote(int sno) async {
    final db = await getDB();
    int rows = await db.delete(
      TABLE_NOTE,
      where: "$COLUMN_NOTE_SNO = ?",
      whereArgs: [sno],
    );
    return rows > 0;
  }
}
