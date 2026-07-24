import 'package:budgetr/core/components/currency_text.dart';
import 'package:budgetr/features/transactions/views/transaction_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/constants/icon_constants.dart';
import '../../../core/constants/date_time_constants.dart'; 
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../services/transaction_service.dart';
import '../providers/transaction_provider.dart';

class TransactionCard extends ConsumerWidget {
  final TransactionWithDetails data;
  final String currentAccountId; 

  const TransactionCard({
    Key? key, 
    required this.data, 
    required this.currentAccountId
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tx = data.transaction;
    
    final isExpense = tx.type == 'Expense';
    final isIncome = tx.type == 'Income';
    final isTransfer = tx.type == 'Transfer';
    
    bool isMoneyLeaving;
    if (isExpense) {
      isMoneyLeaving = true;
    } else if (isIncome) {
      isMoneyLeaving = false;
    } else {
      if (tx.toAccountId == 'EXTERNAL_IN') {
        isMoneyLeaving = false; 
      } else if (tx.toAccountId == 'EXTERNAL_OUT') {
        isMoneyLeaving = true; 
      } else {
        isMoneyLeaving = tx.accountId == currentAccountId;
      }
    }
    
    Color amountColor = TransactionColors.getTypeColor(tx.type, theme);
    String sign;
    if (isTransfer) {
      sign = isMoneyLeaving ? '-₹' : '+₹';
    } else if (isExpense) {
      sign = '-₹';
    } else {
      sign = '+₹';
    }

    IconData leadingIcon = Icons.sync_alt_rounded;
    String mainTitle = 'Transfer';
    String subTitle = '';
    
    if (isTransfer) {
      if (tx.toAccountId == 'EXTERNAL_IN') {
        subTitle = 'From External Source';
      } else if (tx.toAccountId == 'EXTERNAL_OUT') {
        subTitle = 'To External Source';
      } else {
        subTitle = isMoneyLeaving ? 'To ${data.toAccount?.name ?? "Unknown"}' : 'From ${data.account.name}';
      }
    }
    
    if (!isTransfer && data.category != null) {
      leadingIcon = IconConstants.getIconByCode(data.category!.iconCode);
      mainTitle = data.category!.name;
      subTitle = tx.subCategory ?? data.category!.type;
    }

    bool isExplicitRepayment = data.category?.name == 'Repayment';
    if (isExplicitRepayment) {
      mainTitle = 'Statement Repayment';
      leadingIcon = Icons.verified_rounded; 
      amountColor = theme.colorScheme.primary; 
    }

    // ==========================================
    // SMART RECONCILIATION ENGINE
    // ==========================================
    bool isSpilloverEligible = false;
    if (data.account.type == 'Credit Cards') {
      final bDay = data.account.billDate ?? 15;
      DateTime currentBillDate = DateTime(tx.date.year, tx.date.month, bDay);
      if (tx.date.day > bDay) {
        currentBillDate = DateTime(tx.date.year, tx.date.month + 1, bDay);
      }
      
      final pureTxDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final diff = currentBillDate.difference(pureTxDate).inDays;
      
      // If within 2 days BEFORE or ON the bill date
      if (diff >= 0 && diff <= 2) {
        isSpilloverEligible = true;
      }
    }

    // --- FIX: Safely append the warning without overwriting the actual subcategory string ---
    Color? cardBgColor; 
    if (tx.isSpillover) {
      cardBgColor = theme.colorScheme.primaryContainer.withOpacity(isDark ? 0.2 : 0.4);
      subTitle = subTitle.isEmpty ? '→ Carry Forwarded' : '$subTitle • Carry Forwarded';
    } else if (isSpilloverEligible && !tx.isSettlementVerified) {
      cardBgColor = Colors.orangeAccent.withOpacity(isDark ? 0.1 : 0.15);
      subTitle = subTitle.isEmpty ? '⚠️ Verify Settlement' : '$subTitle • ⚠️ Verify';
    } else if (isSpilloverEligible && tx.isSettlementVerified) {
      subTitle = subTitle.isEmpty ? '✓ Settled' : '$subTitle • ✓ Settled';
    }

    final dayStr = tx.date.day.toString().padLeft(2, '0');
    final shortMonthStr = DateTimeConstants.shortMonths[tx.date.month - 1];
    final fullMonthStr = DateTimeConstants.fullMonths[tx.date.month - 1];
    final weekdayStr = DateTimeConstants.shortDays[tx.date.weekday - 1];
    final timeStr = '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';

    final compactDate = '$dayStr/$shortMonthStr';
    final expandedDate = '$dayStr $fullMonthStr ${tx.date.year}, $weekdayStr : $timeStr';

    final boxyRadius = BorderRadius.circular(DesignTokens.spacingXs);

    return BoxySlidableCard(
      key: ValueKey(tx.id),
      customBackgroundColor: cardBgColor, 
      onEdit: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionFormPage(existingTransaction: data),
          ),
        );
      },
      onDelete: () {
        ConfirmationBottomSheet.show(
          context,
          title: 'Delete Log?',
          description: 'This will permanently remove the record and reverse the account balances. Proceed?',
          confirmText: 'DELETE',
          isDestructive: true,
          onConfirm: () => ref.read(transactionActionProvider.notifier).deleteTransaction(tx.id),
        );
      },
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: cardBgColor != null ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: boxyRadius,
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: Icon(leadingIcon, color: theme.colorScheme.primary, size: 22),
          ),
          title: Text(mainTitle, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2, fontSize: 15)),
          subtitle: Text(
            subTitle, 
            style: TextStyle(
              fontSize: 12, 
              color: isSpilloverEligible && !tx.isSpillover && !tx.isSettlementVerified ? Colors.orangeAccent.shade700 : theme.colorScheme.onSurfaceVariant, 
              fontWeight: isSpilloverEligible || tx.isSpillover ? FontWeight.w800 : FontWeight.w600
            )
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyText(
                amount: tx.amount,
                sign: sign,
                amountStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: amountColor, letterSpacing: -0.5),
                symbolStyle: TextStyle(color: amountColor.withOpacity(0.85)), 
              ),
              const SizedBox(height: 4),
              Text(compactDate, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.bucket != null) ...[
                      Row(
                        children: [
                          Icon(Icons.donut_small_rounded, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text('Bucket: ${data.bucket!.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          expandedDate, 
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)
                        ),
                      ],
                    ),
                    
                    if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(height: 1),
                      ),
                      Text('"${tx.notes}"', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                    ],

                    // --- INLINE RECONCILIATION TOGGLE (NEW) ---
                    if (isSpilloverEligible || tx.isSpillover) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.rule_folder_outlined, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              const Text('Push to next statement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          Switch(
                            value: tx.isSpillover,
                            activeColor: theme.colorScheme.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              ref.read(transactionActionProvider.notifier).toggleSpillover(tx.id, val);
                            },
                          )
                        ],
                      ),
                      
                      // Show confirmation logic ONLY if they haven't pushed it to the next statement
                      if (!tx.isSpillover) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  tx.isSettlementVerified ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, 
                                  size: 16, 
                                  color: Colors.green
                                ),
                                const SizedBox(width: 6),
                                Text('Settled in current bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tx.isSettlementVerified ? Colors.green : theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ref.read(transactionActionProvider.notifier).verifySettlement(tx.id, !tx.isSettlementVerified);
                              },
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: tx.isSettlementVerified ? theme.colorScheme.onSurfaceVariant : Colors.green,
                              ),
                              child: Text(tx.isSettlementVerified ? 'UNDO' : 'VERIFY', style: const TextStyle(fontWeight: FontWeight.w900)),
                            )
                          ],
                        )
                      ]
                    ],

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}