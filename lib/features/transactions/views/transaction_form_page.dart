import 'dart:convert';
import 'package:budgetr/core/models/transaction_category_model.dart';
import 'package:budgetr/features/transactions/services/transaction_service.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart' hide Column, Table;
import '../../../core/database/database_provider.dart' as db_prov;
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/components/docked_calculator_pad.dart';
import '../../../core/utils/bodmas_calculator.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../../core/components/currency_text.dart'; // <-- ADDED GLOBAL FORMATTER
import '../../../core/utils/location_helper.dart';
import '../../accounts/providers/account_provider.dart';
import '../../category_manager/providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class _BucketItem {
  final int id;
  final String name;
  _BucketItem(this.id, this.name);
}

final _formBudgetProvider = StreamProvider.family
    .autoDispose<MonthlyBudget?, DateTime>((ref, date) {
      final db = ref.watch(db_prov.databaseProvider);
      return (db.select(db.monthlyBudgets)..where(
            (t) => t.month.equals(date.month) & t.year.equals(date.year),
          ))
          .watchSingleOrNull();
    });

class TransactionFormPage extends ConsumerStatefulWidget {
  final TransactionWithDetails? existingTransaction;
  final String? preSelectedAccountId;
  final bool isClone;
  final bool isSplit;

  const TransactionFormPage({
    Key? key,
    this.existingTransaction,
    this.preSelectedAccountId,
    this.isClone = false,
    this.isSplit = false,
  }) : super(key: key);

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  int _typeIndex = 0;
  final List<String> _types = ['Expense', 'Income', 'Transfer'];
  String _expression = '';
  String _liveResult = '0.00';
  bool _isSpillover = false;
  bool _isSettlementVerified = false;
  late TextEditingController _amountController;
  late TextEditingController _notesCtrl;
  DateTime _selectedDateTime = DateTime.now();
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  String? _selectedSubCategory;
  int? _selectedBucketId;
  String? _historicalBucketName;
  bool _showValidationErrors = false;

  String? _locationName;
  double? _latitude;
  double? _longitude;
  bool _isFetchingLoc = false;

  late TextEditingController _loanPrinCtrl;
  late TextEditingController _loanIntCtrl;
  late TextEditingController _loanTaxCtrl;
  late TextEditingController _loanFeeCtrl;
  bool _markAsExpense = false;
  TextEditingController? _activeCalcController;

  bool get _isLoanRepayment {
    final sub = widget.existingTransaction?.transaction.subCategory;
    return sub == 'Loan Principal' ||
        sub == 'Loan Interest' ||
        sub == 'Tax on Interest' ||
        sub == 'Bank Charges on Loan';
  }

  bool _isToLoanMode() {
    if (_typeIndex != 2) return false;
    if (_selectedToAccountId == null || _selectedToAccountId == 'EXTERNAL')
      return false;
    final rawAccounts = ref.read(accountsStreamProvider).asData?.value ?? [];
    final toAcc = rawAccounts
        .where((a) => a.id == _selectedToAccountId)
        .firstOrNull;
    return toAcc?.type == 'Loan';
  }

  @override
  void initState() {
    super.initState();
    final txDetails = widget.existingTransaction;
    String initialAmount = '';
    if (txDetails != null && !widget.isSplit) {
      initialAmount = txDetails.transaction.amount.toStringAsFixed(2);
    }
    _amountController = TextEditingController(text: initialAmount);
    _expression = initialAmount;
    _liveResult = initialAmount.isEmpty ? '0.00' : initialAmount;

    _loanPrinCtrl = TextEditingController();
    _loanIntCtrl = TextEditingController();
    _loanTaxCtrl = TextEditingController();
    _loanFeeCtrl = TextEditingController();

    if (txDetails != null) {
      final tx = txDetails.transaction;
      _typeIndex = _types.indexOf(tx.type);
      _selectedDateTime = widget.isClone ? DateTime.now() : tx.date;
      _isSpillover = widget.isClone || widget.isSplit ? false : tx.isSpillover;
      _isSettlementVerified = widget.isClone || widget.isSplit
          ? false
          : tx.isSettlementVerified;
      _notesCtrl = TextEditingController(text: tx.notes ?? '');
      _selectedCategoryId = widget.isSplit ? null : tx.categoryId;
      _selectedSubCategory = widget.isSplit ? null : tx.subCategory;

      _locationName = tx.locationName;
      _latitude = tx.latitude;
      _longitude = tx.longitude;

      if (tx.type == 'Transfer') {
        if (tx.toAccountId == 'EXTERNAL_IN') {
          _selectedAccountId = 'EXTERNAL';
          _selectedToAccountId = tx.accountId;
        } else if (tx.toAccountId == 'EXTERNAL_OUT') {
          _selectedAccountId = tx.accountId;
          _selectedToAccountId = 'EXTERNAL';
        } else {
          _selectedAccountId = tx.accountId;
          _selectedToAccountId = tx.toAccountId;
        }
      } else {
        _selectedAccountId = tx.accountId;
      }

      _selectedBucketId = tx.bucketId ?? -1;
      _historicalBucketName = tx.bucketName ?? txDetails.bucket?.name;
    } else {
      _notesCtrl = TextEditingController();
      _selectedAccountId = widget.preSelectedAccountId;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _amountController.dispose();
    _loanPrinCtrl.dispose();
    _loanIntCtrl.dispose();
    _loanTaxCtrl.dispose();
    _loanFeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLoc = true);
    try {
      final locData = await LocationHelper.fetchCurrentLocation();
      if (locData != null) {
        setState(() {
          _locationName = locData['name'];
          _latitude = locData['latitude'];
          _longitude = locData['longitude'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not fetch location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isFetchingLoc = false);
    }
  }

  void _updateLoanTransferTotal() {
    final p =
        double.tryParse(
          BodmasCalculator.evaluate(
            _loanPrinCtrl.text.isEmpty ? '0' : _loanPrinCtrl.text,
          ),
        ) ??
        0.0;
    final i =
        double.tryParse(
          BodmasCalculator.evaluate(
            _loanIntCtrl.text.isEmpty ? '0' : _loanIntCtrl.text,
          ),
        ) ??
        0.0;
    final t =
        double.tryParse(
          BodmasCalculator.evaluate(
            _loanTaxCtrl.text.isEmpty ? '0' : _loanTaxCtrl.text,
          ),
        ) ??
        0.0;
    final f =
        double.tryParse(
          BodmasCalculator.evaluate(
            _loanFeeCtrl.text.isEmpty ? '0' : _loanFeeCtrl.text,
          ),
        ) ??
        0.0;
    final total = p + i + t + f;
    _liveResult = total.toStringAsFixed(2);
  }

  void _onCalcKeyPress(String key) {
    setState(() {
      TextEditingController targetCtrl =
          _activeCalcController ?? _amountController;

      int cursorPosition = targetCtrl.selection.baseOffset;
      if (cursorPosition < 0) cursorPosition = targetCtrl.text.length;
      String currentText = targetCtrl.text;

      if (key == 'C') {
        targetCtrl.clear();
        if (!_isToLoanMode()) {
          _expression = '';
          _liveResult = '0.00';
        }
      } else if (key == '⌫') {
        if (cursorPosition > 0) {
          final newText =
              currentText.substring(0, cursorPosition - 1) +
              currentText.substring(cursorPosition);
          targetCtrl.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursorPosition - 1),
          );
        }
      } else if (key == '=') {
        String rawResult = BodmasCalculator.evaluate(targetCtrl.text);
        double? parsed = double.tryParse(rawResult);
        if (parsed != null && !parsed.isNaN && !parsed.isInfinite) {
          targetCtrl.text = parsed.toStringAsFixed(2);
          targetCtrl.selection = TextSelection.collapsed(
            offset: targetCtrl.text.length,
          );
        }
      } else {
        final isOperator = ['+', '-', '×', '÷'].contains(key);
        if (isOperator && cursorPosition > 0) {
          final prevChar = currentText[cursorPosition - 1];
          if (['+', '-', '×', '÷'].contains(prevChar)) {
            final newText =
                currentText.substring(0, cursorPosition - 1) +
                key +
                currentText.substring(cursorPosition);
            targetCtrl.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: cursorPosition),
            );
          } else {
            if (currentText.length < 25) {
              final newText =
                  currentText.substring(0, cursorPosition) +
                  key +
                  currentText.substring(cursorPosition);
              targetCtrl.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: cursorPosition + 1),
              );
            }
          }
        } else {
          if (currentText.length < 25) {
            final newText =
                currentText.substring(0, cursorPosition) +
                key +
                currentText.substring(cursorPosition);
            targetCtrl.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: cursorPosition + 1),
            );
          }
        }
      }

      if (_isToLoanMode()) {
        _updateLoanTransferTotal();
      } else {
        _expression = targetCtrl.text;
        String rawResult = BodmasCalculator.evaluate(_expression);
        double? parsed = double.tryParse(rawResult);

        if (parsed != null) {
          if (parsed.isNaN || parsed.isInfinite) {
            _liveResult = '0.00';
          } else if (parsed >= 1000000000000) {
            _liveResult = '999999999999.99';
            if (key != '⌫') {
              targetCtrl.text = '999999999999.99';
              targetCtrl.selection = TextSelection.collapsed(
                offset: targetCtrl.text.length,
              );
              _expression = targetCtrl.text;
            }
          } else if (parsed <= -1000000000000) {
            _liveResult = '-999999999999.99';
            if (key != '⌫') {
              targetCtrl.text = '-999999999999.99';
              targetCtrl.selection = TextSelection.collapsed(
                offset: targetCtrl.text.length,
              );
              _expression = targetCtrl.text;
            }
          } else {
            _liveResult = parsed.toStringAsFixed(2);
          }
        } else {
          _liveResult = rawResult.isEmpty ? '0.00' : rawResult;
        }
      }
    });
  }

  String _formatDateTime(DateTime d) {
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}, $time';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (time != null)
        setState(
          () => _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
        );
    }
  }

  List<Widget> _buildAccountGroup(
    BuildContext ctx,
    List<Account> accounts,
    String title,
    IconData iconData,
    String? selectedId,
    ThemeData theme,
  ) {
    if (accounts.isEmpty) return [];

    List<Widget> children = [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    ];

    for (int i = 0; i < accounts.length; i++) {
      final acc = accounts[i];
      final isLast = i == accounts.length - 1;

      children.add(
        Column(
          children: [
            _buildAccountTile(
              ctx,
              acc.id,
              acc.name,
              acc.providerName,
              iconData,
              selectedId,
              theme,
            ),
            if (!isLast)
              Divider(
                height: 1,
                color: theme.dividerColor.withOpacity(0.2),
                indent: 20,
                endIndent: 20,
              ),
          ],
        ),
      );
    }
    return children;
  }

  Future<void> _pickAccount(bool isToAccount, List<Account> rawAccounts) async {
    final theme = Theme.of(context);

    List<Account> availableAccounts = List.from(rawAccounts);

    if (!isToAccount) {
      availableAccounts = availableAccounts
          .where((a) => a.type != 'Loan')
          .toList();
    }

    if (isToAccount) {
      if (_selectedAccountId != null && _selectedAccountId != 'EXTERNAL') {
        availableAccounts = availableAccounts
            .where((a) => a.id != _selectedAccountId)
            .toList();
      }
    } else {
      if (_typeIndex == 2 &&
          _selectedToAccountId != null &&
          _selectedToAccountId != 'EXTERNAL') {
        availableAccounts = availableAccounts
            .where((a) => a.id != _selectedToAccountId)
            .toList();
      }
    }

    final assets = availableAccounts
        .where((a) => a.type != 'Credit Cards' && a.type != 'Loan')
        .toList();
    final creditCards = availableAccounts
        .where((a) => a.type == 'Credit Cards')
        .toList();
    final loans = availableAccounts.where((a) => a.type == 'Loan').toList();

    final selectedId = isToAccount ? _selectedToAccountId : _selectedAccountId;

    bool showExternal = _typeIndex == 2;
    if (isToAccount && _selectedAccountId == 'EXTERNAL') showExternal = false;
    if (!isToAccount && _selectedToAccountId == 'EXTERNAL')
      showExternal = false;

    final selected = await GlobalSelectionSheet.show<String>(
      context: context,
      title: isToAccount ? 'Select Destination' : 'Select Account',
      builder: (ctx, scrollController) {
        return ListView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          children: [
            ..._buildAccountGroup(
              ctx,
              assets,
              'ASSETS',
              Icons.account_balance_wallet_rounded,
              selectedId,
              theme,
            ),

            if (assets.isNotEmpty &&
                (creditCards.isNotEmpty || loans.isNotEmpty || showExternal))
              Divider(
                height: 12,
                thickness: 4,
                color: theme.dividerColor.withOpacity(0.05),
              ),

            ..._buildAccountGroup(
              ctx,
              creditCards,
              'CREDIT CARDS',
              Icons.credit_card_rounded,
              selectedId,
              theme,
            ),

            if (creditCards.isNotEmpty && (loans.isNotEmpty || showExternal))
              Divider(
                height: 12,
                thickness: 4,
                color: theme.dividerColor.withOpacity(0.05),
              ),

            ..._buildAccountGroup(
              ctx,
              loans,
              'LOANS',
              Icons.account_balance_rounded,
              selectedId,
              theme,
            ),

            if (loans.isNotEmpty && showExternal)
              Divider(
                height: 12,
                thickness: 4,
                color: theme.dividerColor.withOpacity(0.05),
              ),

            if (showExternal) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  'EXTERNAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              _buildAccountTile(
                ctx,
                'EXTERNAL',
                'External Account',
                'Outside of Budgetr',
                Icons.sync_alt_rounded,
                selectedId,
                theme,
              ),
            ],
          ],
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        if (isToAccount) {
          _selectedToAccountId = selected;
          if (_isToLoanMode()) {
            _activeCalcController = _loanPrinCtrl;
            _updateLoanTransferTotal();
          } else {
            _activeCalcController = _amountController;
          }
        } else {
          _selectedAccountId = selected;
        }
      });
    }
  }

  Widget _buildAccountTile(
    BuildContext ctx,
    String id,
    String name,
    String providerName,
    IconData icon,
    String? selectedId,
    ThemeData theme,
  ) {
    final isSelected = id == selectedId;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(
        icon,
        size: 20,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        providerName,
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(ctx, id);
      },
    );
  }

  Future<void> _pickCategory(
    List<TransactionCategoryModel> activeCategories,
    TransactionCategoryModel? selectedCatMatch,
  ) async {
    final items = activeCategories.map((c) => c.name).toList();
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Category',
      items: items,
      selectedValue: selectedCatMatch?.name ?? '',
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedCategoryId = activeCategories
            .firstWhere((c) => c.name == selected)
            .id;
        _selectedSubCategory = null;
      });
    }
  }

  Future<void> _pickSubCategory(List<String> activeSubCategories) async {
    if (activeSubCategories.isEmpty) return;
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Subcategory',
      items: activeSubCategories,
      selectedValue: _selectedSubCategory ?? '',
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedSubCategory = selected;
      });
    }
  }

  Future<void> _pickBucket(
    List<_BucketItem> bucketItems,
    _BucketItem? selectedBucketMatch,
  ) async {
    final items = bucketItems.map((b) => b.name).toList();
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Assign to Bucket',
      items: items,
      selectedValue: selectedBucketMatch?.name ?? '',
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedBucketId = bucketItems
            .firstWhere((b) => b.name == selected)
            .id;
      });
    }
  }

  void _openNotesEditor(
    TransactionCategoryModel? selectedCatMatch,
    List<TransactionWithDetails> allTxs,
  ) {
    final pastNotes = allTxs.reversed
        .map((txData) => txData.transaction.notes)
        .where((n) => n != null && n.trim().isNotEmpty)
        .map((n) => n!.trim())
        .toSet()
        .toList();

    List<String> getSmartSuggestions() {
      final cat = selectedCatMatch?.name.toLowerCase() ?? '';

      if (_typeIndex == 0) {
        if (cat.contains('food') ||
            cat.contains('dining') ||
            cat.contains('restaurant')) {
          return [
            'Breakfast',
            'Lunch',
            'Dinner',
            'Coffee',
            'Snacks',
            'Groceries',
            'Swiggy',
            'Zomato',
            'Cafe',
            'Drinks',
            'Street Food',
            'Bakery',
            'Pub',
            'Fast Food',
          ];
        }
        if (cat.contains('transport') ||
            cat.contains('auto') ||
            cat.contains('travel')) {
          return [
            'Uber',
            'Taxi',
            'Metro',
            'Fuel',
            'Parking',
            'Bus Ticket',
            'Train Ticket',
            'Flight',
            'Toll',
            'Car Wash',
            'Cab',
            'Bike Service',
            'Rickshaw',
          ];
        }
        if (cat.contains('shopping') || cat.contains('retail')) {
          return [
            'Clothes',
            'Electronics',
            'Amazon',
            'Gifts',
            'Flipkart',
            'Shoes',
            'Accessories',
            'Myntra',
            'Gadgets',
            'Home Decor',
            'Cosmetics',
            'Books',
          ];
        }
        if (cat.contains('bills') || cat.contains('utility')) {
          return [
            'Electricity',
            'Water',
            'Internet',
            'Mobile Recharge',
            'Gas',
            'Maintenance',
            'Netflix',
            'Amazon Prime',
            'Spotify',
            'Broadband',
            'DTH',
            'Cable',
          ];
        }
        if (cat.contains('health') || cat.contains('medical')) {
          return [
            'Pharmacy',
            'Doctor Consultation',
            'Medicines',
            'Therapy',
            'Hospital',
            'Checkup',
            'Dental',
            'Lab Test',
            'Vitamins',
            'Gym',
            'Fitness',
          ];
        }
        if (cat.contains('entertainment') || cat.contains('fun')) {
          return [
            'Movie',
            'Concert',
            'Event',
            'Games',
            'Bowling',
            'Theme Park',
            'Club',
            'Party',
            'Exhibition',
          ];
        }
        if (cat.contains('education') || cat.contains('learning')) {
          return [
            'Course Fee',
            'Books',
            'Stationery',
            'Tuition',
            'Certification',
            'Exam Fee',
            'School Supplies',
          ];
        }
        if (cat.contains('home') || cat.contains('rent')) {
          return [
            'House Rent',
            'Maid',
            'Cook',
            'Plumber',
            'Electrician',
            'Furniture',
            'Pest Control',
            'Hardware',
          ];
        }
        return [
          'Groceries',
          'Dining',
          'Transport',
          'Shopping',
          'Miscellaneous',
          'Subscription',
          'Service',
          'Supplies',
          'Fee',
        ];
      } else if (_typeIndex == 1) {
        if (cat.contains('salary'))
          return [
            'Monthly Salary',
            'Bonus',
            'Appraisal',
            'Incentive',
            'Overtime',
            'Arrears',
          ];
        if (cat.contains('business') || cat.contains('freelance'))
          return [
            'Client Payment',
            'Project Advance',
            'Consulting',
            'Contract',
            'Sales',
            'Service Fee',
          ];
        if (cat.contains('investment') || cat.contains('return'))
          return [
            'Dividends',
            'Stock Sale',
            'Mutual Fund',
            'FD Interest',
            'Crypto',
            'Rent Income',
          ];
        return [
          'Salary',
          'Refund',
          'Cashback',
          'Interest',
          'Gift',
          'Reimbursement',
          'Pocket Money',
          'Allowance',
        ];
      } else {
        return [
          'Self Transfer',
          'Credit Card Bill',
          'Investment Deposit',
          'Emergency Savings',
          'Loan EMI',
          'Wallet Top-up',
          'Splitwise Settlement',
          'Mutual Fund SIP',
          'Stock Broker',
          'Friend Repayment',
        ];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _notesCtrl.text.trim().toLowerCase();
            List<String> suggestions = pastNotes
                .where((n) => n.toLowerCase().contains(query))
                .toList();

            if (suggestions.isEmpty) {
              suggestions = getSmartSuggestions()
                  .where((n) => n.toLowerCase().contains(query))
                  .toList();
            }

            suggestions = suggestions.take(12).toList();
            final theme = Theme.of(context);

            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
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
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Transaction Note',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${_notesCtrl.text.length}/140',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesCtrl,
                      autofocus: true,
                      maxLines: 3,
                      maxLength: 140,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      textInputAction: TextInputAction.done,
                      onChanged: (val) => setModalState(() {}),
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.dividerColor.withOpacity(0.5),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                    ),
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'SUGGESTIONS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: suggestions.map((suggestion) {
                          return ActionChip(
                            label: Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            backgroundColor: theme
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            side: BorderSide(
                              color: theme.dividerColor.withOpacity(0.3),
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _notesCtrl.text = suggestion;
                              _notesCtrl.selection = TextSelection.collapsed(
                                offset: suggestion.length,
                              );
                              setState(() {});
                              Navigator.pop(ctx);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Save Note',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _resolveBucketName(List<_BucketItem> items, int? selectedId) {
    if (selectedId == null || selectedId == -1) return null;
    final match = items.where((b) => b.id == selectedId).firstOrNull;
    return match?.name ?? _historicalBucketName;
  }

  Future<void> _submit(List<_BucketItem> activeBucketItems) async {
    if (_isToLoanMode()) {
      final p =
          double.tryParse(
            BodmasCalculator.evaluate(
              _loanPrinCtrl.text.isEmpty ? '0' : _loanPrinCtrl.text,
            ),
          ) ??
          0.0;
      final i =
          double.tryParse(
            BodmasCalculator.evaluate(
              _loanIntCtrl.text.isEmpty ? '0' : _loanIntCtrl.text,
            ),
          ) ??
          0.0;
      final t =
          double.tryParse(
            BodmasCalculator.evaluate(
              _loanTaxCtrl.text.isEmpty ? '0' : _loanTaxCtrl.text,
            ),
          ) ??
          0.0;
      final f =
          double.tryParse(
            BodmasCalculator.evaluate(
              _loanFeeCtrl.text.isEmpty ? '0' : _loanFeeCtrl.text,
            ),
          ) ??
          0.0;

      final String? finalBucketName = _resolveBucketName(
        activeBucketItems,
        _selectedBucketId,
      );

      if ((p + i + t + f) <= 0 ||
          _selectedAccountId == null ||
          _selectedToAccountId == null ||
          (_markAsExpense && _selectedBucketId == null)) {
        setState(() => _showValidationErrors = true);
        HapticFeedback.heavyImpact();
        return;
      }

      final success = await ref
          .read(transactionActionProvider.notifier)
          .logLoanTransfer(
            fromAccountId: _selectedAccountId!,
            loanAccountId: _selectedToAccountId!,
            principal: p,
            interest: i,
            tax: t,
            bankCharges: f,
            date: _selectedDateTime,
            markAsExpense: _markAsExpense,
            bucketId: _selectedBucketId == -1 ? null : _selectedBucketId,
            bucketName: finalBucketName,
            notes: _notesCtrl.text.trim().isNotEmpty
                ? _notesCtrl.text.trim()
                : null,
            isSpillover: _isSpillover,
            isSettlementVerified: _isSettlementVerified,
            locationName: _locationName,
            latitude: _latitude,
            longitude: _longitude,
          );

      if (success && mounted) Navigator.pop(context);
      return;
    }

    final amount = double.tryParse(_liveResult) ?? 0.0;
    final isExpense = _typeIndex == 0;
    final isIncome = _typeIndex == 1;
    final isTransfer = _typeIndex == 2;
    final isLoanRep = _isLoanRepayment;

    final hasDanglingOperator =
        _expression.isNotEmpty &&
        ['+', '-', '×', '÷'].contains(_expression[_expression.length - 1]);
    final origAmount = widget.existingTransaction?.transaction.amount ?? 0.0;
    final isOverSplit = widget.isSplit && amount >= origAmount;

    if (amount <= 0 ||
        hasDanglingOperator ||
        isOverSplit ||
        _selectedAccountId == null ||
        (isTransfer && _selectedToAccountId == null) ||
        (isTransfer && _selectedAccountId == _selectedToAccountId) ||
        (!isTransfer && _selectedCategoryId == null && !isLoanRep) ||
        (isExpense && _selectedBucketId == null && !isLoanRep)) {
      setState(() => _showValidationErrors = true);
      HapticFeedback.heavyImpact();
      return;
    }

    final rawAccounts = ref.read(accountsStreamProvider).asData?.value ?? [];
    final rawCategories =
        ref.read(categoriesStreamProvider).asData?.value ?? [];

    Account? targetCC;
    if (isTransfer &&
        _selectedToAccountId != null &&
        _selectedToAccountId != 'EXTERNAL') {
      final rawTarget = rawAccounts
          .where((a) => a.id == _selectedToAccountId)
          .firstOrNull;
      if (rawTarget?.type == 'Credit Cards') targetCC = rawTarget;
    } else if (isIncome &&
        _selectedAccountId != null &&
        _selectedAccountId != 'EXTERNAL') {
      final rawTarget = rawAccounts
          .where((a) => a.id == _selectedAccountId)
          .firstOrNull;
      if (rawTarget?.type == 'Credit Cards') targetCC = rawTarget;
    }

    String? finalCategoryId = _selectedCategoryId;
    String? finalSubCategory = _selectedSubCategory;
    String? finalNotes = _notesCtrl.text.trim();
    String? finalBucketName = _resolveBucketName(
      activeBucketItems,
      _selectedBucketId,
    );

    if (targetCC != null) {
      final bDay = targetCC.billDate ?? 15;
      final dDay = targetCC.dueDate ?? 5;
      final txDate = _selectedDateTime;

      DateTime lastBillDate = DateTime(txDate.year, txDate.month, bDay);
      if (txDate.day < bDay) {
        lastBillDate = DateTime(txDate.year, txDate.month - 1, bDay);
      }

      DateTime dueDate = DateTime(
        lastBillDate.year,
        lastBillDate.month + 1,
        dDay,
      );
      if (dDay > bDay) {
        dueDate = DateTime(lastBillDate.year, lastBillDate.month, dDay);
      }

      bool inWindow =
          txDate.isAfter(lastBillDate) &&
          txDate.isBefore(dueDate.add(const Duration(days: 1)));
      final selectedCatName = rawCategories
          .where((c) => c.id == _selectedCategoryId)
          .firstOrNull
          ?.name;

      if (inWindow && selectedCatName != 'Repayment') {
        final isRepayment = await ConfirmationBottomSheet.show(
          context,
          title: 'Credit Card Repayment?',
          description:
              'This transaction is between the last bill date and the due date. Is this a repayment for the previous statement?',
          confirmText: 'YES, REPAYMENT',
          cancelText: 'NO, NORMAL',
          onConfirm: () {},
        );
        if (isRepayment == true) {
          final repaymentCat = rawCategories
              .where((c) => c.name == 'Repayment' && c.type == 'Income')
              .firstOrNull;
          if (repaymentCat != null) {
            finalCategoryId = repaymentCat.id;
            finalSubCategory = isTransfer
                ? 'Credit Card Bill'
                : 'Account Adjustments';
            finalNotes = finalNotes!.isEmpty
                ? 'Auto-tagged as Bill Repayment'
                : '$finalNotes (Bill Repayment)';
          }
        }
      }
    }

    if (widget.isSplit) {
      final success = await ref
          .read(transactionActionProvider.notifier)
          .splitTransaction(
            originalTxId: widget.existingTransaction!.transaction.id,
            splitAmount: amount,
            type: _types[_typeIndex],
            date: _selectedDateTime,
            accountId: _selectedAccountId!,
            toAccountId: _selectedToAccountId,
            categoryId: finalCategoryId,
            subCategory: finalSubCategory,
            bucketId: _selectedBucketId == -1 ? null : _selectedBucketId,
            bucketName: finalBucketName,
            notes: finalNotes,
            isSpillover: _isSpillover,
            isSettlementVerified: _isSettlementVerified,
            locationName: _locationName,
            latitude: _latitude,
            longitude: _longitude,
          );
      if (success && mounted) Navigator.pop(context);
      return;
    }

    final String? safeExistingId =
        (widget.existingTransaction != null && !widget.isClone)
        ? widget.existingTransaction!.transaction.id
        : null;

    final success = await ref
        .read(transactionActionProvider.notifier)
        .saveTransaction(
          existingId: safeExistingId,
          type: _types[_typeIndex],
          amount: amount,
          date: _selectedDateTime,
          accountId: _selectedAccountId!,
          toAccountId: _selectedToAccountId,
          categoryId: finalCategoryId,
          subCategory: finalSubCategory,
          bucketId: _selectedBucketId == -1 ? null : _selectedBucketId,
          bucketName: finalBucketName,
          notes: finalNotes,
          isSpillover: _isSpillover,
          isSettlementVerified: _isSettlementVerified,
          locationName: _locationName,
          latitude: _latitude,
          longitude: _longitude,
        );

    if (success && mounted) Navigator.pop(context);
  }

  // --- SMART CELL FORMATTER UTILITY ---
  String _formatCell(String text) {
    if (text.isEmpty) return '0.00';
    final parsed = double.tryParse(text);
    if (parsed != null) return CurrencyFormatter.format(parsed);
    return text;
  }

  Widget _buildTableCell(
    String label,
    String? value,
    IconData icon,
    VoidCallback? onTap,
    bool isError, {
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final hasValue =
        value != null && value.isNotEmpty && value != '0.00' && value != '0';

    return Material(
      color: isActive
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isError
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasValue ? value : (onTap != null ? 'Select' : ''),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasValue ? FontWeight.w800 : FontWeight.w500,
                  color: isError
                      ? theme.colorScheme.error
                      : (hasValue
                            ? (isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface)
                            : theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              )),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCell(
    String label,
    bool value,
    IconData icon,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Transform.scale(
                  scale: 0.85,
                  alignment: Alignment.centerLeft,
                  child: Switch(
                    value: value,
                    activeColor: theme.colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      onChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStandardCells(
    ThemeData theme,
    List<Account> rawAccounts,
    String? displayAccName,
    String? displayToAccName,
    TransactionCategoryModel? selectedCatMatch,
    List<TransactionCategoryModel> activeCategories,
    List<String> activeSubCategories,
    List<_BucketItem> bucketItems,
    _BucketItem? selectedBucketMatch,
    List<TransactionWithDetails> allTxs,
  ) {
    final List<Widget> cells = [];
    final isExpense = _typeIndex == 0;
    final isIncome = _typeIndex == 1;
    final isTransfer = _typeIndex == 2;
    final isLoanRep = _isLoanRepayment;

    cells.add(
      _buildTableCell(
        'DATE & TIME',
        _formatDateTime(_selectedDateTime),
        Icons.calendar_today_rounded,
        _pickDateTime,
        false,
      ),
    );
    cells.add(
      _buildTableCell(
        isTransfer ? 'FROM ACCOUNT' : 'ACCOUNT',
        displayAccName,
        Icons.account_balance_wallet_rounded,
        isLoanRep ? null : () => _pickAccount(false, rawAccounts),
        _showValidationErrors && _selectedAccountId == null,
      ),
    );

    if (isTransfer) {
      cells.add(
        _buildTableCell(
          'TO ACCOUNT',
          displayToAccName,
          Icons.sync_alt_rounded,
          isLoanRep ? null : () => _pickAccount(true, rawAccounts),
          _showValidationErrors && _selectedToAccountId == null,
        ),
      );
    } else {
      cells.add(
        _buildTableCell(
          'CATEGORY',
          isLoanRep ? 'Loan Repayment' : selectedCatMatch?.name,
          Icons.category_rounded,
          isLoanRep
              ? null
              : () => _pickCategory(activeCategories, selectedCatMatch),
          _showValidationErrors && _selectedCategoryId == null && !isLoanRep,
        ),
      );
      if (activeSubCategories.isNotEmpty ||
          _selectedSubCategory != null ||
          isLoanRep) {
        cells.add(
          _buildTableCell(
            'SUBCATEGORY',
            _selectedSubCategory,
            Icons.subdirectory_arrow_right_rounded,
            isLoanRep ? null : () => _pickSubCategory(activeSubCategories),
            false,
          ),
        );
      }
      if (!isIncome) {
        cells.add(
          _buildTableCell(
            'BUDGET BUCKET',
            isLoanRep ? 'Out of Bucket' : selectedBucketMatch?.name,
            Icons.donut_small_rounded,
            isLoanRep
                ? null
                : () => _pickBucket(bucketItems, selectedBucketMatch),
            _showValidationErrors &&
                isExpense &&
                _selectedBucketId == null &&
                !isLoanRep,
          ),
        );
      }
    }

    cells.add(
      _buildTableCell(
        'NOTES',
        _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        Icons.notes_rounded,
        () => _openNotesEditor(selectedCatMatch, allTxs),
        false,
      ),
    );
    cells.add(
      _buildTableCell(
        'LOCATION',
        _isFetchingLoc ? 'Locating...' : _locationName,
        Icons.pin_drop_rounded,
        _fetchLocation,
        false,
      ),
    );

    if (cells.length % 2 != 0) cells.add(const SizedBox.shrink());
    return cells;
  }

  List<Widget> _buildLoanTransferCells(
    ThemeData theme,
    List<Account> rawAccounts,
    String? displayAccName,
    String? displayToAccName,
    TransactionCategoryModel? selectedCatMatch,
    List<_BucketItem> bucketItems,
    _BucketItem? selectedBucketMatch,
    List<TransactionWithDetails> allTxs,
  ) {
    final List<Widget> cells = [];

    cells.add(
      _buildTableCell(
        'DATE & TIME',
        _formatDateTime(_selectedDateTime),
        Icons.calendar_today_rounded,
        _pickDateTime,
        false,
      ),
    );
    cells.add(
      _buildTableCell(
        'FROM ACCOUNT',
        displayAccName,
        Icons.account_balance_wallet_rounded,
        () => _pickAccount(false, rawAccounts),
        _showValidationErrors && _selectedAccountId == null,
      ),
    );
    cells.add(
      _buildTableCell(
        'TO LOAN ACCOUNT',
        displayToAccName,
        Icons.account_balance_rounded,
        () => _pickAccount(true, rawAccounts),
        _showValidationErrors && _selectedToAccountId == null,
      ),
    );

    cells.add(
      _buildTableCell(
        'PRINCIPAL (₹)',
        _formatCell(_loanPrinCtrl.text),
        Icons.payments_rounded,
        () => setState(() => _activeCalcController = _loanPrinCtrl),
        false,
        isActive: _activeCalcController == _loanPrinCtrl,
      ),
    );
    cells.add(
      _buildTableCell(
        'INTEREST (₹)',
        _formatCell(_loanIntCtrl.text),
        Icons.percent_rounded,
        () => setState(() => _activeCalcController = _loanIntCtrl),
        false,
        isActive: _activeCalcController == _loanIntCtrl,
      ),
    );
    cells.add(
      _buildTableCell(
        'TAX (₹)',
        _formatCell(_loanTaxCtrl.text),
        Icons.account_balance_rounded,
        () => setState(() => _activeCalcController = _loanTaxCtrl),
        false,
        isActive: _activeCalcController == _loanTaxCtrl,
      ),
    );
    cells.add(
      _buildTableCell(
        'BANK CHARGES (₹)',
        _formatCell(_loanFeeCtrl.text),
        Icons.receipt_long_rounded,
        () => setState(() => _activeCalcController = _loanFeeCtrl),
        false,
        isActive: _activeCalcController == _loanFeeCtrl,
      ),
    );

    cells.add(
      _buildToggleCell(
        'RECORD AS EXPENSE',
        _markAsExpense,
        Icons.receipt_long_rounded,
        (val) => setState(() => _markAsExpense = val),
      ),
    );

    if (_markAsExpense) {
      cells.add(
        _buildTableCell(
          'BUDGET BUCKET',
          selectedBucketMatch?.name,
          Icons.donut_small_rounded,
          () => _pickBucket(bucketItems, selectedBucketMatch),
          _showValidationErrors && _selectedBucketId == null,
        ),
      );
    }

    cells.add(
      _buildTableCell(
        'NOTES',
        _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        Icons.notes_rounded,
        () => _openNotesEditor(selectedCatMatch, allTxs),
        false,
      ),
    );
    cells.add(
      _buildTableCell(
        'LOCATION',
        _isFetchingLoc ? 'Locating...' : _locationName,
        Icons.pin_drop_rounded,
        _fetchLocation,
        false,
      ),
    );

    if (cells.length % 2 != 0) cells.add(const SizedBox.shrink());
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isExpense = _typeIndex == 0;
    final isLoanRep = _isLoanRepayment;
    final isToLoan = _isToLoanMode();

    final txColor = TransactionColors.getTypeColor(_types[_typeIndex], theme);
    final amountVal = double.tryParse(_liveResult) ?? 0.0;
    final origAmount = widget.existingTransaction?.transaction.amount ?? 0.0;
    final hasDanglingOperator =
        _expression.isNotEmpty &&
        ['+', '-', '×', '÷'].contains(_expression[_expression.length - 1]);
    final isOverSplit = widget.isSplit && amountVal >= origAmount;

    final hasAmountError =
        _showValidationErrors &&
        (amountVal <= 0 || hasDanglingOperator || isOverSplit);
    final displayAmountColor = hasAmountError
        ? theme.colorScheme.error
        : txColor;

    String errorMsg = 'Amount must be greater than 0';
    if (hasDanglingOperator) errorMsg = 'Incomplete mathematical expression';
    if (isOverSplit)
      // --- FORMATTED SPLITTING STRING ---
      errorMsg =
          'Split amount must be less than original (₹${CurrencyFormatter.format(origAmount)})';

    final rawAccounts = ref.watch(accountsStreamProvider).asData?.value ?? [];
    final rawCategories =
        ref.watch(categoriesStreamProvider).asData?.value ?? [];

    final allTxs = ref.watch(allTransactionsProvider).asData?.value ?? [];

    final budgetDate = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
    );
    final budgetAsync = ref.watch(_formBudgetProvider(budgetDate));
    final List<_BucketItem> bucketItems = [];
    final activeBudget = budgetAsync.asData?.value;

    bool isBudgetLocked = activeBudget == null || activeBudget.isClosed;
    String lockedReason = activeBudget == null
        ? 'No active budget exists for this month.'
        : 'This month\'s budget is permanently closed.';

    final bool isEditingExisting =
        widget.existingTransaction != null &&
        !widget.isClone &&
        !widget.isSplit;

    if (isBudgetLocked) {
      if (isEditingExisting &&
          _selectedBucketId != null &&
          _selectedBucketId != -1) {
        bucketItems.add(
          _BucketItem(_selectedBucketId!, _historicalBucketName ?? ''),
        );
      } else {
        if (_selectedBucketId != null && _selectedBucketId != -1) {
          _selectedBucketId = null;
        }
      }
      bucketItems.add(_BucketItem(-1, 'Out of Bucket'));
    } else {
      if (activeBudget.bucketsSnapshot != null) {
        try {
          final List<dynamic> decoded = jsonDecode(
            activeBudget.bucketsSnapshot!,
          );
          for (var b in decoded) {
            bucketItems.add(_BucketItem(b['id'] as int, b['name'] as String));
          }
        } catch (e) {}
      }
      if (isEditingExisting &&
          _selectedBucketId != null &&
          _selectedBucketId != -1) {
        if (!bucketItems.any((b) => b.id == _selectedBucketId)) {
          String displayLabel = _historicalBucketName ?? '';
          if (bucketItems.any((b) => b.name == displayLabel))
            displayLabel = '$displayLabel (Legacy)';
          bucketItems.add(_BucketItem(_selectedBucketId!, displayLabel));
        }
      } else {
        if (_selectedBucketId != null && _selectedBucketId != -1) {
          if (!bucketItems.any((b) => b.id == _selectedBucketId)) {
            _selectedBucketId = null;
          }
        }
      }
      bucketItems.add(_BucketItem(-1, 'Out of Bucket'));
    }

    final activeCategories = rawCategories
        .where((c) => c.type == _types[_typeIndex])
        .toList();
    final selectedCatMatch = rawCategories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;
    final activeSubCategories = selectedCatMatch?.subCategories ?? [];

    final selectedAccMatch = rawAccounts
        .where((a) => a.id == _selectedAccountId)
        .firstOrNull;
    final selectedToAccMatch = rawAccounts
        .where((a) => a.id == _selectedToAccountId)
        .firstOrNull;

    final displayAccName = _selectedAccountId == 'EXTERNAL'
        ? 'External Account'
        : selectedAccMatch?.name;
    final displayToAccName = _selectedToAccountId == 'EXTERNAL'
        ? 'External Account'
        : selectedToAccMatch?.name;

    final selectedBucketMatch = bucketItems
        .where((b) => b.id == _selectedBucketId)
        .firstOrNull;

    final List<Widget> cells = isToLoan
        ? _buildLoanTransferCells(
            theme,
            rawAccounts,
            displayAccName,
            displayToAccName,
            selectedCatMatch,
            bucketItems,
            selectedBucketMatch,
            allTxs,
          )
        : _buildStandardCells(
            theme,
            rawAccounts,
            displayAccName,
            displayToAccName,
            selectedCatMatch,
            activeCategories,
            activeSubCategories,
            bucketItems,
            selectedBucketMatch,
            allTxs,
          );

    List<TableRow> tableRows = [];
    for (int i = 0; i < cells.length; i += 2) {
      tableRows.add(TableRow(children: [cells[i], cells[i + 1]]));
    }

    String appBarTitle = 'New Log';
    if (widget.existingTransaction != null) {
      if (widget.isClone)
        appBarTitle = 'Clone Log';
      else if (widget.isSplit)
        appBarTitle = 'Split Log';
      else
        appBarTitle = 'Edit Log';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: ModernAppBar(
        title: appBarTitle,
        subtitle: 'TRANSACTION',
        leadingIcon: Icons.close_rounded,
        onLeadingPressed: () => Navigator.pop(context),
        trailingIcon: Icons.done_all_rounded,
        onTrailingPressed: () => _submit(bucketItems),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 60,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: AbsorbPointer(
                      absorbing: isLoanRep,
                      child: Opacity(
                        opacity: isLoanRep ? 0.6 : 1.0,
                        child: ModernBoxyToggle(
                          labels: _types,
                          selectedIndex: _typeIndex,
                          onSelected: (index) => setState(() {
                            final oldIndex = _typeIndex;
                            _typeIndex = index;
                            _selectedCategoryId = null;
                            _selectedSubCategory = null;
                            if (index == 1) _selectedBucketId = null;
                            if (oldIndex == 2 && index != 2) {
                              _selectedAccountId = null;
                              _selectedToAccountId = null;
                            } else if (index != 2 &&
                                _selectedAccountId == 'EXTERNAL') {
                              _selectedAccountId = null;
                            }

                            if (_isToLoanMode()) {
                              _activeCalcController = _loanPrinCtrl;
                              _updateLoanTransferTotal();
                            } else {
                              _activeCalcController = _amountController;
                            }
                          }),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: isToLoan ? 2 : 3,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isSplit)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                // --- FORMATTED SPLITTING STRING ---
                                child: Text(
                                  'SPLITTING FROM ₹${CurrencyFormatter.format(origAmount)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),

                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 250),
                              crossFadeState: isToLoan
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '₹ ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium!
                                          .copyWith(
                                            color: displayAmountColor
                                                .withOpacity(0.7),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    IntrinsicWidth(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                        ),
                                        child: TextField(
                                          controller: _amountController,
                                          readOnly: true,
                                          showCursor: true,
                                          autofocus: true,
                                          cursorColor: displayAmountColor,
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge!
                                              .copyWith(
                                                color: displayAmountColor,
                                              ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            hintText: '0.00',
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .displayLarge!
                                                .copyWith(
                                                  color: displayAmountColor
                                                      .withOpacity(0.3),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(bottom: 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'TOTAL REPAYMENT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // --- FORMATTED TOTAL REPAYMENT ---
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '₹ ',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                              color: displayAmountColor
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          TextSpan(
                                            text: CurrencyFormatter.format(
                                              double.tryParse(_liveResult) ??
                                                  0.0,
                                            ),
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              color: displayAmountColor,
                                              letterSpacing: -1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_expression.isNotEmpty &&
                                _expression != _liveResult &&
                                !hasAmountError &&
                                !isToLoan)
                              // --- FORMATTED LIVE RESULT EQUATION ---
                              Text(
                                '= ₹${CurrencyFormatter.format(double.tryParse(_liveResult) ?? 0.0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: displayAmountColor,
                                ),
                              ),
                            if (hasAmountError)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  errorMsg,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: isToLoan ? 6 : 5,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          if (isExpense &&
                              isBudgetLocked &&
                              !isEditingExisting &&
                              !isLoanRep)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.error.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Only "Out of Bucket" is available because $lockedReason',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.dividerColor,
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.2 : 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Material(
                              color: Colors.transparent,
                              child: Table(
                                border: TableBorder.symmetric(
                                  inside: BorderSide(
                                    color: theme.dividerColor,
                                    width: 1.0,
                                  ),
                                ),
                                children: tableRows,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 40,
              child: DockedCalculatorPad(
                backgroundColor: theme.scaffoldBackgroundColor,
                actionColor: txColor,
                onKeyPress: _onCalcKeyPress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
