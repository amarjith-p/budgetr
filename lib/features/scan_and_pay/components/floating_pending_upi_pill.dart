// lib/features/scan_and_pay/components/floating_pending_upi_pill.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/components/currency_text.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/pending_upi_provider.dart';

class FloatingPendingUpiCard extends ConsumerStatefulWidget {
  const FloatingPendingUpiCard({super.key});

  @override
  ConsumerState<FloatingPendingUpiCard> createState() =>
      _FloatingPendingUpiCardState();
}

class _FloatingPendingUpiCardState
    extends ConsumerState<FloatingPendingUpiCard> {
  int _currentIndex = 0;
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final pendingList = ref.watch(pendingUpiPaymentsProvider);
    if (pendingList.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_currentIndex >= pendingList.length) {
      _currentIndex = 0;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = pendingList[_currentIndex];
    final isMultiple = pendingList.length > 1;
    final timeStr = DateFormat('hh:mm a').format(item.createdAt);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.amber.shade700.withValues(alpha: 0.8)
                  : Colors.amber.shade600,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Status + Collapse/Expand
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isCollapsed = !_isCollapsed);
                },
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.amber.shade900.withValues(alpha: 0.25)
                        : Colors.amber.shade100.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(9),
                      bottom: _isCollapsed
                          ? const Radius.circular(9)
                          : Radius.zero,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_actions_rounded,
                        color: isDark
                            ? Colors.amber.shade300
                            : Colors.amber.shade900,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isMultiple
                              ? 'PENDING UPI PAYMENT (${_currentIndex + 1} OF ${pendingList.length})'
                              : 'PENDING UPI PAYMENT VERIFICATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: isDark
                                ? Colors.amber.shade300
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                      if (isMultiple && !_isCollapsed) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _currentIndex =
                                  (_currentIndex - 1 + pendingList.length) %
                                  pendingList.length;
                            });
                          },
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _currentIndex =
                                  (_currentIndex + 1) % pendingList.length;
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(
                        _isCollapsed
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark
                            ? Colors.amber.shade300
                            : Colors.amber.shade900,
                      ),
                    ],
                  ),
                ),
              ),

              if (!_isCollapsed) ...[
                // Card Body: Merchant details, account, amount, and time
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
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
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.accountName}${item.categoryName != null ? ' • ${item.categoryName}' : ''} • $timeStr',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
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
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Divider(height: 1),
                ),

                // Direct Action Buttons: DISCARD and CONFIRM & SAVE
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(
                    children: [
                      // Discard Button
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ConfirmationBottomSheet.show(
                              context,
                              title: 'Discard Payment?',
                              description:
                                  'Did not complete or cancelled? This will remove this pending entry without recording any transaction.',
                              confirmText: 'DISCARD',
                              isDestructive: true,
                              onConfirm: () {
                                ref
                                    .read(pendingUpiPaymentsProvider.notifier)
                                    .discardPayment(item.id);
                                CustomSnackbars.showSuccess(
                                  context,
                                  message: 'Payment discarded.',
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.close_rounded, size: 14),
                          label: const Text(
                            'DISCARD',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Confirm & Save Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
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
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 15,
                          ),
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

typedef FloatingPendingUpiPill = FloatingPendingUpiCard;
