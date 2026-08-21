import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/constants/date_time_constants.dart';
import '../models/custom_budget_details.dart';
import '../providers/custom_budget_provider.dart';
import '../views/custom_budget_transactions_page.dart';
import 'custom_budget_form_sheet.dart';

class CustomBudgetCard extends ConsumerWidget {
  final CustomBudgetWithDetails data;
  final bool isActive;

  const CustomBudgetCard({Key? key, required this.data, required this.isActive})
    : super(key: key);

  String _formatDate(DateTime d) =>
      '${d.day} ${DateTimeConstants.shortMonths[d.month - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDanger = data.progress >= 1.0;
    final activeColor = isDanger
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final activeRadius = BorderRadius.circular(8.0);

    return Slidable(
      key: ValueKey(data.budget.id),
      enabled: true,
      startActionPane: isActive
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                CustomSlidableAction(
                  onPressed: (_) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      shape: DesignTokens.bottomSheetShape,
                      builder: (ctx) =>
                          CustomBudgetFormSheet(existingBudget: data.budget),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  padding: EdgeInsets.zero,
                  child: Container(
                    margin: const EdgeInsets.only(
                      right: DesignTokens.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: activeRadius,
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_rounded),
                        SizedBox(height: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : null,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: isActive ? 0.50 : 0.25,
        children: [
          if (isActive)
            CustomSlidableAction(
              onPressed: (_) {
                ConfirmationBottomSheet.show(
                  context,
                  title: 'Settle Budget?',
                  description:
                      'This moves the budget to the Settled tab. It will become view-only and stop tracking future expenses.',
                  confirmText: 'SETTLE',
                  onConfirm: () => ref
                      .read(customBudgetActionProvider.notifier)
                      .settleBudget(data.budget.id),
                );
              },
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onTertiaryContainer,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.only(left: DesignTokens.spacingSm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: activeRadius,
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded),
                    SizedBox(height: 4),
                    Text(
                      'Settle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          CustomSlidableAction(
            onPressed: (_) {
              ConfirmationBottomSheet.show(
                context,
                title: 'Delete Budget?',
                description:
                    'This will permanently remove the tracker. Your logged transactions will remain entirely safe.',
                confirmText: 'DELETE',
                isDestructive: true,
                onConfirm: () => ref
                    .read(customBudgetActionProvider.notifier)
                    .deleteBudget(data.budget.id),
              );
            },
            backgroundColor: Colors.transparent,
            foregroundColor: theme.colorScheme.onErrorContainer,
            padding: EdgeInsets.zero,
            child: Container(
              margin: const EdgeInsets.only(left: DesignTokens.spacingSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: activeRadius,
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded),
                  SizedBox(height: 4),
                  Text(
                    'Delete',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: Material(
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: activeRadius,
          side: BorderSide(
            color: isDanger
                ? theme.colorScheme.error.withOpacity(0.4)
                : theme.dividerColor,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomBudgetTransactionsPage(data: data),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.budget.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data.budget.timeFrame}     ${_formatDate(data.budget.startDate)} - ${_formatDate(data.budget.endDate)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CurrencyText(
                      amount: data.budget.amountLimit,
                      sign: '₹ ',
                      amountStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: activeColor,
                      ),
                      symbolStyle: TextStyle(
                        fontSize: 12,
                        color: activeColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 8.0,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * data.progress,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- APPLIED GLOBAL FORMATTER ---
                    Text(
                      'Spent: ₹${CurrencyFormatter.format(data.spent)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // --- APPLIED GLOBAL FORMATTER ---
                    Text(
                      data.remaining >= 0
                          ? '₹${CurrencyFormatter.format(data.remaining)} Left'
                          : '₹${CurrencyFormatter.format(data.remaining.abs())} Over',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDanger
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
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
}
