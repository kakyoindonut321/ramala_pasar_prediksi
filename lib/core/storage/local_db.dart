const dbVersion = 1;
const migrations = <int, List<String>>{
  1: [
    'CREATE TABLE cache (key TEXT PRIMARY KEY, json TEXT NOT NULL, updated_at INTEGER NOT NULL)',
    'CREATE TABLE chat_messages (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT NOT NULL, content TEXT NOT NULL, created_at INTEGER NOT NULL)',
    'CREATE TABLE search_history (query TEXT PRIMARY KEY, used_at INTEGER NOT NULL)',
  ],
  // 2: [ ... ]  // perubahan skema nanti cukup tambah versi baru
};
