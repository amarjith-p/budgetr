// lib/features/smart_trackers/services/smart_tracker_export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../models/tracker_field_model.dart';

class SmartTrackerExportResult {
  final String publicPath;
  final String safeCachePath;
  SmartTrackerExportResult({
    required this.publicPath,
    required this.safeCachePath,
  });
}

class SmartTrackerExportService {
  // Added a flag to optionally strip the currency symbol for CSV exports
  static String formatValue(
    TrackerField field,
    dynamic value, {
    bool forCsv = false,
  }) {
    if (value == null || value.toString().isEmpty) return '-';
    try {
      if (field.type == TrackerFieldType.checkbox && value is List) {
        return value.join(', ');
      }
      if (field.type == TrackerFieldType.currency) {
        if (forCsv) {
          // Strictly return just the number for CSV to avoid Excel corruption
          return value.toString().trim();
        }
        // Return with symbol for PDF and UI
        return '${field.currencySymbol ?? ''} $value'.trim();
      }
      if (field.type == TrackerFieldType.date) {
        return DateFormat(
          'dd MMM yyyy',
        ).format(DateTime.parse(value.toString()));
      }
      if (field.type == TrackerFieldType.toggle) {
        return value == true ? 'Yes' : 'No';
      }
      return value.toString();
    } catch (e) {
      return value.toString();
    }
  }

  // --- NEW: CALCULATE FOOTER AGGREGATES ---
  List<String> _generateFooterRow(
    List<TrackerField> fields,
    List<SmartTrackerRecord> records, {
    required bool forCsv,
  }) {
    List<String> footerRow = [];
    bool hasAnyAggregate = false;

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];
      final canAggregate =
          field.type == TrackerFieldType.number ||
          field.type == TrackerFieldType.currency ||
          field.type == TrackerFieldType.formula;

      if (!canAggregate ||
          field.aggregate == null ||
          field.aggregate == 'NONE' ||
          field.aggregate!.isEmpty) {
        footerRow.add(''); // Placeholder for columns without aggregates
        continue;
      }

      hasAnyAggregate = true;
      double sum = 0;
      double minVal = double.infinity;
      double maxVal = double.negativeInfinity;
      int count = 0;

      for (var record in records) {
        final dataMap = jsonDecode(record.dataJson);
        final val = double.tryParse(dataMap[field.id]?.toString() ?? '');
        if (val != null) {
          sum += val;
          count++;
          if (val < minVal) minVal = val;
          if (val > maxVal) maxVal = val;
        }
      }

      String result = '';
      if (count > 0) {
        if (field.aggregate == 'SUM') result = sum.toStringAsFixed(2);
        if (field.aggregate == 'AVG') result = (sum / count).toStringAsFixed(2);
        if (field.aggregate == 'MAX') result = maxVal.toStringAsFixed(2);
        if (field.aggregate == 'MIN') result = minVal.toStringAsFixed(2);

        if (field.type == TrackerFieldType.currency && !forCsv) {
          result = '${field.currencySymbol ?? ''} $result'.trim();
        }

        // Append prefix so it reads cleanly (e.g., "SUM: 500")
        result = '${field.aggregate}: $result';
      }
      footerRow.add(result);
    }

    // If aggregates exist, label the first empty column
    if (hasAnyAggregate) {
      if (footerRow.isNotEmpty && footerRow[0] == '') {
        footerRow[0] = 'AGGREGATES';
      }
      return footerRow;
    }

    return [];
  }

  Future<SmartTrackerExportResult> _saveFile(
    String defaultFileName,
    dynamic content,
    String formatFolder,
  ) async {
    try {
      final folderDate = DateFormat('MMM yyyy').format(DateTime.now());
      final folderPath =
          'FinStack 360/Smart Trackers/$folderDate/$formatFolder';

      Directory publicDir;
      if (Platform.isAndroid) {
        publicDir = Directory('/storage/emulated/0/Download/$folderPath');
      } else {
        final baseDir = await getApplicationDocumentsDirectory();
        publicDir = Directory(p.join(baseDir.path, folderPath));
      }

      if (!await publicDir.exists()) await publicDir.create(recursive: true);

      final publicPath = p.join(publicDir.path, defaultFileName);
      final publicFile = File(publicPath);

      final tempDir = await getTemporaryDirectory();
      final safeCachePath = p.join(tempDir.path, defaultFileName);
      final tempFile = File(safeCachePath);

      if (content is String) {
        await publicFile.writeAsString(content, flush: true);
        await tempFile.writeAsString(content, flush: true);
      } else if (content is List<int>) {
        await publicFile.writeAsBytes(content, flush: true);
        await tempFile.writeAsBytes(content, flush: true);
      }

      return SmartTrackerExportResult(
        publicPath: publicPath,
        safeCachePath: safeCachePath,
      );
    } catch (e) {
      throw Exception("Storage Permission Error: $e");
    }
  }

  // --- CSV EXPORT (NO BOM, NO SYMBOLS) ---
  Future<SmartTrackerExportResult> exportToCsv({
    required SmartTrackerTemplate template,
    required List<TrackerField> fields,
    required List<SmartTrackerRecord> records,
  }) async {
    List<List<dynamic>> rows = [];

    rows.add(['FINSTACK 360 SMART TRACKER REPORT']);
    rows.add(['Template:', template.name]);
    rows.add([
      'Generated:',
      DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
    ]);
    rows.add(['Total Records:', records.length.toString()]);
    rows.add([]);

    rows.add(fields.map((f) => f.name.toUpperCase()).toList());

    for (var record in records) {
      final Map<String, dynamic> dataMap = jsonDecode(record.dataJson);
      List<String> rowData = [];
      for (var field in fields) {
        rowData.add(formatValue(field, dataMap[field.id], forCsv: true));
      }
      rows.add(rowData);
    }

    // --- APPEND FOOTER AGGREGATES ---
    final footerRow = _generateFooterRow(fields, records, forCsv: true);
    if (footerRow.isNotEmpty) {
      rows.add(footerRow);
    }

    String csvString = rows
        .map((row) {
          return row
              .map((item) {
                String str = item?.toString() ?? '';
                if (str.contains(',') ||
                    str.contains('"') ||
                    str.contains('\n') ||
                    str.contains('\r')) {
                  str = '"${str.replaceAll('"', '""')}"';
                }
                return str;
              })
              .join(',');
        })
        .join('\r\n');

    String defaultName =
        "${template.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";

    return await _saveFile(defaultName, csvString, 'CSV');
  }

  // --- PDF EXPORT (WITH UNICODE FONT & WATERMARK) ---
  Future<SmartTrackerExportResult> exportToPdf({
    required SmartTrackerTemplate template,
    required List<TrackerField> fields,
    required List<SmartTrackerRecord> records,
  }) async {
    final pdf = pw.Document();

    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      regularFont = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoMedium();
    } catch (e) {
      debugPrint("Unicode font load error: $e");
    }

    pw.MemoryImage? watermarkImage;
    try {
      final ByteData image = await rootBundle.load('assets/icon/fs360.png');
      watermarkImage = pw.MemoryImage(image.buffer.asUint8List());
    } catch (e) {
      debugPrint("Watermark image not found: $e");
    }

    final pageTheme = pw.PageTheme(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(36),
      buildBackground: (pw.Context context) {
        if (watermarkImage == null) return pw.SizedBox();
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Opacity(
              opacity: 0.05,
              child: pw.Image(watermarkImage, width: 400),
            ),
          ),
        );
      },
    );

    final tableHeaders = fields.map((f) => f.name.toUpperCase()).toList();
    final tableData = records.map((record) {
      final Map<String, dynamic> dataMap = jsonDecode(record.dataJson);
      return fields
          .map((f) => formatValue(f, dataMap[f.id], forCsv: false))
          .toList();
    }).toList();

    // --- APPEND FOOTER AGGREGATES ---
    final footerRow = _generateFooterRow(fields, records, forCsv: false);
    if (footerRow.isNotEmpty) {
      tableData.add(footerRow);
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
            ),
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      template.name.toUpperCase(),
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColor.fromInt(0xFF1E1E1E),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "FinStack 360 Smart Tracker Ledger",
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Total Records: ${records.length}",
                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
              style: pw.TextStyle(
                font: regularFont,
                color: PdfColors.grey500,
                fontSize: 10,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: tableHeaders,
              data: tableData,
              border: null,
              headerStyle: pw.TextStyle(
                font: boldFont,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E1E1E),
              ),
              cellStyle: pw.TextStyle(font: regularFont, fontSize: 8),
              cellHeight: 24,
              cellAlignments: {
                for (var i = 0; i < fields.length; i++)
                  i: pw.Alignment.centerLeft,
              },
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1F5F9),
              ),
            ),
          ];
        },
      ),
    );

    String defaultName =
        "${template.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";
    return await _saveFile(defaultName, await pdf.save(), 'PDF');
  }
}

// ============================================================================
// --- SMART TRACKER EXPORT UI ---
// ============================================================================
class SmartTrackerExportUI {
  static void show(
    BuildContext context, {
    required SmartTrackerTemplate template,
    required List<TrackerField> fields,
    required List<SmartTrackerRecord> records,
  }) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Export Tracker Ledger",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Generates a snapshot of your currently filtered records.",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildExportOption(
                    context,
                    icon: Icons.picture_as_pdf_rounded,
                    label: "Save PDF",
                    color: const Color(0xFFE71D36),
                    onTap: () async {
                      Navigator.pop(ctx);
                      _executeExport(context, true, template, fields, records);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExportOption(
                    context,
                    icon: Icons.table_chart_rounded,
                    label: "Save CSV",
                    color: const Color(0xFF2EC4B6),
                    onTap: () async {
                      Navigator.pop(ctx);
                      _executeExport(context, false, template, fields, records);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Future<void> _executeExport(
    BuildContext context,
    bool isPdf,
    SmartTrackerTemplate template,
    List<TrackerField> fields,
    List<SmartTrackerRecord> records,
  ) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      barrierDismissible: false,
      builder: (_) => const Material(
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FuturisticLoader(color: Colors.cyanAccent),
              SizedBox(height: 32),
              Text(
                "GENERATING REPORT...",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final service = SmartTrackerExportService();
      SmartTrackerExportResult result;

      if (isPdf) {
        result = await service.exportToPdf(
          template: template,
          fields: fields,
          records: records,
        );
      } else {
        result = await service.exportToCsv(
          template: template,
          fields: fields,
          records: records,
        );
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        _showExportSuccessSheet(
          context,
          result,
          isPdf ? const Color(0xFFE71D36) : const Color(0xFF2EC4B6),
          isPdf ? "PDF" : "CSV",
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    }
  }

  static Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static void _showExportSuccessSheet(
    BuildContext context,
    SmartTrackerExportResult result,
    Color themeColor,
    String format,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: themeColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "$format Export Successful",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "File Saved to:",
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.publicPath,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: themeColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(Icons.ios_share_rounded, color: themeColor),
                    label: Text(
                      "Share",
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Share.shareXFiles([
                        XFile(result.safeCachePath),
                      ], text: "FinStack 360 Smart Tracker $format Export");
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.file_open_rounded),
                    label: const Text(
                      "Open File",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final String mimeType = format == "PDF"
                          ? "application/pdf"
                          : "text/csv";
                      final openResult = await OpenFile.open(
                        result.safeCachePath,
                        type: mimeType,
                      );
                      if (openResult.type != ResultType.done &&
                          context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Cannot open directly. Please use the 'Share' button.",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Dismiss",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
