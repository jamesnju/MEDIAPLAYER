// lib/core/database/migrations/migration_v2.dart
import 'package:sqflite/sqflite.dart';

class MigrationV2 {
  static Future<void> upgrade(Database db) async {
    // Add isFilteredOut column to songs table
    try {
      await db.execute('ALTER TABLE songs ADD COLUMN isFilteredOut INTEGER DEFAULT 0');
    } catch (e) {
      // Column might already exist
    }
    
    // Add isFilteredOut column to videos table
    try {
      await db.execute('ALTER TABLE videos ADD COLUMN isFilteredOut INTEGER DEFAULT 0');
    } catch (e) {
      // Column might already exist
    }
  }
}