import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      final factory = databaseFactoryFfi;
      final pasta = await factory.getDatabasesPath();
      final caminho = join(pasta, 'pets_database.db');

      return factory.openDatabase(
        caminho,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE pets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nome TEXT NOT NULL,
                idade INTEGER NOT NULL
              )
            ''');
          },
        ),
      );
    }

    final pasta = await getDatabasesPath();
    final caminho = join(pasta, 'pets_database.db');

    return openDatabase(
      caminho,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            idade INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  static Future<int> inserirPet(
    String nome,
    int idade,
  ) async {
    final db = await database;

    return db.insert('pets', {
      'nome': nome,
      'idade': idade,
    });
  }

  static Future<List<Map<String, dynamic>>> listarPets() async {
    final db = await database;

    return db.query(
      'pets',
      orderBy: 'id DESC',
    );
  }

  static Future<int> atualizarPet(
    int id,
    String nome,
    int idade,
  ) async {
    final db = await database;

    return db.update(
      'pets',
      {
        'nome': nome,
        'idade': idade,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> apagarPet(int id) async {
    final db = await database;

    return db.delete(
      'pets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
