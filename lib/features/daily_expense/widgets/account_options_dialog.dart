import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_models.dart';

class AccountOptionsDialog extends StatelessWidget {
  final ExpenseAccountModel account;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const AccountOptionsDialog({
    super.key,
    required this.account,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: const Color(0xff1B263B).withOpacity(0.9),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Account Options",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow("Account Name", account.name),
              const Divider(color: Colors.white10, height: 24),
              _buildDetailRow("Bank", account.bankName),
              const Divider(color: Colors.white10, height: 24),
              _buildDetailRow("Type", account.accountType),
              const Divider(color: Colors.white10, height: 24),
              _buildDetailRow("Account No", "**** ${account.accountNumber}"),
              const Divider(color: Colors.white10, height: 24),
              _buildDetailRow(
                  "Balance", currency.format(account.currentBalance)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
                      label: const Text("Delete",
                          style: TextStyle(color: Colors.redAccent)),
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
                        Navigator.pop(context);
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white, size: 20),
                      label: const Text("Edit",
                          style: TextStyle(color: Colors.white)),
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
    );
  }

  Widget _buildDetailRow(String label, String value) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5))),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold))
      ]);
}
