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

  // Design Constants
  final Color _bgColor = const Color(0xff050505);
  final Color _accentRed = const Color(0xFFE63946);
  final Color _accentBlue = const Color(0xFF4361EE);

  // New Colors for Amounts
  final Color _positiveGreen = const Color(0xFF00E676);
  final Color _negativeRed = const Color(0xFFFF4D6D);

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
      child: Scaffold(
        backgroundColor: _bgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Credit Portfolio",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const AddCreditCardSheet(),
              ),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: _accentBlue.withOpacity(0.5)),
                ),
                child: const Icon(
                  Icons.add_card_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              tooltip: "Add New Card",
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Stack(
          children: [
            // --- LAYER 1: Aurora Ambient Glows ---
            Positioned(
              top: -100,
              left: -50,
              child: _buildAuroraOrb(_accentBlue, 300),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: _buildAuroraOrb(_accentRed, 300),
            ),

            // --- LAYER 2: Content ---
            AsyncStreamBuilder<List<CreditCardModel>>(
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
                Color valueColor = Colors.white;
                Color glowColor = Colors.white.withOpacity(0.1);

                if (totalDebt > 0.01) {
                  label = "TOTAL PAYABLE";
                  displayAmount = -totalDebt; // Negative for Debt
                  valueColor = _negativeRed; // RED
                  glowColor = _negativeRed.withOpacity(0.2);
                } else if (totalSurplus.abs() > 0.01) {
                  label = "TOTAL SURPLUS";
                  displayAmount = -totalSurplus; // Positive for Surplus
                  valueColor = _positiveGreen; // GREEN
                  glowColor = _positiveGreen.withOpacity(0.2);
                }

                return Stack(
                  children: [
                    Column(
                      children: [
                        // MINIMIZED WHITESPACE:
                        // Reduced from (padding.top + kToolbarHeight) to (padding.top + 40)
                        // This pulls the card up by ~16 pixels closer to the Title.
                        SizedBox(
                          height: MediaQuery.of(context).padding.top + 40,
                        ),

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

                        const SizedBox(
                          height: 16,
                        ), // Gap between header and list
                        // List of Cards
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: cards.length,
                            itemBuilder: (context, index) => CreditCardTile(
                              card: cards[index],
                              currency: _currency,
                              accentColor: _accentBlue,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreditCardDetailScreen(
                                    card: cards[index],
                                  ),
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
                                builder: (ctx) =>
                                    const AddCreditTransactionSheet(),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: _accentBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accentBlue.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                    ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAuroraOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }

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
      // Reduced vertical padding from 20 to 12 for compactness
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
              color: Colors.white.withOpacity(0.5),
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
          color: Colors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 16),
        Text(
          "No Cards Found",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: const Color(0xff0D1B2A).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
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
                        color: _accentBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.credit_card,
                        color: _accentBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Card Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
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
                          foregroundColor: _accentRed,
                          backgroundColor: _accentRed.withOpacity(0.1),
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
        backgroundColor: const Color(0xff0D1B2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
              style: TextStyle(color: _accentRed, fontWeight: FontWeight.bold),
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
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
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
