// lib/features/automation/components/approve_staged_transaction_bottom_sheet.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../accounts/providers/account_provider.dart';
import '../../category_manager/providers/category_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../providers/smart_inbox_provider.dart';

class ApproveStagedTransactionBottomSheet extends ConsumerStatefulWidget {
  final StagedTransaction stagedTx;

  const ApproveStagedTransactionBottomSheet({Key? key, required this.stagedTx})
    : super(key: key);

  static void show(BuildContext context, StagedTransaction stagedTx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApproveStagedTransactionBottomSheet(stagedTx: stagedTx),
    );
  }

  @override
  ConsumerState<ApproveStagedTransactionBottomSheet> createState() =>
      _ApproveStagedTransactionBottomSheetState();
}

class _ApproveStagedTransactionBottomSheetState
    extends ConsumerState<ApproveStagedTransactionBottomSheet> {
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedCategoryIcon;
  String? _selectedSubCategory;
  int? _selectedBucketId;
  String? _selectedBucketName;
  late TextEditingController _notesCtrl;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(
      text: widget.stagedTx.merchantName ?? widget.stagedTx.sourceName,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoMatchAccount();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _autoMatchAccount() {
    final rawAccounts = ref.read(accountsStreamProvider).asData?.value ?? [];
    if (widget.stagedTx.accountLast4 != null &&
        widget.stagedTx.accountLast4!.isNotEmpty) {
      final match = rawAccounts
          .where((a) => (a.last4 ?? '').endsWith(widget.stagedTx.accountLast4!))
          .firstOrNull;
      if (match != null) {
        setState(() => _selectedAccountId = match.id);
        return;
      }
    }
    // Fallback: Default to first active non-loan account
    final defaultAcc = rawAccounts.where((a) => a.type != 'Loan').firstOrNull;
    if (defaultAcc != null && _selectedAccountId == null) {
      setState(() => _selectedAccountId = defaultAcc.id);
    }
  }

  Future<void> _submit() async {
    if (_selectedAccountId == null ||
        (_selectedCategoryId == null &&
            widget.stagedTx.inferredType != 'Transfer')) {
      setState(() => _showValidationErrors = true);
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.selectionClick();
    final success = await ref
        .read(smartInboxActionProvider.notifier)
        .approveStagedTransaction(
          stagedTx: widget.stagedTx,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryName,
          categoryIcon: _selectedCategoryIcon,
          subCategory: _selectedSubCategory,
          bucketId: _selectedBucketId == -1 ? null : _selectedBucketId,
          bucketName: _selectedBucketName,
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
        );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actionState = ref.watch(smartInboxActionProvider);
    final rawAccounts = ref.watch(accountsStreamProvider).asData?.value ?? [];
    final rawCategories =
        ref.watch(categoriesStreamProvider).asData?.value ?? [];
    final isExpense = widget.stagedTx.inferredType == 'Expense';
    final amountColor = TransactionColors.getTypeColor(
      widget.stagedTx.inferredType,
      theme,
    );

    final selectedAcc = rawAccounts
        .where((a) => a.id == _selectedAccountId)
        .firstOrNull;
    final availableCategories = rawCategories
        .where((c) => c.type == widget.stagedTx.inferredType)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLg),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirm Transaction',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.stagedTx.inferredType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Amount Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: amountColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stagedTx.sourceName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CurrencyText(
                          amount: widget.stagedTx.extractedAmount,
                          sign: isExpense ? '- ' : '+ ',
                          amountStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Selection Fields
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: _showValidationErrors && _selectedAccountId == null
                      ? theme.colorScheme.error
                      : theme.dividerColor.withOpacity(0.5),
                ),
              ),
              tileColor: theme.colorScheme.surface,
              leading: Icon(
                Icons.account_balance_wallet_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              title: const Text(
                'Account',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                selectedAcc?.name ?? 'Select Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selectedAcc != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              onTap: () async {
                final names = rawAccounts
                    .where((a) => a.type != 'Loan')
                    .map((a) => a.name)
                    .toList();
                final res = await GlobalSelectionSheet.showSimple(
                  context: context,
                  title: 'Select Account',
                  items: names,
                  selectedValue: selectedAcc?.name ?? '',
                );
                if (res != null) {
                  final matched = rawAccounts.firstWhere((a) => a.name == res);
                  setState(() => _selectedAccountId = matched.id);
                }
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: _showValidationErrors && _selectedCategoryId == null
                      ? theme.colorScheme.error
                      : theme.dividerColor.withOpacity(0.5),
                ),
              ),
              tileColor: theme.colorScheme.surface,
              leading: Icon(
                Icons.category_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              title: const Text(
                'Category',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _selectedCategoryName ?? 'Select Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _selectedCategoryName != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              onTap: () async {
                final names = availableCategories.map((c) => c.name).toList();
                final res = await GlobalSelectionSheet.showSimple(
                  context: context,
                  title: 'Select Category',
                  items: names,
                  selectedValue: _selectedCategoryName ?? '',
                );
                if (res != null) {
                  final matched = availableCategories.firstWhere(
                    (c) => c.name == res,
                  );
                  setState(() {
                    _selectedCategoryId = matched.id;
                    _selectedCategoryName = matched.name;
                    _selectedCategoryIcon = matched.iconCode;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            ModernBoxyInput(
              controller: _notesCtrl,
              labelText: 'Transaction Note',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ModernBoxyButton(
                    onPressed: () => Navigator.pop(context),
                    label: 'Dismiss',
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ModernBoxyButton(
                    onPressed: _submit,
                    label: 'Confirm & Log',
                    isLoading: actionState.isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
