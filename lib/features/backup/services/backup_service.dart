// lib/features/backup/services/backup_service.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart'; // <-- ADDED

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupService {
  static const String _dbFileName = 'budgetr_db.sqlite';
  HttpServer? _wifiServer;

  // --- PERMISSION HANDLER ---
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 11+ (API 30+) requires Manage External Storage
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Android 10 and below fallback
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
    return await Permission.storage.isGranted;
  }

  Future<Directory> getBackupDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception(
          'Storage permission denied. Cannot access the Downloads folder.',
        );
      }

      // Target the public Android Downloads folder directly
      directory = Directory('/storage/emulated/0/Download/FinStack 360');

      if (!await directory.exists()) {
        await directory.create(recursive: true);
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

  Future<String?> exportDatabase() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      if (!await dbFile.exists()) {
        return 'Database file not found.';
      }

      final dir = await getBackupDirectory();
      final dateStr = DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
      final backupFileName = 'FinStack360_Backup_$dateStr.sqlite';

      await dbFile.copy(p.join(dir.path, backupFileName));
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> exportDatabaseExternal() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      if (!await dbFile.exists()) {
        return 'ERROR: Database file not found.';
      }

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy_MMM_dd').format(DateTime.now());
      final backupFileName = 'FinStack360_Backup_$dateStr.sqlite';

      final tempFile = await dbFile.copy(p.join(tempDir.path, backupFileName));

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

  Future<String?> startWifiShare() async {
    try {
      final ip = await NetworkInfo().getWifiIP();
      if (ip == null || ip.isEmpty) {
        return 'ERROR: Could not fetch Wi-Fi IP. Ensure you are connected to a Wi-Fi network.';
      }

      final tempPath = await exportDatabaseExternal();
      if (tempPath != null && tempPath.startsWith('ERROR')) return tempPath;

      _wifiServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);

      _wifiServer!.listen((HttpRequest request) async {
        if (request.uri.path == '/sync') {
          final file = File(tempPath!);
          request.response.headers.contentType = ContentType(
            'application',
            'octet-stream',
          );
          request.response.headers.add(
            'Content-Disposition',
            'attachment; filename="finstack_sync.sqlite"',
          );
          request.response.contentLength = await file.length();
          await file.openRead().pipe(request.response);
          request.response.close();
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.close();
        }
      });

      return 'http://$ip:${_wifiServer!.port}/sync';
    } catch (e) {
      return 'ERROR: Failed to start local server. ($e)';
    }
  }

  void stopWifiShare() {
    _wifiServer?.close(force: true);
    _wifiServer = null;
  }

  Future<String?> downloadAndRestoreFromWifi(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          p.join(tempDir.path, 'wifi_sync_download.sqlite'),
        );
        await tempFile.writeAsBytes(response.bodyBytes);

        return await restoreDatabase(tempFile);
      } else {
        return 'ERROR: Host device responded with status ${response.statusCode}.';
      }
    } catch (e) {
      return 'ERROR: Connection failed. Ensure BOTH devices are connected to the exact same Wi-Fi network. ($e)';
    }
  }
}
