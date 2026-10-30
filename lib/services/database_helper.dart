import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fuel_logs.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Trova il percorso sicuro sul dispositivo (iOS/Android)
    Directory dbDirectory = await getApplicationDocumentsDirectory();
    String path = join(dbDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabella per i veicoli
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');
    // Tabella per i rifornimenti (allineata al tuo modello FuelLog)
    await db.execute('''
      CREATE TABLE fuel_logs (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        date TEXT NOT NULL,
        liters REAL NOT NULL,
        costEuro REAL NOT NULL,
        odometer REAL NOT NULL
      )
    ''');
  }

  // Inserisci un nuovo rifornimento
  Future<int> insertFuelLog(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('fuel_logs', row);
  }

  // Leggi tutti i rifornimenti ordinati per data
  Future<List<Map<String, dynamic>>> fetchFuelLogs() async {
    final db = await instance.database;
    return await db.query('fuel_logs', orderBy: 'date DESC');
  }

  // Elimina un rifornimento
  Future<int> deleteFuelLog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'fuel_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Inserisci un veicolo
  Future<int> insertVehicle(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('vehicles', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Leggi tutti i veicoli
  Future<List<Map<String, dynamic>>> fetchVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles');
  }

  // Elimina un veicolo
  Future<int> deleteVehicle(String id) async {
    final db = await instance.database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // Metodo utile per ottenere il file fisico del database (fondamentale per il futuro backup su Google Drive)
  Future<File> getDatabaseFile() async {
    Directory dbDirectory = await getApplicationDocumentsDirectory();
    String path = join(dbDirectory.path, 'fuel_logs.db');
    return File(path);
  }
}