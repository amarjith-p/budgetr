// features/insights/services/insight_export_service.dart
import 'dart:io';
import 'package:budgetr/core/database/app_database.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;

import '../../transactions/services/transaction_service.dart';
import '../models/insight_summary_model.dart';
import '../providers/insight_filter_provider.dart';

class InsightExportResult {
  final String publicPath;
  final String safeCachePath;
  InsightExportResult({required this.publicPath, required this.safeCachePath});
}

class InsightExportService {
  // --- PRECISE DATE RANGE RESOLVER ---
  ({DateTime start, DateTime end}) _getDateRange(InsightFilterState filter) {
    final now = DateTime.now();
    DateTime start = DateTime(2000);
    DateTime end = DateTime(2100);

    switch (filter.timeFrame) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Week':
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        end = start.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'Last Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'Last Year':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      case 'Custom Range':
        if (filter.customRange != null) {
          start = filter.customRange!.start;
          end = filter.customRange!.end.add(
            const Duration(hours: 23, minutes: 59, seconds: 59),
          );
        }
        break;
      case 'All Time':
      default:
        break;
    }
    return (start: start, end: end);
  }

  List<TransactionWithDetails> _getFilteredTransactions(
    InsightFilterState filter,
    List<TransactionWithDetails> allTransactions,
  ) {
    final range = _getDateRange(filter);
    List<TransactionWithDetails> filtered = [];

    for (var t in allTransactions) {
      final tx = t.transaction;
      final accType = t.account.type;

      if (filter.accountId != null) {
        if (filter.accountId == 'ASSETS') {
          if (accType == 'Credit Cards' || accType == 'Loan') continue;
        } else if (filter.accountId == 'CREDIT') {
          if (accType != 'Credit Cards' && accType != 'Loan') continue;
        } else if (tx.accountId != filter.accountId) {
          continue;
        }
      }

      if (tx.date.isBefore(range.start) || tx.date.isAfter(range.end)) {
        continue;
      }
      filtered.add(t);
    }

    filtered.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
    return filtered;
  }

  Future<InsightExportResult> _saveFile(
    String defaultFileName,
    dynamic content,
    String formatFolder,
  ) async {
    try {
      final folderDate = DateFormat('MMM yyyy').format(DateTime.now());
      final folderPath = 'FinStack 360/Insights/$folderDate/$formatFolder';

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

      return InsightExportResult(
        publicPath: publicPath,
        safeCachePath: safeCachePath,
      );
    } catch (e) {
      throw Exception("Storage Permission Error: $e");
    }
  }

  // --- CSV EXPORT (Rigid Grid Formatting) ---
  Future<InsightExportResult> exportToCsv({
    required InsightFilterState filter,
    required InsightSummaryModel summary,
    required String accountName,
    required List<TransactionWithDetails> allTransactions,
    required List<BudgetBucket> activeBuckets,
  }) async {
    final transactions = _getFilteredTransactions(filter, allTransactions);
    final range = _getDateRange(filter);
    final dateString =
        "${DateFormat('dd MMM yyyy').format(range.start)} to ${DateFormat('dd MMM yyyy').format(range.end)}";

    List<List<dynamic>> rows = [];

    // Header
    rows.add(['INSIGHTS REPORT']);
    rows.add(['Account:', accountName]);
    rows.add(['Period:', dateString]);
    rows.add([]);

    // Summary
    rows.add(['--- OVERVIEW ---']);
    rows.add(['METRIC', 'VALUE']); // Added explicit header
    rows.add(['Total Income', summary.totalIncome.toStringAsFixed(2)]);
    rows.add(['Total Expense', summary.totalExpense.toStringAsFixed(2)]);
    rows.add(['Net Savings', summary.netSavings.toStringAsFixed(2)]);
    rows.add(['Savings Rate', '${summary.savingsRate.toStringAsFixed(1)}%']);
    rows.add([]);

    // Buckets Math
    Map<String, double> allocated = {};
    Map<String, double> spent = {};
    for (var b in activeBuckets) {
      allocated[b.name] = (b.percentage / 100) * summary.totalIncome;
      spent[b.name] = 0.0;
    }

    final incomes = transactions
        .where((t) => t.transaction.type == 'Income')
        .toList();
    final expenses = transactions
        .where((t) => t.transaction.type == 'Expense')
        .toList();

    for (var t in expenses) {
      String bName =
          t.transaction.bucketName ?? t.bucket?.name ?? 'Out of Bucket';
      spent[bName] = (spent[bName] ?? 0.0) + t.transaction.amount;
    }

    // Bucket Table
    rows.add(['--- BUDGET BUCKETS SUMMARY ---']);
    rows.add(['BUCKET NAME', 'ALLOCATED', 'SPENT', 'REMAINING']);

    final allBucketNames = {...allocated.keys, ...spent.keys};
    for (var bName in allBucketNames) {
      double a = allocated[bName] ?? 0.0;
      double s = spent[bName] ?? 0.0;
      double r = a - s;
      rows.add([
        bName,
        a.toStringAsFixed(2),
        s.toStringAsFixed(2),
        r.toStringAsFixed(2),
      ]);
    }
    rows.add([]);

    // Calculate Category Math
    Map<String, double> expByCat = {};
    Map<String, double> incByCat = {};

    for (var t in expenses) {
      String cat =
          t.transaction.categoryName ?? t.category?.name ?? 'Uncategorized';
      expByCat[cat] = (expByCat[cat] ?? 0) + t.transaction.amount;
    }
    for (var t in incomes) {
      String cat =
          t.transaction.categoryName ?? t.category?.name ?? 'Uncategorized';
      if (cat.toLowerCase() != 'repayment') {
        incByCat[cat] = (incByCat[cat] ?? 0) + t.transaction.amount;
      }
    }

    // Expense Category Table
    rows.add(['--- EXPENSE BY CATEGORY ---']);
    rows.add(['CATEGORY', 'SPENT AMOUNT']); // Added explicit header
    expByCat.forEach((key, val) => rows.add([key, val.toStringAsFixed(2)]));
    rows.add([]);

    // Income Category Table
    rows.add(['--- INCOME BY CATEGORY ---']);
    rows.add(['CATEGORY', 'RECEIVED AMOUNT']); // Added explicit header
    incByCat.forEach((key, val) => rows.add([key, val.toStringAsFixed(2)]));
    rows.add([]);

    // Income Ledger (Extended to 7 Columns)
    rows.add(['--- INCOME TRANSACTIONS ---']);
    rows.add([
      'DATE',
      'ACCOUNT',
      'BUCKET',
      'CATEGORY',
      'SUBCATEGORY',
      'AMOUNT',
      'NOTES',
    ]);
    for (var t in incomes) {
      final tx = t.transaction;
      rows.add([
        DateFormat('dd MMM yyyy').format(tx.date),
        t.account.name,
        tx.bucketName ?? t.bucket?.name ?? '-',
        tx.categoryName ?? t.category?.name ?? 'Uncategorized',
        tx.subCategory ?? '-',
        tx.amount.toStringAsFixed(2),
        tx.notes ?? '',
      ]);
    }
    rows.add([]);

    // Expense Ledger (Extended to 7 Columns)
    rows.add(['--- EXPENSE TRANSACTIONS ---']);
    rows.add([
      'DATE',
      'ACCOUNT',
      'BUCKET',
      'CATEGORY',
      'SUBCATEGORY',
      'AMOUNT',
      'NOTES',
    ]);
    for (var t in expenses) {
      final tx = t.transaction;
      rows.add([
        DateFormat('dd MMM yyyy').format(tx.date),
        t.account.name,
        tx.bucketName ?? t.bucket?.name ?? 'Out of Bucket',
        tx.categoryName ?? t.category?.name ?? 'Uncategorized',
        tx.subCategory ?? '-',
        tx.amount.toStringAsFixed(2),
        tx.notes ?? '',
      ]);
    }

    // --- NATIVE CSV ENCODER (WITH STRICT PADDING & EXCEL LINE ENDINGS) ---
    int maxCols = 7; // The widest table in this file has 7 columns (Ledger)

    String csvString = rows
        .map((row) {
          // Create a mutable copy and pad it with empty strings until it hits 7 columns
          List<dynamic> paddedRow = List.from(row);
          while (paddedRow.length < maxCols) {
            paddedRow.add('');
          }

          return paddedRow
              .map((item) {
                String str = item?.toString() ?? '';
                // Wrap in quotes and escape internal quotes if it contains commas, newlines, or carriage returns
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
        .join('\r\n'); // Strictly use \r\n to prevent Excel from shifting rows

    String defaultName =
        "Insights_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";

    return await _saveFile(defaultName, csvString, 'CSV');
  }

  // --- PDF EXPORT (Pro Structured Tables & Charts) ---
  Future<InsightExportResult> exportToPdf({
    required InsightFilterState filter,
    required InsightSummaryModel summary,
    required String accountName,
    required List<TransactionWithDetails> allTransactions,
    required List<BudgetBucket> activeBuckets,
  }) async {
    final transactions = _getFilteredTransactions(filter, allTransactions);
    final range = _getDateRange(filter);
    final dateString =
        "${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}";
    final pdf = pw.Document();

    // Separate Data Streams
    final incomes = transactions
        .where((t) => t.transaction.type == 'Income')
        .toList();
    final expenses = transactions
        .where((t) => t.transaction.type == 'Expense')
        .toList();

    // Math for Charts & Buckets
    Map<String, double> expByCat = {};
    Map<String, double> incByCat = {};
    Map<String, double> allocated = {};
    Map<String, double> spent = {};

    for (var b in activeBuckets) {
      allocated[b.name] = (b.percentage / 100) * summary.totalIncome;
      spent[b.name] = 0.0;
    }

    for (var t in expenses) {
      String cat =
          t.transaction.categoryName ?? t.category?.name ?? 'Uncategorized';
      String bucket =
          t.transaction.bucketName ?? t.bucket?.name ?? 'Out of Bucket';
      expByCat[cat] = (expByCat[cat] ?? 0) + t.transaction.amount;
      spent[bucket] = (spent[bucket] ?? 0) + t.transaction.amount;
    }

    for (var t in incomes) {
      String cat =
          t.transaction.categoryName ?? t.category?.name ?? 'Uncategorized';
      if (cat.toLowerCase() != 'repayment') {
        incByCat[cat] = (incByCat[cat] ?? 0) + t.transaction.amount;
      }
    }

    // Common Table Header
    final tableHeaders = [
      'DATE',
      'ACCOUNT',
      'BUCKET',
      'CATEGORY',
      'SUBCATEGORY',
      'AMOUNT',
    ];
    final tableAlignments = {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.centerLeft,
      3: pw.Alignment.centerLeft,
      4: pw.Alignment.centerLeft,
      5: pw.Alignment.centerRight,
    };

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
    );

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
                      "INSIGHTS REPORT",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF1E1E1E),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Account: $accountName",
                      style: const pw.TextStyle(
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
                      dateString,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
                      style: const pw.TextStyle(
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
              style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // --- SUMMARY CARDS ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfSummaryBox(
                  "TOTAL INCOME",
                  summary.totalIncome,
                  PdfColors.green700,
                ),
                _buildPdfSummaryBox(
                  "TOTAL EXPENSE",
                  summary.totalExpense,
                  PdfColors.red700,
                ),
                _buildPdfSummaryBox(
                  "NET SAVINGS",
                  summary.netSavings,
                  summary.netSavings >= 0
                      ? PdfColors.green700
                      : PdfColors.red700,
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // --- PRO CHARTS WITH EXTERNAL LEGENDS ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildPdfProChart("EXPENSE BREAKDOWN", expByCat),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: _buildPdfProChart("INCOME SOURCES", incByCat),
                ),
              ],
            ),
            pw.SizedBox(height: 36),

            // --- BUDGET BUCKETS SUMMARY TABLE ---
            pw.Text(
              "BUDGET BUCKETS SUMMARY",
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['BUCKET NAME', 'ALLOCATED', 'SPENT', 'REMAINING'],
              data: {...allocated.keys, ...spent.keys}.map((bName) {
                double a = allocated[bName] ?? 0.0;
                double s = spent[bName] ?? 0.0;
                double r = a - s;
                return [
                  bName,
                  a.toStringAsFixed(2),
                  s.toStringAsFixed(2),
                  r.toStringAsFixed(2),
                ];
              }).toList(),
              border: null,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E1E1E),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellHeight: 24,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1F5F9),
              ),
            ),
            pw.SizedBox(height: 30),

            // --- INCOME TRANSACTIONS ---
            if (incomes.isNotEmpty) ...[
              pw.Text(
                "INCOME TRANSACTIONS",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: tableHeaders,
                data: incomes
                    .map(
                      (t) => [
                        DateFormat('dd MMM').format(t.transaction.date),
                        t.account.name,
                        t.transaction.bucketName ?? t.bucket?.name ?? '-',
                        t.transaction.categoryName ??
                            t.category?.name ??
                            'Uncategorized',
                        t.transaction.subCategory ?? '-',
                        t.transaction.amount.toStringAsFixed(2),
                      ],
                    )
                    .toList(),
                border: null,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.green800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellHeight: 22,
                cellAlignments: tableAlignments,
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1F5F9),
                ),
              ),
              pw.SizedBox(height: 30),
            ],

            // --- EXPENSE TRANSACTIONS ---
            if (expenses.isNotEmpty) ...[
              pw.Text(
                "EXPENSE TRANSACTIONS",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: tableHeaders,
                data: expenses
                    .map(
                      (t) => [
                        DateFormat('dd MMM').format(t.transaction.date),
                        t.account.name,
                        t.transaction.bucketName ??
                            t.bucket?.name ??
                            'Out of Bucket',
                        t.transaction.categoryName ??
                            t.category?.name ??
                            'Uncategorized',
                        t.transaction.subCategory ?? '-',
                        t.transaction.amount.toStringAsFixed(2),
                      ],
                    )
                    .toList(),
                border: null,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.red800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellHeight: 22,
                cellAlignments: tableAlignments,
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1F5F9),
                ),
              ),
            ],
          ];
        },
      ),
    );

    String defaultName =
        "Insights_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";

    return await _saveFile(defaultName, await pdf.save(), 'PDF');
  }

  // --- PDF WIDGET HELPERS ---
  pw.Widget _buildPdfSummaryBox(String title, double amount, PdfColor color) {
    return pw.Container(
      width: 145,
      padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8F9FA),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            amount.toStringAsFixed(2),
            style: pw.TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Chart with External Legends ---
  pw.Widget _buildPdfProChart(String title, Map<String, double> data) {
    if (data.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            "No Data",
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
          ),
        ],
      );
    }

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topItems = sorted.take(8).toList(); // Top 8 to keep it clean

    final colors = [
      PdfColor.fromHex('#00B4D8'),
      PdfColor.fromHex('#9D4EDD'),
      PdfColor.fromHex('#FF4D6D'),
      PdfColor.fromHex('#FF9F1C'),
      PdfColor.fromHex('#00E676'),
      PdfColor.fromHex('#F15BB5'),
      PdfColor.fromHex('#3F37C9'),
      PdfColor.fromHex('#48CAE4'),
    ];

    List<pw.Dataset> datasets = [];
    List<pw.Widget> legends = [];

    for (int i = 0; i < topItems.length; i++) {
      final color = colors[i % colors.length];

      datasets.add(
        pw.PieDataSet(
          value: topItems[i].value,
          color: color,
          drawBorder: false,
          // Notice: No legend parameter here, so the chart stays clean!
        ),
      );

      legends.add(
        pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 8, height: 8, color: color),
            pw.SizedBox(width: 6),
            pw.Text(
              '${topItems[i].key} (${topItems[i].value.toStringAsFixed(0)})',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              height: 90,
              width: 90,
              child: pw.Chart(grid: pw.PieGrid(), datasets: datasets),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Wrap(spacing: 8, runSpacing: 6, children: legends),
            ),
          ],
        ),
      ],
    );
  }
}
