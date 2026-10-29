import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/currency_text.dart';
import '../../accounts/providers/account_provider.dart';

class CreditPayableBottomSheet extends ConsumerStatefulWidget {
  final List<Account> bankAccounts;
  final double totalCreditLiability;
  const CreditPayableBottomSheet({
    Key? key,
    required this.bankAccounts,
    required this.totalCreditLiability,
  }) : super(key: key);

  @override
  ConsumerState<CreditPayableBottomSheet> createState() =>
      _CreditPayableBottomSheetState();
}

class _CreditPayableBottomSheetState
    extends ConsumerState<CreditPayableBottomSheet> {
  late Set<String> _selectedIds;

  bool _isAccountHided(Account acc) => acc.isHidden || acc.hideBalanceInHome;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.bankAccounts
        .where((a) => a.isCreditPayable && !_isAccountHided(a))
        .map((a) => a.id)
        .toSet();
  }

  void _toggleSelection(String id, bool isSelected) {
    HapticFeedback.selectionClick();
    setState(() {
      if (isSelected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  Future<void> _saveAllocations() async {
    final updatedList = widget.bankAccounts.map((acc) {
      final isHided = _isAccountHided(acc);
      return acc.copyWith(
        isCreditPayable: !isHided && _selectedIds.contains(acc.id),
      );
    }).toList();
    await ref
        .read(accountActionProvider.notifier)
        .updateAccountPreferences(updatedList);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double allocatedFunds = 0.0;
    for (var acc in widget.bankAccounts) {
      if (_selectedIds.contains(acc.id) && !_isAccountHided(acc)) {
        allocatedFunds += (acc.balance > 0 ? acc.balance : 0.0);
      }
    }
    final liability = widget.totalCreditLiability.abs();
    final difference = allocatedFunds - liability;

    String statusText = 'TALLY';
    Color statusColor = Colors.blueAccent.shade700;
    if (difference > 0) {
      statusText = 'SURPLUS';
      statusColor = Colors.green.shade600;
    } else if (difference < 0) {
      statusText = 'SHORTFALL';
      statusColor = theme.colorScheme.error;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusLg),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: DesignTokens.spacingMd,
                    top: DesignTokens.spacingMd,
                  ),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Payable Allocation',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Liability (Cr)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              // --- FIX: VISUALLY FORCE LIABILITY TO SHOW AS NEGATIVE ---
                              CurrencyText(
                                amount: liability,
                                sign: liability > 0 ? '-₹ ' : '₹ ',
                                amountStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Allocated Funds',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              CurrencyText(
                                amount: allocatedFunds,
                                sign: '₹ ',
                                amountStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              CurrencyText(
                                amount: difference.abs(),
                                sign: difference < 0
                                    ? '-₹ '
                                    : (difference > 0 ? '+₹ ' : '₹ '),
                                amountStyle: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  letterSpacing: -1.0,
                                ),
                                symbolStyle: TextStyle(
                                  color: statusColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: widget.bankAccounts.length,
                  itemBuilder: (context, index) {
                    final acc = widget.bankAccounts[index];
                    final isHided = _isAccountHided(acc);
                    final isSelected =
                        !isHided && _selectedIds.contains(acc.id);

                    final tileWidget = Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHided
                            ? (isDark
                                  ? Colors.white.withOpacity(0.02)
                                  : Colors.black.withOpacity(0.02))
                            : (isSelected
                                  ? theme.colorScheme.primaryContainer
                                        .withOpacity(0.3)
                                  : theme.colorScheme.surface),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isHided
                              ? theme.dividerColor.withOpacity(0.4)
                              : (isSelected
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor),
                        ),
                      ),
                      child: Opacity(
                        opacity: isHided ? 0.45 : 1.0,
                        child: CheckboxListTile(
                          value: isSelected,
                          enabled: !isHided,
                          activeColor: theme.colorScheme.primary,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  acc.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isHided
                                        ? theme.colorScheme.onSurface
                                              .withOpacity(0.6)
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isHided) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: theme.dividerColor.withOpacity(
                                        0.6,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.visibility_off_rounded,
                                        size: 10,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      // const SizedBox(width: 3),
                                      // Text(
                                      //   'HIDDEN',
                                      //   style: TextStyle(
                                      //     fontSize: 9,
                                      //     fontWeight: FontWeight.w800,
                                      //     letterSpacing: 0.5,
                                      //     color: theme.colorScheme.onSurfaceVariant,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                acc.providerName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₹ ${CurrencyFormatter.format(acc.balance)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isHided
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          onChanged: isHided
                              ? null
                              : (val) => _toggleSelection(acc.id, val ?? false),
                        ),
                      ),
                    );

                    if (isHided) {
                      return Tooltip(
                        message:
                            'Hidden accounts cannot be selected for payable allocation',
                        child: tileWidget,
                      );
                    }
                    return tileWidget;
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ModernBoxyButton(
                        onPressed: () => Navigator.pop(context),
                        label: 'CANCEL',
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      flex: 2,
                      child: ModernBoxyButton(
                        onPressed: _saveAllocations,
                        label: 'SAVE ALLOCATIONS',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
