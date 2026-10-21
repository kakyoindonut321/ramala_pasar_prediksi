import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SQLite lokal: cache JSON + tabel untuk chatbot dan riwayat pencarian (tahap berikutnya).
class LocalDb {
  static Database? _db;

  static Future<Database> get _d async => _db ??= await openDatabase(
    join(await getDatabasesPath(), 'ramala.db'),
    version: 1,
    onCreate: (db, _) async {
      await db.execute(
        'create table cache(key text primary key, json text not null, updated_at integer not null)',
      );
      await db.execute(
        'create table chat_messages(id integer primary key autoincrement, role text not null, content text not null, created_at integer not null)',
      );
      await db.execute(
        'create table search_history(query text primary key, used_at integer not null)',
      );
    },
  );

  static Future<void> putCache(String key, Object json) async {
    final db = await _d;
    await db.insert('cache', {
      'key': key,
      'json': jsonEncode(json),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<dynamic> getCache(String key) async {
    final db = await _d;
    final r = await db.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return r.isEmpty ? null : jsonDecode(r.first['json'] as String);
  }

  /// Ambil dari server dan simpan. Jika jaringan gagal, pakai cache (jika ada).
  /// Error dari server (Postgrest/Auth) tidak memakai cache.
  static Future<List<Map<String, dynamic>>> cachedList(
    String key,
    Future<List<Map<String, dynamic>>> Function() fetch,
  ) async {
    try {
      final rows = await fetch();
      await putCache(key, rows);
      return rows;
    } catch (e) {
      if (e is PostgrestException || e is AuthException) rethrow;
      final c = await getCache(key);
      if (c is List)
        return c.map((x) => Map<String, dynamic>.from(x as Map)).toList();
      rethrow;
    }
  }

  static Future<void> clear() async {
    final db = await _d;
    await db.delete('cache');
    await db.delete('chat_messages');
    await db.delete('search_history');
  }

  static Future<void> addChat(String role, String content) async {
    final db = await _d;
    await db.insert('chat_messages', {
      'role': role,
      'content': content,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<Map<String, Object?>>> chatHistory({
    int limit = 50,
  }) async {
    final db = await _d;
    final r = await db.query('chat_messages', orderBy: 'id desc', limit: limit);
    return r.reversed.toList();
  }

  static Future<void> clearChat() async => (await _d).delete('chat_messages');
}
