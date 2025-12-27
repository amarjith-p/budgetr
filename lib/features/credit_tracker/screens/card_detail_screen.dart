import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Ensure you have this package or remove groupBy if strictly standard
import '../../../core/constants/bank_list.dart';
import '../../../core/widgets/modern_loader.dart';
import '../models/credit_models.dart';
import '../services/credit_service.dart';

class CreditCardDetailScreen extends StatelessWidget {
  final CreditCardModel card;
  const CreditCardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: const Color(0xff0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              card.bankName,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<CreditTransactionModel>>(
        stream: CreditService().getTransactionsForCard(card.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: ModernLoader());

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No transactions yet.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          // Group by Month (e.g., "Dec 2023")
          // If 'collection' package is missing, you might need to add it to pubspec.yaml: collection: ^1.18.0
          // Or simply list them linearly if you prefer not to add dependencies.
          final grouped = groupBy(snapshot.data!, (CreditTransactionModel t) {
            return DateFormat('MMMM yyyy').format(t.date.toDate());
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final month = grouped.keys.elementAt(index);
              final txns = grouped[month]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      month,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  ...txns
                      .map((t) => _buildTransactionItem(t, currency))
                      .toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(
    CreditTransactionModel txn,
    NumberFormat currency,
  ) {
    final isExpense = txn.type == 'Expense';
    final color = isExpense ? Colors.white : Colors.greenAccent;
    final iconColor = isExpense ? const Color(0xFF3A86FF) : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(
              isExpense ? Icons.shopping_bag_outlined : Icons.payment,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.subCategory.isNotEmpty && txn.subCategory != 'General'
                      ? txn.subCategory
                      : txn.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        txn.bucket,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (txn.notes.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          txn.notes,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Amount & Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isExpense ? '-' : '+'} ${currency.format(txn.amount)}",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM').format(txn.date.toDate()),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
