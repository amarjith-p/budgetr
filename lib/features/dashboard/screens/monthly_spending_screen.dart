import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/design/budgetr_colors.dart';
import '../../../core/design/budgetr_styles.dart';
import '../../../core/widgets/modern_loader.dart';
import '../../../core/constants/icon_constants.dart';
import '../../../core/services/category_service.dart';
import '../../../core/models/transaction_category_model.dart';
import '../../../core/models/financial_record_model.dart';
import '../../credit_tracker/models/credit_models.dart';
import '../../credit_tracker/services/credit_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/bucket_trends_chart.dart';

class MonthlySpendingScreen extends StatefulWidget {
  final FinancialRecord record;

  const MonthlySpendingScreen({super.key, required this.record});

  @override
  State<MonthlySpendingScreen> createState() => _MonthlySpendingScreenState();
}

class _MonthlySpendingScreenState extends State<MonthlySpendingScreen> {
  final DashboardService _dashboardService = DashboardService();
  final CreditService _creditService = CreditService();
  final CategoryService _categoryService = CategoryService();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
  );

  Map<String, String> _cardNames = {};
  Map<String, IconData> _categoryIcons = {};
  bool _isLoadingInfo = true;

  // Filter State
  bool _hideOutOfBucket = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final results = await Future.wait([
      _creditService.getCreditCards().first,
      _categoryService.getCategories().first,
    ]);

    if (mounted) {
      final cards = results[0] as List<CreditCardModel>;
      final categories = results[1] as List<TransactionCategoryModel>;

      setState(() {
        _cardNames = {for (var c in cards) c.id: "${c.bankName} - ${c.name}"};
        _categoryIcons = {
          for (var c in categories)
            if (c.iconCode != null)
              c.name: IconConstants.getIconByCode(c.iconCode!),
        };
        _isLoadingInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(widget.record.year, widget.record.month));

    final double totalBudget = widget.record.effectiveIncome;

    return Scaffold(
      backgroundColor: BudgetrColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Monthly Overview",
              style: TextStyle(
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
      body: _isLoadingInfo
          ? const Center(child: ModernLoader())
          : StreamBuilder<List<CreditTransactionModel>>(
              stream: _dashboardService.getMonthlyTransactions(
                widget.record.year,
                widget.record.month,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: ModernLoader());
                }

                var transactions = snapshot.data ?? [];

                // --- APPLY FILTER ---
                if (_hideOutOfBucket) {
                  transactions = transactions
                      .where((t) => t.bucket != 'Out of Bucket')
                      .toList();
                }

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
                          _hideOutOfBucket
                              ? "No planned transactions found"
                              : "No transactions found",
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
                    // --- GLOBAL CHART ---
                    BucketTrendsChart(
                      transactions: transactions,
                      year: widget.record.year,
                      month: widget.record.month,
                      budgetLimit: totalBudget,
                    ),

                    const SizedBox(height: 8),

                    // --- CUSTOM FILTER TOGGLE ---
                    GestureDetector(
                      onTap: () =>
                          setState(() => _hideOutOfBucket = !_hideOutOfBucket),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _hideOutOfBucket
                              ? BudgetrColors.accent.withOpacity(0.15)
                              : BudgetrColors.cardSurface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _hideOutOfBucket
                                ? BudgetrColors.accent.withOpacity(0.5)
                                : Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                          boxShadow: _hideOutOfBucket
                              ? [
                                  BoxShadow(
                                    color: BudgetrColors.accent.withOpacity(
                                      0.1,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _hideOutOfBucket
                                    ? BudgetrColors.accent
                                    : Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.filter_alt_off_outlined,
                                size: 18,
                                color: _hideOutOfBucket
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hide 'Out of Bucket'",
                                    style: TextStyle(
                                      color: _hideOutOfBucket
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _hideOutOfBucket
                                        ? "Showing planned expenses only"
                                        : "Showing all expenses",
                                    style: TextStyle(
                                      color: _hideOutOfBucket
                                          ? Colors.white70
                                          : Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Custom Animated Switch
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 48,
                              height: 28,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: _hideOutOfBucket
                                    ? BudgetrColors.accent
                                    : Colors.black26,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOutBack,
                                alignment: _hideOutOfBucket
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _hideOutOfBucket
                                          ? Icons.close
                                          : Icons.check,
                                      size: 14,
                                      color: _hideOutOfBucket
                                          ? BudgetrColors.accent
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

                    // --- LIST ---
                    ...transactions.map((txn) {
                      final cardName = _cardNames[txn.cardId] ?? "Unknown Card";
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                iconData,
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
                                  // Show Bucket Tag for Context
                                  if (txn.bucket.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: txn.bucket == 'Out of Bucket'
                                              ? Colors.redAccent.withOpacity(
                                                  0.2,
                                                )
                                              : Colors.white10,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          txn.bucket,
                                          style: TextStyle(
                                            color: txn.bucket == 'Out of Bucket'
                                                ? Colors.redAccent
                                                : Colors.white54,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
