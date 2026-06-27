import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class CityDb {
  final Database _db;
  CityDb._(this._db);

  static Future<CityDb> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'cities_v1.db');

    if (!File(path).existsSync()) {
      final data = await rootBundle.load('assets/data/cities.db');
      await File(path).writeAsBytes(data.buffer.asUint8List());
    }

    final db = await openDatabase(path, readOnly: true);
    return CityDb._(db);
  }

  Future<List<Map<String, dynamic>>> searchCities(String query, {int limit = 20}) {
    return _db.query(
      'cities',
      where: 'ascii_name LIKE ?',
      whereArgs: ['${query.trim()}%'],
      orderBy: 'population DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> citiesInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int limit = 200,
  }) {
    return _db.query(
      'cities',
      where: 'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?',
      whereArgs: [minLat, maxLat, minLng, maxLng],
      orderBy: 'population DESC',
      limit: limit,
    );
  }

  Future<Map<String, dynamic>?> countryByCode(String code) async {
    final rows = await _db.query(
      'countries',
      where: 'iso_code = ?',
      whereArgs: [code.toUpperCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> close() => _db.close();
}
