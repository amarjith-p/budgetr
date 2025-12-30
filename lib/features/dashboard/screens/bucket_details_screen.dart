import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/design/budgetr_colors.dart';
import '../../../core/design/budgetr_styles.dart';
import '../../../core/widgets/modern_loader.dart';
import '../../../core/constants/icon_constants.dart'; // Import IconConstants
import '../../../core/services/category_service.dart'; // Import CategoryService
import '../../../core/models/transaction_category_model.dart'; // Import CategoryModel
import '../../../core/models/financial_record_model.dart'; // Import FinancialRecord
import '../../credit_tracker/models/credit_models.dart';
import '../../credit_tracker/services/credit_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/bucket_trends_chart.dart';

class BucketDetailsScreen extends StatefulWidget {
  final String bucketName;
  final int year;
  final int month;

  const BucketDetailsScreen({
    super.key,
    required this.bucketName,
    required this.year,
    required this.month,
  });

  @override
  State<BucketDetailsScreen> createState() => _BucketDetailsScreenState();
}

class _BucketDetailsScreenState extends State<BucketDetailsScreen> {
  final DashboardService _dashboardService = DashboardService();
  final CreditService _creditService = CreditService();
  final CategoryService _categoryService = CategoryService();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
  );

  Map<String, String> _cardNames = {};
  Map<String, IconData> _categoryIcons = {}; // Map to store resolved icons
  double _budgetLimit = 0.0;
  bool _isLoadingLimit = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Fetch all required data in parallel
    final results = await Future.wait([
      _creditService.getCreditCards().first, // 0: Cards
      _categoryService.getCategories().first, // 1: Categories
      _dashboardService.getRecordForMonth(
        widget.year,
        widget.month,
      ), // 2: Budget Record
    ]);

    if (mounted) {
      final cards = results[0] as List<CreditCardModel>;
      final categories = results[1] as List<TransactionCategoryModel>;
      final record = results[2] as FinancialRecord?;

      double limit = 0.0;
      if (record != null) {
        limit = record.allocations[widget.bucketName] ?? 0.0;
      }

      setState(() {
        // 1. Map Card IDs to Names
        _cardNames = {for (var c in cards) c.id: "${c.bankName} - ${c.name}"};

        // 2. Map Category Names to Icons
        _categoryIcons = {
          for (var c in categories)
            if (c.iconCode != null)
              c.name: IconConstants.getIconByCode(c.iconCode!),
        };

        _budgetLimit = limit;
        _isLoadingLimit = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(widget.year, widget.month));

    return Scaffold(
      backgroundColor: BudgetrColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.bucketName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              dateString,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingLimit
          ? const Center(child: ModernLoader())
          : StreamBuilder<List<CreditTransactionModel>>(
              stream: _dashboardService.getBucketTransactions(
                widget.year,
                widget.month,
                widget.bucketName,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: ModernLoader());
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No transactions found",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // --- CHART SECTION ---
                    BucketTrendsChart(
                      transactions: transactions,
                      year: widget.year,
                      month: widget.month,
                      budgetLimit: _budgetLimit,
                    ),

                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        "Transactions",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // --- TRANSACTIONS LIST ---
                    ...transactions.map((txn) {
                      final cardName = _cardNames[txn.cardId] ?? "Unknown Card";
                      // Resolve Icon: Use map or fallback to category default
                      final iconData =
                          _categoryIcons[txn.category] ??
                          Icons.category_outlined;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: BudgetrColors.cardSurface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Dynamic Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                iconData, // Uses the actual category icon
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    txn.category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat(
                                          'dd MMM',
                                        ).format(txn.date.toDate()),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Colors.white24,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          cardName,
                                          style: const TextStyle(
                                            color: BudgetrColors.accent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (txn.notes.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        txn.notes,
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              _currencyFormat.format(txn.amount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}
