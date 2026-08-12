// lib/features/backup/views/backup_page.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:restart_app/restart_app.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/components/futuristic_loader.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/database/database_provider.dart';
import '../services/backup_service.dart';
import 'wifi_scanner_page.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _isLoading = false;
  String _loadingLabel = 'PROCESSING...';

  // Removed Wi-Fi from here, keeping standard exports clean
  String _exportTarget = 'Local Folder';

  Map<String, dynamic>? _dbInfo;
  Map<String, dynamic>? _latestBackup;
  String _backupPath = 'Scanning...';

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final service = ref.read(backupServiceProvider);
    final dbInfo = await service.getDatabaseInfo();
    final latestBackup = await service.getLatestBackupInfo();
    final dir = await service.getBackupDirectory();

    if (mounted) {
      setState(() {
        _dbInfo = dbInfo;
        _latestBackup = latestBackup;
        _backupPath = dir.path.split('0/').last;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _selectExportTarget() async {
    HapticFeedback.lightImpact();
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Export Target',
      items: const ['Local Folder', 'Share / Google Drive'],
      selectedValue: _exportTarget,
    );

    if (selected != null && mounted) {
      setState(() {
        _exportTarget = selected;
      });
    }
  }

  // --- STANDARD EXPORT ---
  Future<void> _handleExport() async {
    HapticFeedback.selectionClick();
    setState(() {
      _isLoading = true;
      _loadingLabel = 'PREPARING BACKUP...';
    });

    if (_exportTarget == 'Local Folder') {
      final error = await ref.read(backupServiceProvider).exportDatabase();
      if (mounted) {
        setState(() => _isLoading = false);
        if (error != null) {
          CustomSnackbars.showError(context, message: error);
        } else {
          CustomSnackbars.showSuccess(
            context,
            message: 'Backup successfully exported.',
          );
          _loadMetrics();
        }
      }
    } else if (_exportTarget == 'Share / Google Drive') {
      final result = await ref
          .read(backupServiceProvider)
          .exportDatabaseExternal();
      if (mounted) {
        setState(() => _isLoading = false);
        if (result != null && result.startsWith('ERROR:')) {
          CustomSnackbars.showError(
            context,
            message: result.replaceFirst('ERROR: ', ''),
          );
        } else if (result != null) {
          await Share.shareXFiles([
            XFile(result),
          ], subject: 'FinStack 360 Ledger Backup');
        }
      }
    }
  }

  // --- WI-FI GENERATOR (HOST) ---
  Future<void> _startWifiHost() async {
    HapticFeedback.selectionClick();
    setState(() {
      _isLoading = true;
      _loadingLabel = 'STARTING LOCAL SERVER...';
    });

    final result = await ref.read(backupServiceProvider).startWifiShare();

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null && result.startsWith('ERROR:')) {
        CustomSnackbars.showError(
          context,
          message: result.replaceFirst('ERROR: ', ''),
        );
      } else if (result != null) {
        _showQrHostSheet(result);
      }
    }
  }

  void _showQrHostSheet(String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wi-Fi Sync Active',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan this QR code from another device on the same network to pull your ledger data.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black87,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ModernBoxyButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(backupServiceProvider).stopWifiShare();
                  Navigator.pop(ctx);
                },
                label: 'STOP SHARING',
                isOutlined: true,
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WI-FI SCANNER (CLIENT) ---
  Future<void> _handleWifiRestore() async {
    final scannedUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const WifiScannerPage()),
    );

    if (scannedUrl == null || !mounted) return;

    final confirm = await ConfirmationBottomSheet.show(
      context,
      title: 'Sync Over Wi-Fi?',
      description:
          'This will completely overwrite your current data with the database retrieved from the host device. Proceed?',
      confirmText: 'SYNC NOW',
      isDestructive: true,
      onConfirm: () {},
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _loadingLabel = 'DOWNLOADING FROM HOST...';
    });

    try {
      final activeDb = ref.read(databaseProvider);
      try {
        await activeDb.close().timeout(const Duration(milliseconds: 500));
      } catch (_) {}

      final error = await ref
          .read(backupServiceProvider)
          .downloadAndRestoreFromWifi(scannedUrl);

      if (error != null && mounted) {
        setState(() => _isLoading = false);
        CustomSnackbars.showError(context, message: error);
        return;
      }

      Restart.restartApp();
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _isLoading = false);
        _showRestartDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbars.showError(context, message: 'Sync failed: $e');
      }
    }
  }

  // --- STANDARD RESTORE ---
  Future<void> _handleRestore(File file) async {
    HapticFeedback.heavyImpact();

    final confirm = await ConfirmationBottomSheet.show(
      context,
      title: 'Restore Ledger?',
      description:
          'This will permanently overwrite all your current data with the selected backup. This cannot be undone.',
      confirmText: 'OVERWRITE DATA',
      isDestructive: true,
      onConfirm: () {},
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _loadingLabel = 'RESTORING LEDGER...';
    });

    try {
      final activeDb = ref.read(databaseProvider);
      try {
        await activeDb.close().timeout(const Duration(milliseconds: 500));
      } catch (_) {}

      final error = await ref.read(backupServiceProvider).restoreDatabase(file);

      if (error != null && mounted) {
        setState(() => _isLoading = false);
        CustomSnackbars.showError(context, message: error);
        return;
      }

      Restart.restartApp();

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _isLoading = false);
        _showRestartDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbars.showError(context, message: 'Restore failed: $e');
      }
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restoration Complete',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: Text(
          'Your ledger data has been successfully restored.\n\nPlease completely close and reopen FinStack 360 to apply the database changes safely.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Platform.isAndroid) SystemNavigator.pop();
            },
            child: const Text(
              'ACKNOWLEDGE',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocalBackupsSheet() async {
    HapticFeedback.lightImpact();
    final files = await ref.read(backupServiceProvider).getAllBackups();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 16, bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Backup',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${files.length} Files',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              Expanded(
                child: files.isEmpty
                    ? Center(
                        child: Text(
                          'No backups found in directory.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final stat = file.statSync();
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.description_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              p.basename(file.path),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatSize(stat.size)}  •  ${DateFormat('dd MMM yyyy, HH:mm').format(stat.modified)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _handleRestore(file);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- COMPACT SECTION HEADER HELPER ---
  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  // --- FULLY COMPACTED METRIC CARD FOR SINGLE SCREEN VIEW ---
  Widget _buildMetricCard({
    required String label,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
    VoidCallback? onTap,
    bool showDropdown = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final isInteractive = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0), // Compact Margin
        padding: const EdgeInsets.all(12.0), // Compact Padding
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInteractive
                ? theme.colorScheme.primary.withOpacity(0.4)
                : theme.dividerColor,
            width: isInteractive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), // Scaled Icon Container
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9, // Scaled down
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14, // Scaled down
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11, // Scaled down
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showDropdown)
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData targetIcon = Icons.folder_rounded;
    String targetSub = 'Local Device Storage';
    if (_exportTarget == 'Share / Google Drive') {
      targetIcon = Icons.cloud_upload_rounded;
      targetSub = 'Google Drive, Email, etc.';
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: ModernAppBar(
            title: 'Ledger Security',
            subtitle: 'OFFLINE DATA MANAGEMENT',
            leadingIcon: Icons.arrow_back_rounded,
            onLeadingPressed: _isLoading ? () {} : () => Navigator.pop(context),
          ),
          body: SafeArea(
            // Removed SingleChildScrollView and replaced with a stretching Column.
            // Spacers distribute empty space evenly across the single screen view.
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingLg,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. SYSTEM STATUS ---
                  _buildSectionHeader(theme, 'SYSTEM STATUS'),
                  _buildMetricCard(
                    theme: theme,
                    label: 'Active Database',
                    title: 'budgetr_db.sqlite',
                    subtitle: _dbInfo != null
                        ? '${_formatSize(_dbInfo!['size'])}  •  Live & Encrypted'
                        : 'Scanning...',
                    icon: Icons.shield_rounded,
                  ),

                  const Spacer(flex: 2),

                  // --- 2. EXPORT DESTINATION ---
                  _buildSectionHeader(theme, 'EXPORT DESTINATION'),
                  _buildMetricCard(
                    theme: theme,
                    label: 'Save Target',
                    title: _exportTarget == 'Local Folder'
                        ? _backupPath
                        : _exportTarget,
                    subtitle: targetSub,
                    icon: targetIcon,
                    onTap: _selectExportTarget,
                    showDropdown: true,
                  ),
                  ModernBoxyButton(
                    onPressed: _isLoading ? null : _handleExport,
                    label: 'EXPORT BACKUP',
                    icon: Icons.upload_rounded,
                  ),

                  const Spacer(flex: 2),

                  // --- 3. RESTORE TARGET ---
                  _buildSectionHeader(theme, 'RESTORE TARGET'),
                  if (_latestBackup != null) ...[
                    _buildMetricCard(
                      theme: theme,
                      label: 'Latest Archive Found',
                      title: _latestBackup!['name'],
                      subtitle:
                          '${_formatSize(_latestBackup!['size'])}  •  ${DateFormat('dd MMM yyyy, HH:mm').format(_latestBackup!['date'] as DateTime)}',
                      icon: Icons.restore_page_rounded,
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ModernBoxyButton(
                            onPressed: _isLoading
                                ? null
                                : () => _handleRestore(
                                    _latestBackup!['file'] as File,
                                  ),
                            label: 'RESTORE LATEST',
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacingMd),
                        Expanded(
                          child: ModernBoxyButton(
                            onPressed: _isLoading
                                ? null
                                : _showLocalBackupsSheet,
                            label: 'BROWSE',
                            isOutlined: true,
                            icon: Icons.search_rounded,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16), // Compressed Padding
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No recent backups found in the FinStack 360 directory.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8), // Compressed Margin
                    ModernBoxyButton(
                      onPressed: _isLoading ? null : _showLocalBackupsSheet,
                      label: 'BROWSE LOCAL FILES',
                      isOutlined: true,
                      icon: Icons.search_rounded,
                    ),
                  ],

                  const Spacer(flex: 2),

                  // --- 4. PEER-TO-PEER SYNC ---
                  _buildSectionHeader(theme, 'PEER-TO-PEER SYNC'),
                  _buildMetricCard(
                    theme: theme,
                    label: 'Wi-Fi Network',
                    title: 'Local Device Transfer',
                    subtitle: 'Host or Scan to sync directly',
                    icon: Icons.wifi_tethering_rounded,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ModernBoxyButton(
                          onPressed: _isLoading ? null : _startWifiHost,
                          label: 'HOST (QR)',
                          icon: Icons.qr_code_2_rounded,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMd),
                      Expanded(
                        child: ModernBoxyButton(
                          onPressed: _isLoading ? null : _handleWifiRestore,
                          label: 'SCAN (QR)',
                          isOutlined: true,
                          icon: Icons.qr_code_scanner_rounded,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),

        // --- FULL SCREEN FUTURISTIC LOADER OVERLAY ---
        if (_isLoading)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    color: theme.scaffoldBackgroundColor.withOpacity(0.85),
                    child: Center(
                      child: FuturisticLoader(size: 80, label: _loadingLabel),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
