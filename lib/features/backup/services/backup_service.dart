// lib/features/backup/services/backup_service.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupService {
  static const String _dbFileName = 'budgetr_db.sqlite';

  Future<Directory> getBackupDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory(
        '/storage/emulated/0/Download/FinStack 360/Backups',
      );
      try {
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } catch (e) {
        final extDir = await getExternalStorageDirectory();
        directory = Directory('${extDir!.path}/FinStack 360/Backups');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }
    } else {
      final docs = await getApplicationDocumentsDirectory();
      directory = Directory(p.join(docs.path, 'FinStack 360', 'Backups'));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
    return directory;
  }

  Future<Map<String, dynamic>?> getDatabaseInfo() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));
      if (!await dbFile.exists()) return null;
      return {
        'size': await dbFile.length(),
        'lastModified': await dbFile.lastModified(),
      };
    } catch (_) {
      return null;
    }
  }

  Future<List<File>> getAllBackups() async {
    try {
      final dir = await getBackupDirectory();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sqlite') || f.path.endsWith('.db'))
          .toList();

      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      return files;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestBackupInfo() async {
    try {
      final files = await getAllBackups();
      if (files.isEmpty) return null;

      final latest = files.first;
      return {
        'file': latest,
        'name': p.basename(latest.path),
        'size': await latest.length(),
        'date': await latest.lastModified(),
      };
    } catch (_) {
      return null;
    }
  }

  // --- LOCAL EXPORT ---
  Future<String?> exportDatabase() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      if (!await dbFile.exists()) {
        return 'Database file not found.';
      }

      final dir = await getBackupDirectory();
      final dateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
      final backupFileName = 'FinStack360_Backup_$dateStr.sqlite';

      await dbFile.copy(p.join(dir.path, backupFileName));
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // --- EXTERNAL SHARE EXPORT ---
  Future<String?> exportDatabaseExternal() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      if (!await dbFile.exists()) {
        return 'ERROR: Database file not found.';
      }

      // Copy to temporary directory so it can be safely handed off to other apps
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy_MMM_dd_HH_mm').format(DateTime.now());
      final backupFileName = 'FinStack360_Backup_$dateStr.sqlite';

      final tempFile = await dbFile.copy(p.join(tempDir.path, backupFileName));

      // Return the file path so the UI can trigger the share sheet
      return tempFile.path;
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  Future<String?> restoreDatabase(File fileToRestore) async {
    try {
      final fileName = fileToRestore.path.toLowerCase();
      if (!fileName.endsWith('.sqlite') && !fileName.endsWith('.db')) {
        return 'Invalid file type. Select a .sqlite backup file.';
      }

      final dbFolder = await getApplicationDocumentsDirectory();
      final targetFile = File(p.join(dbFolder.path, _dbFileName));

      final walFile = File(p.join(dbFolder.path, '$_dbFileName-wal'));
      final shmFile = File(p.join(dbFolder.path, '$_dbFileName-shm'));

      if (await targetFile.exists()) await targetFile.delete();
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();

      await fileToRestore.copy(targetFile.path);

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
