// lib/features/trips/services/trip_export_service.dart
import 'dart:io';
import 'package:budgetr/core/components/currency_text.dart';
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
import '../../../core/components/futuristic_loader.dart';
import '../../transactions/services/transaction_service.dart';

class TripExportResult {
  final String publicPath;
  final String safeCachePath;
  TripExportResult({required this.publicPath, required this.safeCachePath});
}

class TripExportService {
  Future<TripExportResult> _saveFile(
    String defaultFileName,
    dynamic content,
    String formatFolder,
  ) async {
    try {
      final folderDate = DateFormat('MMM yyyy').format(DateTime.now());
      final folderPath = 'FinStack 360/Trips/$folderDate/$formatFolder';

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

      return TripExportResult(
        publicPath: publicPath,
        safeCachePath: safeCachePath,
      );
    } catch (e) {
      throw Exception("Storage Permission Error: $e");
    }
  }

  // --- CSV EXPORT (NO BOM, NO SYMBOLS) ---
  Future<TripExportResult> exportToCsv({
    required Trip trip,
    required double netSpend,
    required double totalExpense,
    required double totalIncome,
    required double dailyAvg,
    required List<TransactionWithDetails> transactions,
  }) async {
    List<List<dynamic>> rows = [];

    // Summary Header
    rows.add(['FINSTACK 360 TRIP REPORT']);
    rows.add(['Trip Name:', trip.name]);
    rows.add(['Status:', trip.status]);
    rows.add([
      'Budget:',
      trip.budget != null ? trip.budget.toString() : 'Not Set',
    ]);
    rows.add(['Notes:', trip.notes?.replaceAll('\n', ' ') ?? 'None']);
    rows.add([
      'Generated:',
      DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
    ]);
    rows.add([]);

    // Aggregates
    rows.add(['Net Spend:', netSpend.toStringAsFixed(2)]);
    rows.add(['Total Expense:', totalExpense.toStringAsFixed(2)]);
    rows.add(['Total Income:', totalIncome.toStringAsFixed(2)]);
    rows.add(['Daily Average:', dailyAvg.toStringAsFixed(2)]);
    rows.add([]);

    // Transactions Table
    rows.add(['DATE', 'ACCOUNT', 'CATEGORY', 'TYPE', 'AMOUNT']);

    for (var txData in transactions) {
      final tx = txData.transaction;
      final categoryName =
          tx.categoryName ?? txData.category?.name ?? 'Uncategorized';

      rows.add([
        DateFormat('dd MMM yyyy HH:mm').format(tx.date),
        txData.account.name,
        categoryName,
        tx.type,
        tx.amount.toStringAsFixed(2),
      ]);
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
        "${trip.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";

    return await _saveFile(defaultName, csvString, 'CSV');
  }

  // --- PDF EXPORT (WITH UNICODE FONT & WATERMARK) ---
  Future<TripExportResult> exportToPdf({
    required Trip trip,
    required double netSpend,
    required double totalExpense,
    required double totalIncome,
    required double dailyAvg,
    required List<TransactionWithDetails> transactions,
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
      final ByteData image = await rootBundle.load(
        'assets/icon/fs360_transparent.png',
      );
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

    final tableHeaders = ['DATE', 'ACCOUNT', 'CATEGORY', 'TYPE', 'AMOUNT'];
    final tableData = transactions.map((txData) {
      final tx = txData.transaction;
      final categoryName =
          tx.categoryName ?? txData.category?.name ?? 'Uncategorized';
      final sign = tx.type == 'Expense'
          ? '-'
          : (tx.type == 'Income' ? '+' : '');

      return [
        DateFormat('dd MMM yyyy, HH:mm').format(tx.date),
        txData.account.name,
        categoryName,
        tx.type,
        '$sign₹ ${CurrencyFormatter.format(tx.amount)}',
      ];
    }).toList();

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
                      trip.name.toUpperCase(),
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColor.fromInt(0xFF1E1E1E),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "FinStack 360 Trip Expense Report",
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
                      "Status: ${trip.status}",
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 12,
                        color: trip.status == 'ACTIVE'
                            ? PdfColors.green
                            : PdfColors.grey600,
                      ),
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
            // Summary Block
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 24),
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    'NET SPEND',
                    '₹ ${CurrencyFormatter.format(netSpend.abs())}',
                    boldFont,
                    regularFont,
                  ),
                  if (trip.budget != null)
                    _buildSummaryItem(
                      'BUDGET',
                      '₹ ${CurrencyFormatter.format(trip.budget!)}',
                      boldFont,
                      regularFont,
                    ),
                  _buildSummaryItem(
                    'TOTAL EXPENSE',
                    '₹ ${CurrencyFormatter.format(totalExpense)}',
                    boldFont,
                    regularFont,
                  ),
                  _buildSummaryItem(
                    'TOTAL INCOME',
                    '₹ ${CurrencyFormatter.format(totalIncome)}',
                    boldFont,
                    regularFont,
                  ),
                  _buildSummaryItem(
                    'DAILY AVG',
                    '₹ ${CurrencyFormatter.format(dailyAvg.abs())}',
                    boldFont,
                    regularFont,
                  ),
                ],
              ),
            ),
            if (trip.notes != null && trip.notes!.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 24),
                child: pw.Text(
                  'Notes: ${trip.notes}',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
            // Data Table
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
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
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
        "${trip.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";
    return await _saveFile(defaultName, await pdf.save(), 'PDF');
  }

  pw.Widget _buildSummaryItem(
    String label,
    String value,
    pw.Font? boldFont,
    pw.Font? regularFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
            color: PdfColor.fromInt(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// --- TRIP EXPORT UI ---
// ============================================================================
class TripExportUI {
  static void show(
    BuildContext context, {
    required Trip trip,
    required double netSpend,
    required double totalExpense,
    required double totalIncome,
    required double dailyAvg,
    required List<TransactionWithDetails> transactions,
  }) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Export Trip Report",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Generates a complete summary of your trip and all its transactions.",
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
                      _executeExport(
                        context,
                        true,
                        trip,
                        netSpend,
                        totalExpense,
                        totalIncome,
                        dailyAvg,
                        transactions,
                      );
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
                      _executeExport(
                        context,
                        false,
                        trip,
                        netSpend,
                        totalExpense,
                        totalIncome,
                        dailyAvg,
                        transactions,
                      );
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
    Trip trip,
    double netSpend,
    double totalExpense,
    double totalIncome,
    double dailyAvg,
    List<TransactionWithDetails> transactions,
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
      final service = TripExportService();
      TripExportResult result;

      if (isPdf) {
        result = await service.exportToPdf(
          trip: trip,
          netSpend: netSpend,
          totalExpense: totalExpense,
          totalIncome: totalIncome,
          dailyAvg: dailyAvg,
          transactions: transactions,
        );
      } else {
        result = await service.exportToCsv(
          trip: trip,
          netSpend: netSpend,
          totalExpense: totalExpense,
          totalIncome: totalIncome,
          dailyAvg: dailyAvg,
          transactions: transactions,
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
          borderRadius: BorderRadius.circular(8),
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
    TripExportResult result,
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(8),
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
                      ], text: "FinStack 360 Trip $format Export");
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
                        borderRadius: BorderRadius.circular(8),
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
