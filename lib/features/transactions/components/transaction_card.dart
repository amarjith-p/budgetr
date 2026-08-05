import 'package:budgetr/core/components/currency_text.dart';
import 'package:budgetr/core/database/app_database.dart';
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
import '../../../core/components/custom_snackbars.dart';
import '../../../core/utils/location_helper.dart';
import '../services/transaction_service.dart';
import '../providers/transaction_provider.dart';
import '../../accounts/providers/account_provider.dart';

class TransactionCard extends ConsumerWidget {
  final TransactionWithDetails data;
  final String currentAccountId;
  final bool isGlobalView;
  final double? closingBalance;

  const TransactionCard({
    Key? key,
    required this.data,
    required this.currentAccountId,
    this.isGlobalView = false,
    this.closingBalance,
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
      sign = isMoneyLeaving ? '- ' : '+ ';
    } else if (isExpense) {
      sign = '- ';
    } else {
      sign = '+ ';
    }

    IconData leadingIcon = Icons.sync_alt_rounded;
    String mainTitle = 'Transfer';
    String subTitle = '';

    bool isLoanRepayment =
        tx.subCategory == 'Loan Principal' ||
        tx.subCategory == 'Loan Interest' ||
        tx.subCategory == 'Tax on Interest' ||
        tx.subCategory == 'Bank Charges on Loan';

    final accountsList = ref.watch(accountsStreamProvider).asData?.value ?? [];
    final parentAccount = accountsList
        .where((a) => a.id == currentAccountId)
        .firstOrNull;
    final bool isParentLoanSettled =
        parentAccount?.type == 'Loan' && (parentAccount?.isClosed ?? false);

    if (isTransfer) {
      if (tx.toAccountId == 'EXTERNAL_IN') {
        subTitle = 'From External Source';
      } else if (tx.toAccountId == 'EXTERNAL_OUT') {
        subTitle = 'To External Source';
      } else {
        subTitle = isMoneyLeaving
            ? 'To ${data.toAccount?.name ?? "Unknown"}'
            : 'From ${data.account.name}';
      }
    } else if (isLoanRepayment) {
      mainTitle = 'Loan Repayment';
      subTitle = tx.subCategory!;
      leadingIcon = Icons.payments_rounded;
      amountColor = theme.colorScheme.primary;
    } else if (!isTransfer && data.category != null) {
      leadingIcon = IconConstants.getIconByCode(data.category!.iconCode);
      mainTitle = data.category!.name;
      subTitle = tx.subCategory ?? data.category!.type;
    }

    Account? globalAccount;
    if (isGlobalView) {
      final rawAccounts = ref.watch(accountsStreamProvider).asData?.value ?? [];
      globalAccount = rawAccounts
          .where((a) => a.id == currentAccountId)
          .firstOrNull;
    }

    bool isExplicitRepayment = data.category?.name == 'Repayment';
    if (isExplicitRepayment) {
      mainTitle = 'Statement Repayment';
      leadingIcon = Icons.verified_rounded;
      amountColor = theme.colorScheme.primary;
    }

    bool isSpilloverEligible = false;
    if (data.account.type == 'Credit Cards') {
      final bDay = data.account.billDate ?? 15;
      DateTime currentBillDate = DateTime(
        tx.date.year,
        tx.date.month,
        bDay,
        23,
        59,
        59,
      );
      if (tx.date.day > bDay) {
        currentBillDate = DateTime(
          tx.date.year,
          tx.date.month + 1,
          bDay,
          23,
          59,
          59,
        );
      }
      final pureTxDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final pureBillDate = DateTime(
        currentBillDate.year,
        currentBillDate.month,
        currentBillDate.day,
      );
      final diff = pureBillDate.difference(pureTxDate).inDays;
      if (diff >= 0 && diff <= 2) {
        isSpilloverEligible = true;
      }
    }

    Color? cardBgColor;
    if (tx.isSpillover) {
      cardBgColor = theme.colorScheme.primaryContainer.withOpacity(
        isDark ? 0.2 : 0.4,
      );
      subTitle = subTitle.isEmpty
          ? '  Carry Forwarded'
          : '$subTitle   Carry Forwarded';
    } else if (isSpilloverEligible && !tx.isSettlementVerified) {
      cardBgColor = Colors.orangeAccent.withOpacity(isDark ? 0.1 : 0.15);
      subTitle = subTitle.isEmpty
          ? '  Verify Settlement'
          : '$subTitle   Verify';
    } else if (isSpilloverEligible && tx.isSettlementVerified) {
      subTitle = subTitle.isEmpty ? '  Settled' : '$subTitle   Settled';
    }

    final dayStr = tx.date.day.toString().padLeft(2, '0');
    final shortMonthStr = DateTimeConstants.shortMonths[tx.date.month - 1];
    final fullMonthStr = DateTimeConstants.fullMonths[tx.date.month - 1];
    final weekdayStr = DateTimeConstants.shortDays[tx.date.weekday - 1];

    final int rawHour = tx.date.hour;
    final String amPm = rawHour >= 12 ? 'PM' : 'AM';
    final int displayHour = rawHour == 0
        ? 12
        : (rawHour > 12 ? rawHour - 12 : rawHour);
    final String minuteStr = tx.date.minute.toString().padLeft(2, '0');
    final String timeStr =
        '${displayHour.toString().padLeft(2, '0')}:$minuteStr $amPm';

    final compactDate = '$dayStr/$shortMonthStr';
    final expandedDate =
        '$dayStr $fullMonthStr ${tx.date.year}, $weekdayStr : $timeStr';
    final boxyRadius = BorderRadius.circular(DesignTokens.spacingXs);

    final VoidCallback handleClone = () {
      if (isLoanRepayment || isParentLoanSettled) {
        HapticFeedback.heavyImpact();
        CustomSnackbars.showError(
          context,
          message: isParentLoanSettled
              ? 'This loan is settled. History is read-only.'
              : 'Loan records cannot be cloned. Log a new payment instead.',
        );
      } else {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TransactionFormPage(existingTransaction: data, isClone: true),
          ),
        );
      }
    };

    final VoidCallback handleSplit = () {
      if (isLoanRepayment || isParentLoanSettled) {
        HapticFeedback.heavyImpact();
        CustomSnackbars.showError(
          context,
          message: isParentLoanSettled
              ? 'This loan is settled. History is read-only.'
              : 'Loan records are mathematically locked and cannot be split.',
        );
      } else {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TransactionFormPage(existingTransaction: data, isSplit: true),
          ),
        );
      }
    };

    final VoidCallback handleEdit = () {
      if (isParentLoanSettled) {
        HapticFeedback.heavyImpact();
        CustomSnackbars.showError(
          context,
          message: 'Settled loan records cannot be edited.',
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionFormPage(existingTransaction: data),
          ),
        );
      }
    };

    final VoidCallback handleDelete = () {
      if (isParentLoanSettled) {
        HapticFeedback.heavyImpact();
        CustomSnackbars.showError(
          context,
          message: 'Settled loan records cannot be deleted.',
        );
      } else {
        ConfirmationBottomSheet.show(
          context,
          title: 'Delete Log?',
          description:
              'This will permanently remove the record and reverse the account balances. Proceed?',
          confirmText: 'DELETE',
          isDestructive: true,
          onConfirm: () => ref
              .read(transactionActionProvider.notifier)
              .deleteTransaction(tx.id),
        );
      }
    };

    return BoxySlidableCard(
      key: ValueKey('${tx.id}_$currentAccountId'),
      customBackgroundColor: cardBgColor,
      onEdit: handleEdit,
      onClone: handleClone,
      onSplit: handleSplit,
      onDelete: handleDelete,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cardBgColor != null
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: boxyRadius,
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: Icon(
              leadingIcon,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          title: Text(
            mainTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subTitle,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isSpilloverEligible &&
                          !tx.isSpillover &&
                          !tx.isSettlementVerified
                      ? Colors.orangeAccent.shade700
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSpilloverEligible || tx.isSpillover
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isGlobalView && globalAccount != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${globalAccount.name} - ${globalAccount.providerName}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: globalAccount.type == 'Credit Cards'
                        ? theme.colorScheme.error.withOpacity(0.7)
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyText(
                amount: tx.amount,
                sign: sign,
                amountStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: amountColor,
                  letterSpacing: -0.5,
                ),
                symbolStyle: TextStyle(color: amountColor.withOpacity(0.85)),
              ),

              // --- FIX: Label removed, cleaner display ---
              if (closingBalance != null) ...[
                const SizedBox(height: 2),
                CurrencyText(
                  amount: closingBalance!.abs(),
                  sign: closingBalance! < 0 ? '-₹ ' : '₹ ',
                  amountStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    letterSpacing: -0.2,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],

              const SizedBox(height: 4),
              Text(
                compactDate,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tx.bucketId != null && tx.bucketId != -1) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.donut_small_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Bucket: ${tx.bucketName ?? data.bucket?.name ?? ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          expandedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(height: 1),
                      ),
                      Text(
                        '"${tx.notes}"',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],

                    if (tx.locationName != null &&
                        tx.locationName!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(height: 1),
                      ),
                      InkWell(
                        onTap: () async {
                          if (tx.latitude == null || tx.longitude == null)
                            return;
                          try {
                            await LocationHelper.openMap(
                              tx.latitude!,
                              tx.longitude!,
                            );
                          } catch (e) {
                            HapticFeedback.heavyImpact();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not open Maps. Please ensure a browser or maps app is installed.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 4.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tx.locationName!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (isSpilloverEligible || tx.isSpillover) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(height: 1),
                      ),
                      if (!tx.isSettlementVerified) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.rule_folder_outlined,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Carry Forward',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: tx.isSpillover,
                              activeColor: theme.colorScheme.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(transactionActionProvider.notifier)
                                    .toggleSpillover(tx.id, val);
                              },
                            ),
                          ],
                        ),
                      ],
                      if (!tx.isSpillover) ...[
                        if (!tx.isSettlementVerified) const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  tx.isSettlementVerified
                                      ? Icons.check_circle_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Settled in current bill',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: tx.isSettlementVerified
                                        ? Colors.green
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(transactionActionProvider.notifier)
                                    .verifySettlement(
                                      tx.id,
                                      !tx.isSettlementVerified,
                                    );
                              },
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: tx.isSettlementVerified
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.green,
                              ),
                              child: Text(
                                tx.isSettlementVerified ? 'UNDO' : 'VERIFY',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
