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
  ConsumerState<CreditPayableBottomSheet> createState() => _CreditPayableBottomSheetState();
}

class _CreditPayableBottomSheetState extends ConsumerState<CreditPayableBottomSheet> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    // Initialize the set with accounts previously marked as payable
    _selectedIds = widget.bankAccounts.where((a) => a.isCreditPayable).map((a) => a.id).toSet();
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
      return acc.copyWith(isCreditPayable: _selectedIds.contains(acc.id));
    }).toList();

    await ref.read(accountActionProvider.notifier).updateAccountPreferences(updatedList);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- MATHEMATICAL ENGINE ---
    double allocatedFunds = 0.0;
    for (var acc in widget.bankAccounts) {
      if (_selectedIds.contains(acc.id)) allocatedFunds += acc.balance;
    }

    final liability = widget.totalCreditLiability.abs(); 
    final difference = allocatedFunds - liability;

    // --- COLOR CONTRAST FIX ---
    // Explicitly assigning semantic colors so white text is always visible.
    String statusText = 'TALLY';
    Color statusColor = Colors.blueAccent.shade700;
    if (difference > 0) {
      statusText = 'SURPLUS';
      statusColor = Colors.green.shade600; // Guaranteed contrast in both themes
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // DRAG HANDLE
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd, top: DesignTokens.spacingMd),
                  decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // HERO METRICS
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Payable Allocation', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    
                    // Calculation Dashboard
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Liability (Cr)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
                              CurrencyText(amount: liability, sign: '₹', amountStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.error)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Allocated Funds', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
                              CurrencyText(amount: allocatedFunds, sign: '₹', amountStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)),
                                child: Text(statusText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
                              ),
                              CurrencyText(
                                amount: difference.abs(),
                                sign: difference < 0 ? '-₹' : (difference > 0 ? '+₹' : '₹'),
                                amountStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: -1.0),
                                symbolStyle: TextStyle(color: statusColor.withOpacity(0.8)),
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

              // ACCOUNT SELECTOR LIST
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: widget.bankAccounts.length,
                  itemBuilder: (context, index) {
                    final acc = widget.bankAccounts[index];
                    final isSelected = _selectedIds.contains(acc.id);
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: theme.colorScheme.primary,
                        title: Text(acc.name, style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                        subtitle: Row(
                          children: [
                            Text(acc.providerName, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                            const Spacer(),
                            Text('₹${acc.balance.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                          ],
                        ),
                        onChanged: (val) => _toggleSelection(acc.id, val ?? false),
                      ),
                    );
                  },
                ),
              ),

              // FOOTER
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: theme.dividerColor, width: 1.0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, -4))],
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
              )
            ],
          ),
        );
      },
    );
  }
}