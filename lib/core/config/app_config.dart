import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const _keyPattern = 'pattern';
  static const _keySalt    = 'salt';
  static const _keyViewMode = 'view_mode';
  static const _keySortMode = 'sort_mode';
  static const _keySortOrder = 'sort_order';
  static const _keyStartPath = 'start_path';
  static const _keyThemeMode = 'theme_mode';
  static const _keyTransferPath = 'transfer_path';
  static const _defaultSalt    = 'DEEPSAFE_TUZ_2026';
  static const _defaultPattern = [0, 3, 6, 7, 8];
  static const _defaultViewMode = 'list'; // 'list', 'grid_small', 'grid_large'
  static const _defaultSortMode = 'name'; // 'name', 'date', 'size'
  static const _defaultSortOrder = 'asc'; // 'asc', 'desc'

  static List<int> get defaultPattern => _defaultPattern;

  static Future<List<int>> getPattern() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_keyPattern);
    if (raw == null) return _defaultPattern;
    return (jsonDecode(raw) as List).cast<int>();
  }

  static Future<void> savePattern(List<int> pattern) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyPattern, jsonEncode(pattern));
  }

  static Future<String> getSalt() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keySalt) ?? _defaultSalt;
  }

  static Future<void> saveSalt(String salt) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keySalt, salt);
  }

  static Future<String> getViewMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyViewMode) ?? _defaultViewMode;
  }

  static Future<void> saveViewMode(String viewMode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyViewMode, viewMode);
  }

  static Future<String> getSortMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keySortMode) ?? _defaultSortMode;
  }

  static Future<void> saveSortMode(String sortMode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keySortMode, sortMode);
  }

  static Future<String> getSortOrder() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keySortOrder) ?? _defaultSortOrder;
  }

  static Future<void> saveSortOrder(String sortOrder) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keySortOrder, sortOrder);
  }

  static Future<String?> getStartPath() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyStartPath);
  }

  static Future<void> saveStartPath(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyStartPath, path);
  }

  static Future<String> getThemeMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyThemeMode) ?? 'light';
  }

  static Future<void> saveThemeMode(String mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyThemeMode, mode);
  }

  static Future<String?> getTransferPath() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyTransferPath);
  }

  static Future<void> saveTransferPath(String? path) async {
    final p = await SharedPreferences.getInstance();
    if (path == null) {
      await p.remove(_keyTransferPath);
    } else {
      await p.setString(_keyTransferPath, path);
    }
  }
}
