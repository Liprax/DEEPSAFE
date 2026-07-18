import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AliasService {
  static Database? _db;

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'aliases.db'),
      version: 2,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE aliases(path TEXT PRIMARY KEY, alias TEXT, icon_type TEXT)'
      ),
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('ALTER TABLE aliases ADD COLUMN icon_type TEXT');
        }
      },
    );
    return _db!;
  }

  static Future<void> setAlias(String path, String alias) async {
    final db = await _database;
    final existing = await getAliasData(path);
    await db.insert(
      'aliases',
      {'path': path, 'alias': alias, 'icon_type': existing?['icon_type']},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> setIcon(String path, String iconType) async {
    final db = await _database;
    final existing = await getAliasData(path);
    await db.insert(
      'aliases',
      {'path': path, 'alias': existing?['alias'], 'icon_type': iconType},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getAliasData(String path) async {
    final db = await _database;
    final maps = await db.query(
      'aliases',
      where: 'path = ?',
      whereArgs: [path],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  static Future<String?> getAlias(String path) async {
    final data = await getAliasData(path);
    return data?['alias'] as String?;
  }

  static Future<String?> getIcon(String path) async {
    final data = await getAliasData(path);
    return data?['icon_type'] as String?;
  }

  static Future<Map<String, Map<String, String>>> getAllData() async {
    final db = await _database;
    final maps = await db.query('aliases');
    return {
      for (final m in maps) 
        m['path'] as String: {
          'alias': (m['alias'] ?? '') as String,
          'icon': (m['icon_type'] ?? '') as String,
        }
    };
  }

  static Future<void> removeAlias(String path) async {
    final db = await _database;
    await db.delete('aliases', where: 'path = ?', whereArgs: [path]);
  }
}
