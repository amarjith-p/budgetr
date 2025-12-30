import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Core Imports ---
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_stream_builder.dart';
import '../../../core/widgets/aurora_scaffold.dart';
import '../../../core/widgets/glass_app_bar.dart'; // New Centralized AppBar
import '../../../core/widgets/loading_overlay.dart';

// --- Feature Imports ---
import '../models/credit_models.dart';
import '../services/credit_service.dart';
import '../widgets/add_credit_card_sheet.dart';
import '../widgets/add_credit_txn_sheet.dart';
import '../widgets/credit_card_tile.dart';
import 'card_detail_screen.dart';

class CreditTrackerScreen extends StatefulWidget {
  const CreditTrackerScreen({super.key});

  @override
  State<CreditTrackerScreen> createState() => _CreditTrackerScreenState();
}

class _CreditTrackerScreenState extends State<CreditTrackerScreen> {
  final CreditService _service = CreditService();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
  );

  bool _isLoading = false;
  late Stream<List<CreditCardModel>> _cardsStream;

  @override
  void initState() {
    super.initState();
    _cardsStream = _service.getCreditCards();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: AuroraScaffold(
        accentColor1: AppColors.royalBlue,
        accentColor2: AppColors.dangerRed,

        // --- Centralized Glass App Bar ---
        appBar: GlassAppBar(
          title: "Credit Portfolio",
          actions: [
            GlassIconButton(
              icon: Icons.add_card_rounded,
              color: AppColors.royalBlue.withOpacity(0.2),
              iconColor: Colors.white,
              hasBorder: true,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const AddCreditCardSheet(),
              ),
            ),
          ],
        ),

        body: AsyncStreamBuilder<List<CreditCardModel>>(
          stream: _cardsStream,
          emptyBuilder: (context) => _buildEmptyState(context),
          builder: (context, cards) {
            // Calculate totals
            final double totalDebt = cards
                .where((c) => c.currentBalance > 0)
                .fold(0.0, (sum, c) => sum + c.currentBalance);
            final double totalSurplus = cards
                .where((c) => c.currentBalance < 0)
                .fold(0.0, (sum, c) => sum + c.currentBalance);

            double displayAmount = 0;
            String label = "ALL SETTLED";
            Color valueColor = AppColors.textPrimary;
            Color glowColor = Colors.white.withOpacity(0.1);

            if (totalDebt > 0.01) {
              label = "TOTAL PAYABLE";
              displayAmount = -totalDebt; // Negative for Debt
              valueColor = AppColors
                  .negativeRed; // Ensure this is in AppColors or use Color(0xFFFF4D6D)
              glowColor = valueColor.withOpacity(0.2);
            } else if (totalSurplus.abs() > 0.01) {
              label = "TOTAL SURPLUS";
              displayAmount = -totalSurplus; // Positive for Surplus
              valueColor = AppColors.successGreen;
              glowColor = valueColor.withOpacity(0.2);
            }

            return Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 10), // Spacing from AppBar
                    // Glass Dashboard Summary
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildTotalHeader(
                        label,
                        displayAmount,
                        valueColor,
                        glowColor,
                        _currency,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // List of Cards
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: cards.length,
                        itemBuilder: (context, index) => CreditCardTile(
                          card: cards[index],
                          currency: _currency,
                          accentColor: AppColors.royalBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreditCardDetailScreen(card: cards[index]),
                            ),
                          ),
                          onMoreTap: () => _showCardDetails(
                            context,
                            cards[index],
                            _currency,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating Glass Action Button
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => const AddCreditTransactionSheet(),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.glassBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.royalBlue.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add_rounded, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  "Add Transaction",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Header moved here but styled with AppColors
  Widget _buildTotalHeader(
    String label,
    double amount,
    Color textColor,
    Color glowColor,
    NumberFormat currency,
  ) {
    String displayString = label == "ALL SETTLED"
        ? "All Settled"
        : (amount > 0
              ? "+ ${currency.format(amount)}"
              : currency.format(amount));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayString,
            style: TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              shadows: [Shadow(color: glowColor, blurRadius: 20)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.credit_card_off_rounded,
          size: 60,
          color: AppColors.textSecondary.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text("No Cards Found", style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );

  void _showCardDetails(
    BuildContext context,
    CreditCardModel card,
    NumberFormat currency,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          // Let Theme handle shape and background
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: AppColors.royalBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Card Details",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow("Card Name", card.name),
                const Divider(color: Colors.white10, height: 32),
                _buildDetailRow(
                  "Credit Limit",
                  currency.format(card.creditLimit),
                ),
                const Divider(color: Colors.white10, height: 32),
                _buildDetailRow(
                  "Statement Date",
                  "${_getOrdinal(card.billDate)} of month",
                ),
                const Divider(color: Colors.white10, height: 32),
                _buildDetailRow(
                  "Payment Due Date",
                  "${_getOrdinal(card.dueDate)} of month",
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleDelete(context, card);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text("Delete"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.dangerRed,
                          backgroundColor: AppColors.dangerRed.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (c) =>
                                AddCreditCardSheet(cardToEdit: card),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("Edit"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, CreditCardModel card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // Theme handles background
        title: const Text("Delete Account?"),
        content: Text(
          "Are you sure you want to delete '${card.name}'? This will permanently remove the account and all its associated transactions.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _service.deleteCreditCard(card.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account deleted successfully"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: Text(
              "Delete",
              style: TextStyle(
                color: AppColors.dangerRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ],
  );

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}
