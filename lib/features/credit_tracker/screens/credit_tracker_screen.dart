import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/async_stream_builder.dart';
import '../../../core/widgets/loading_overlay.dart';
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
  final Color _accentColor = const Color(0xFF3A86FF);

  // State to manage loading overlay
  bool _isLoading = false;

  late Stream<List<CreditCardModel>> _cardsStream;

  @override
  void initState() {
    super.initState();
    _cardsStream = _service.getCreditCards();
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme background instead of hardcoded color
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: const Color(
          0xff0D1B2A,
        ), // Keep as is or use Theme.of(context).scaffoldBackgroundColor
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "Credit Tracker",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const AddCreditCardSheet(),
              ),
              icon: const Icon(Icons.add_card),
              tooltip: "Add New Card",
            ),
            const SizedBox(width: 8),
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
            String label = "STATUS";
            Color valueColor = const Color(0xFF00B4D8);

            if (totalDebt > 0.01) {
              label = "TOTAL PAYABLE";
              displayAmount = -totalDebt;
              valueColor = Colors.white;
            } else if (totalSurplus.abs() > 0.01) {
              label = "TOTAL SURPLUS";
              displayAmount = -totalSurplus;
              valueColor = const Color(0xFF4CC9F0);
            }

            return Stack(
              children: [
                Column(
                  children: [
                    _buildTotalHeader(
                      label,
                      displayAmount,
                      valueColor,
                      _currency,
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: cards.length,
                        itemBuilder: (context, index) => CreditCardTile(
                          card: cards[index],
                          currency: _currency,
                          accentColor: _accentColor,
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
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
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
                          gradient: LinearGradient(
                            colors: [_accentColor, const Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: -5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
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
                                fontSize: 16,
                              ),
                            ),
                          ],
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

  Widget _buildTotalHeader(
    String label,
    double amount,
    Color color,
    NumberFormat currency,
  ) {
    String displayString = label == "STATUS"
        ? "All Settled"
        : (amount > 0
              ? "+ ${currency.format(amount)}"
              : currency.format(amount));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayString,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
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
          Icons.credit_card_off,
          size: 60,
          color: Colors.white.withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        const Text(
          "No Credit Cards Added",
          style: TextStyle(color: Colors.white54),
        ),
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
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: const Color(0xff1B263B).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Card Details",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow("Card Name", card.name),
                const Divider(color: Colors.white10, height: 24),
                _buildDetailRow(
                  "Credit Limit",
                  currency.format(card.creditLimit),
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildDetailRow(
                  "Statement Date",
                  "${_getOrdinal(card.billDate)} of month",
                ),
                const Divider(color: Colors.white10, height: 24),
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
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        label: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          "Edit",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
        backgroundColor: const Color(0xff0D1B2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          "Delete Account?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to delete '${card.name}'? This will permanently remove the account and all its associated transactions.",
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Use state-based loading overlay
              setState(() {
                _isLoading = true;
              });

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
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.redAccent,
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
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
