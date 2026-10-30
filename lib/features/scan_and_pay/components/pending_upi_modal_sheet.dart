// lib/features/scan_and_pay/components/pending_upi_modal_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../models/upi_payment_models.dart';
import '../providers/pending_upi_provider.dart';
import '../views/upi_payment_form_page.dart';

// Dynamic IconData from DB codepoints — build with --no-tree-shake-icons.
IconData _iconFromCode(int code) =>
    IconData(code, fontFamily: 'MaterialIcons');

class PendingUpiModalSheet extends ConsumerWidget {
  const PendingUpiModalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PendingUpiModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pendingList = ref.watch(pendingUpiPaymentsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.pending_actions_rounded,
                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PENDING UPI VERIFICATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: isDark
                                ? Colors.amber.shade300
                                : Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pendingList.isEmpty
                              ? 'No Pending Payments'
                              : '${pendingList.length} Payment${pendingList.length > 1 ? 's' : ''} Awaiting Confirmation',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pendingList.length > 1)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ConfirmationBottomSheet.show(
                          context,
                          title: 'Confirm All Payments?',
                          description:
                              'This will log all ${pendingList.length} pending UPI payments into your accounts.',
                          confirmText: 'CONFIRM ALL',
                          onConfirm: () async {
                            final count = await ref
                                .read(pendingUpiPaymentsProvider.notifier)
                                .confirmAll();
                            if (context.mounted) {
                              Navigator.pop(context);
                              CustomSnackbars.showSuccess(
                                context,
                                message: '$count UPI transactions recorded!',
                              );
                            }
                          },
                        );
                      },
                      child: Text(
                        'CONFIRM ALL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.amber.shade300
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),

            if (pendingList.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'All Caught Up!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No unconfirmed UPI payments pending.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: pendingList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) {
                    final item = pendingList[i];
                    return _buildPaymentCard(context, ref, item, theme, isDark);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    WidgetRef ref,
    PendingUpiPayment item,
    ThemeData theme,
    bool isDark,
  ) {
    final timeStr = DateFormat('hh:mm a • dd MMM').format(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Payee & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.payeeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.payeeVpa,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CurrencyText(
                amount: item.amount,
                sign: '₹ ',
                amountStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Detail Badges: Account, Category, Bucket, Time
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildPill(
                Icons.account_balance_rounded,
                item.accountName,
                theme,
              ),
              if (item.categoryName != null)
                _buildPill(
                  item.categoryIcon != null
                      ? _iconFromCode(item.categoryIcon!)
                      : Icons.category_rounded,
                  item.categoryName!,
                  theme,
                ),
              if (item.bucketName != null)
                _buildPill(
                  Icons.pie_chart_outline_rounded,
                  item.bucketName!,
                  theme,
                ),
              _buildPill(
                Icons.access_time_rounded,
                timeStr,
                theme,
              ),
            ],
          ),

          if (item.note != null && item.note!.isNotEmpty && item.note != item.payeeName) ...[
            const SizedBox(height: 6),
            Text(
              'Note: "${item.note}"',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Action Buttons: Edit Details, Discard, Confirm
          Row(
            children: [
              // Edit Details Button
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit details in transaction form',
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UpiPaymentFormPage(
                        pendingPayment: item,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),

              // Discard Button
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ConfirmationBottomSheet.show(
                    context,
                    title: 'Discard Payment?',
                    description:
                        'Did not complete or cancelled? This will remove this entry.',
                    confirmText: 'DISCARD',
                    isDestructive: true,
                    onConfirm: () {
                      ref
                          .read(pendingUpiPaymentsProvider.notifier)
                          .discardPayment(item.id);
                    },
                  );
                },
                icon: const Icon(Icons.close_rounded, size: 14),
                label: const Text(
                  'DISCARD',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),

              const Spacer(),

              // Confirm & Save Button
              ElevatedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final success = await ref
                      .read(pendingUpiPaymentsProvider.notifier)
                      .confirmPayment(item.id);
                  if (success && context.mounted) {
                    CustomSnackbars.showSuccess(
                      context,
                      message:
                          '₹${item.amount.toStringAsFixed(2)} to ${item.payeeName} recorded successfully!',
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                label: const Text(
                  'CONFIRM & SAVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
