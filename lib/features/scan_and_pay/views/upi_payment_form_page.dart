// lib/features/scan_and_pay/views/upi_payment_form_page.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:budgetr/core/models/transaction_category_model.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/components/custom_snackbars.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart' as db_prov;
import '../../../core/utils/location_helper.dart';
import '../../accounts/providers/account_provider.dart';
import '../../category_manager/providers/category_provider.dart';
import '../../settings/providers/location_settings_provider.dart';
import '../../transactions/components/tag_input_sheet.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/views/location_map_picker_page.dart';
import '../models/upi_payment_models.dart';
import '../providers/pending_upi_provider.dart';
import '../services/upi_payment_service.dart';

// ignore_for_file: avoid_dynamic_calls
// Dynamic IconData from DB codepoints — build with --no-tree-shake-icons.
IconData _iconFromCode(int code) =>
    IconData(code, fontFamily: 'MaterialIcons');

class _BucketItem {
  final int id;
  final String name;
  const _BucketItem(this.id, this.name);
}

final _upiBudgetProvider = StreamProvider.family<MonthlyBudget?, DateTime>((
  ref,
  date,
) {
  final db = ref.watch(db_prov.databaseProvider);
  return (db.select(db.monthlyBudgets)
        ..where(
          (tbl) => tbl.month.equals(date.month) & tbl.year.equals(date.year),
        )
        ..limit(1))
      .watchSingleOrNull();
});

final _masterBucketsProvider = StreamProvider<List<BudgetBucket>>((ref) {
  final db = ref.watch(db_prov.databaseProvider);
  return db.select(db.budgetBuckets).watch();
});

class UpiPaymentFormPage extends ConsumerStatefulWidget {
  final UpiQrData? qrData;
  final PendingUpiPayment? pendingPayment;

  const UpiPaymentFormPage({super.key, this.qrData, this.pendingPayment})
    : assert(qrData != null || pendingPayment != null);

  @override
  ConsumerState<UpiPaymentFormPage> createState() => _UpiPaymentFormPageState();
}

class _UpiPaymentFormPageState extends ConsumerState<UpiPaymentFormPage> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedSubCategory;
  int? _selectedBucketId;
  List<String> _tags = [];

  String? _locationName;
  double? _latitude;
  double? _longitude;
  bool _isFetchingLoc = false;

  bool _showValidationErrors = false;
  bool _isSubmitting = false;
  double? _normalAvailableHeight;

  bool get _isEditPending => widget.pendingPayment != null;

  String get _payeeName =>
      widget.qrData?.pn ?? widget.pendingPayment?.payeeName ?? 'UPI Merchant';
  String get _payeeVpa =>
      widget.qrData?.pa ?? widget.pendingPayment?.payeeVpa ?? '';

  @override
  void initState() {
    super.initState();
    final pending = widget.pendingPayment;
    final qr = widget.qrData;

    if (pending != null) {
      _amountCtrl.text = pending.amount.toStringAsFixed(
        pending.amount.truncateToDouble() == pending.amount ? 0 : 2,
      );
      if (pending.note != null) _notesCtrl.text = pending.note!;
      _selectedAccountId = pending.accountId;
      _selectedCategoryId = pending.categoryId;
      _selectedSubCategory = pending.subCategory;
      _selectedBucketId = pending.bucketId;
      if (pending.tags != null && pending.tags!.isNotEmpty) {
        _tags = pending.tags!.split(',').map((t) => t.trim()).toList();
      }
      _locationName = pending.locationName;
      _latitude = pending.latitude;
      _longitude = pending.longitude;
    } else if (qr != null) {
      if (qr.am != null && qr.am! > 0) {
        _amountCtrl.text = qr.am!.toStringAsFixed(2);
      }
      if (qr.tn != null && qr.tn!.isNotEmpty) {
        _notesCtrl.text = qr.tn!;
      }
      final guessedCatName = qr.guessCategoryName();
      if (guessedCatName != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoSelectGuessedCategory(guessedCatName);
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSelectDefaultAccount();
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _autoSelectGuessedCategory(String guessedName) {
    final categories = ref.read(categoriesStreamProvider).asData?.value ?? [];
    final match = categories
        .where(
          (c) =>
              c.type.toLowerCase() == 'expense' &&
              c.name.toLowerCase() == guessedName.toLowerCase(),
        )
        .firstOrNull;
    if (match != null && mounted) {
      setState(() => _selectedCategoryId = match.id);
    }
  }

  void _autoSelectDefaultAccount() {
    if (_selectedAccountId != null) return;
    final accounts = ref.read(accountsStreamProvider).asData?.value ?? [];
    final eligible = accounts
        .where((a) => !a.isClosed && a.type != 'Loan')
        .toList();
    if (eligible.isNotEmpty && mounted) {
      setState(() => _selectedAccountId = eligible.first.id);
    }
  }

  void _addQuickAmount(double addition) {
    HapticFeedback.selectionClick();
    final current = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final next = current + addition;
    _amountCtrl.text = next.toStringAsFixed(
      next.truncateToDouble() == next ? 0 : 2,
    );
    setState(() {});
  }

  // ─── Account Selection ───────────────────────────────────────────

  Future<void> _pickAccount(List<Account> accounts) async {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final assets = accounts
        .where((a) => !a.isClosed && a.type != 'Credit Cards' && a.type != 'Loan')
        .toList();
    final creditCards = accounts
        .where((a) => !a.isClosed && a.type == 'Credit Cards')
        .toList();
    final selectedId = _selectedAccountId;

    final selected = await GlobalSelectionSheet.show<String>(
      context: context,
      title: 'Select Debit Account',
      builder: (ctx, scrollController) {
        return ListView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          children: [
            ..._buildAccountGroup(
              ctx, assets, 'ASSETS & BANK ACCOUNTS',
              Icons.account_balance_wallet_rounded, selectedId, theme,
            ),
            if (assets.isNotEmpty && creditCards.isNotEmpty)
              Divider(height: 12, thickness: 4, color: theme.dividerColor.withValues(alpha: 0.05)),
            ..._buildAccountGroup(
              ctx, creditCards, 'CREDIT CARDS',
              Icons.credit_card_rounded, selectedId, theme,
            ),
          ],
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedAccountId = selected);
    }
  }

  List<Widget> _buildAccountGroup(
    BuildContext ctx,
    List<Account> group,
    String title,
    IconData icon,
    String? selectedId,
    ThemeData theme,
  ) {
    if (group.isEmpty) return [];
    final tiles = <Widget>[];
    for (int i = 0; i < group.length; i++) {
      final acc = group[i];
      final isSelected = acc.id == selectedId;
      tiles.add(
        InkWell(
          onTap: () => Navigator.pop(ctx, acc.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        acc.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: -0.1,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${acc.providerName}  •  ₹${acc.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.1,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
      );
      // faded separator between accounts (not after last one)
      if (i < group.length - 1) {
        tiles.add(
          Divider(
            height: 1,
            thickness: 0.6,
            indent: 20,
            endIndent: 20,
            color: theme.dividerColor.withValues(alpha: 0.35),
          ),
        );
      }
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Row(
          children: [
            Icon(icon, size: 13, color: theme.colorScheme.primary),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      ...tiles,
    ];
  }

  // ─── Category Selection ──────────────────────────────────────────

  Future<void> _pickCategory(List<TransactionCategoryModel> categories) async {
    HapticFeedback.lightImpact();
    final expenseCats = categories
        .where((c) => c.type.toLowerCase() == 'expense')
        .toList();
    final selectedCat = expenseCats
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;

    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Expense Category',
      items: expenseCats.map((c) => c.name).toList(),
      selectedValue: selectedCat?.name ?? '',
    );

    if (selected != null && mounted) {
      final match = expenseCats.where((c) => c.name == selected).firstOrNull;
      if (match != null) {
        setState(() {
          _selectedCategoryId = match.id;
          _selectedSubCategory = null;
        });

        if (match.subCategories.isNotEmpty && mounted) {
          final chosenSub = await GlobalSelectionSheet.showSimple(
            context: context,
            title: 'Select Subcategory (Optional)',
            items: ['None', ...match.subCategories],
            selectedValue: _selectedSubCategory ?? 'None',
          );
          if (chosenSub != null && chosenSub != 'None' && mounted) {
            setState(() => _selectedSubCategory = chosenSub);
          }
        }
      }
    }
  }

  // ─── Budget Bucket Selection ─────────────────────────────────────

  Future<void> _pickBucket(List<_BucketItem> buckets) async {
    HapticFeedback.lightImpact();
    final selectedBucket = buckets
        .where((b) => b.id == _selectedBucketId)
        .firstOrNull;

    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Assign to Budget Bucket',
      items: buckets.map((b) => b.name).toList(),
      selectedValue: selectedBucket?.name ?? '',
    );

    if (selected != null && mounted) {
      final match = buckets.where((b) => b.name == selected).firstOrNull;
      if (match != null) {
        setState(() => _selectedBucketId = match.id);
      }
    }
  }

  // ─── Tags & Note Modal Sheet ──────────────────────────────────────

  Future<void> _openTagsAndNoteSheet() async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final viewInsets = MediaQuery.of(sheetCtx).viewInsets;
            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'ADD REMARKS & TAGS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _notesCtrl,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Remarks / Note',
                        hintText: 'e.g. Lunch with team, Groceries',
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TAGS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final allTxs =
                                ref
                                    .read(allTransactionsProvider)
                                    .asData
                                    ?.value ??
                                [];
                            final allTags = extractUniqueTags(
                              allTxs.map((t) => t.transaction.tags),
                            );
                            final res = await TagInputSheet.show(
                              sheetCtx,
                              selectedTags: List<String>.from(_tags),
                              recentTags: allTags,
                            );
                            if (res != null) {
                              setState(() => _tags = res);
                              setSheetState(() {});
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text(
                            'Edit Tags',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _tags.map((t) {
                          return Chip(
                            label: Text(
                              '#$t',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 14,
                            ),
                            onDeleted: () {
                              setState(() => _tags.remove(t));
                              setSheetState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(fontWeight: FontWeight.w900),
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
    setState(() {});
  }

  // ─── Location Picker ──────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    FocusScope.of(context).unfocus();

    LocationPreference activePref = ref.read(locationSettingsProvider);

    if (activePref == LocationPreference.ask) {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('location_pref');
      if (stored != null) {
        activePref = LocationPreference.values.firstWhere(
          (e) => e.name == stored,
          orElse: () => LocationPreference.ask,
        );
      }
    }

    if (!mounted) return;

    if (activePref == LocationPreference.ask) {
      HapticFeedback.lightImpact();
      final choice = await GlobalSelectionSheet.showSimple(
        context: context,
        title: 'Set Location',
        items: const ['Use Current GPS Location', 'Choose on Map'],
        selectedValue: '',
      );

      if (choice == null) return;

      activePref = choice == 'Choose on Map'
          ? LocationPreference.map
          : LocationPreference.current;
    }

    if (activePref == LocationPreference.map) {
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationMapPickerPage(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            initialLocationName: _locationName,
          ),
        ),
      );

      if (result != null && result is Map<String, dynamic> && mounted) {
        setState(() {
          _locationName = result['name'];
          _latitude = result['latitude'];
          _longitude = result['longitude'];
        });
      }
      return;
    }

    setState(() => _isFetchingLoc = true);
    try {
      final locData = await LocationHelper.fetchCurrentLocation();
      if (locData != null && mounted) {
        setState(() {
          _locationName = locData['name'];
          _latitude = locData['latitude'];
          _longitude = locData['longitude'];
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showError(
          context,
          message: 'Could not fetch location: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLoc = false);
    }
  }

  // ─── Submit Payment with NPCI Launch ─────────────────────────────

  Future<void> _handleSubmit() async {
    setState(() => _showValidationErrors = true);

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      CustomSnackbars.showError(
        context,
        message: 'Please enter a valid payment amount greater than ₹0',
      );
      return;
    }

    if (_selectedAccountId == null) {
      HapticFeedback.heavyImpact();
      CustomSnackbars.showError(
        context,
        message: 'Please select a Debit Account',
      );
      return;
    }

    if (_selectedCategoryId == null) {
      HapticFeedback.heavyImpact();
      CustomSnackbars.showError(
        context,
        message: 'Please select an Expense Category',
      );
      return;
    }

    if (_selectedBucketId == null) {
      HapticFeedback.heavyImpact();
      CustomSnackbars.showError(
        context,
        message: 'Please select a Budget Bucket',
      );
      return;
    }

    final accounts = ref.read(accountsStreamProvider).asData?.value ?? [];
    final selectedAcc = accounts.firstWhere((a) => a.id == _selectedAccountId);

    final categories = ref.read(categoriesStreamProvider).asData?.value ?? [];
    final selectedCat = categories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;

    final now = DateTime.now();
    final budgetDate = DateTime(now.year, now.month);
    final activeBudget = ref.read(_upiBudgetProvider(budgetDate)).asData?.value;
    String bucketName = 'Out of Bucket';
    if (_selectedBucketId != null && _selectedBucketId != -1) {
      if (activeBudget?.bucketsSnapshot != null &&
          activeBudget!.bucketsSnapshot!.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(
            activeBudget.bucketsSnapshot!,
          );
          for (final item in decoded) {
            if (item is Map<String, dynamic> &&
                item['id'] == _selectedBucketId) {
              bucketName = item['name'] as String;
              break;
            }
          }
        } catch (_) {}
      }
      if (bucketName == 'Out of Bucket') {
        final masterBuckets =
            ref.read(_masterBucketsProvider).asData?.value ?? [];
        final mb = masterBuckets
            .where((b) => b.id == _selectedBucketId)
            .firstOrNull;
        if (mb != null) bucketName = mb.name;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final finalUri = UpiPaymentService.buildUpiUri(
        pa: _payeeVpa,
        pn: _payeeName,
        amount: amount,
        note: _notesCtrl.text.isNotEmpty
            ? _notesCtrl.text
            : (widget.qrData?.tn ?? 'Payment to $_payeeName'),
        mc: widget.qrData?.mc,
        tr: widget.qrData?.tr,
      );

      final launched = await UpiPaymentService.launchUpi(upiUri: finalUri);

      if (launched) {
        final pendingPayment = PendingUpiPayment(
          id:
              widget.pendingPayment?.id ??
              'upi_${DateTime.now().millisecondsSinceEpoch}',
          payeeName: _payeeName,
          payeeVpa: _payeeVpa,
          amount: amount,
          accountId: selectedAcc.id,
          accountName: selectedAcc.name,
          categoryId: selectedCat?.id,
          categoryName: selectedCat?.name,
          categoryIcon: selectedCat?.iconCode,
          subCategory: _selectedSubCategory,
          bucketId: _selectedBucketId,
          bucketName: bucketName,
          note: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
          tags: _tags.isNotEmpty ? _tags.join(',') : null,
          locationName: _locationName,
          latitude: _latitude,
          longitude: _longitude,
          createdAt: widget.pendingPayment?.createdAt ?? DateTime.now(),
          rawUpiUri: finalUri,
        );

        if (widget.pendingPayment != null) {
          await ref
              .read(pendingUpiPaymentsProvider.notifier)
              .discardPayment(widget.pendingPayment!.id);
        }
        await ref
            .read(pendingUpiPaymentsProvider.notifier)
            .addPendingPayment(pendingPayment);

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          CustomSnackbars.showError(
            context,
            message:
                'Could not find any installed UPI app (Google Pay, PhonePe, Paytm).',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final rawAccounts = accountsAsync.asData?.value ?? [];
    final eligibleAccounts = rawAccounts
        .where((a) => !a.isClosed && a.type != 'Loan')
        .toList();
    final selectedAcc = eligibleAccounts
        .where((a) => a.id == _selectedAccountId)
        .firstOrNull;

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final rawCategories = categoriesAsync.asData?.value ?? [];
    final selectedCat = rawCategories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;

    // Budget resolution matching TransactionFormPage
    final now = DateTime.now();
    final budgetDate = DateTime(now.year, now.month);
    final budgetAsync = ref.watch(_upiBudgetProvider(budgetDate));
    final activeBudget = budgetAsync.asData?.value;

    final masterBucketsAsync = ref.watch(_masterBucketsProvider);
    final masterBuckets = masterBucketsAsync.asData?.value ?? [];

    final List<_BucketItem> bucketItems = [];
    if (activeBudget != null && !activeBudget.isClosed) {
      if (activeBudget.bucketsSnapshot != null &&
          activeBudget.bucketsSnapshot!.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(
            activeBudget.bucketsSnapshot!,
          );
          for (final item in decoded) {
            if (item is Map<String, dynamic> &&
                item.containsKey('id') &&
                item.containsKey('name')) {
              bucketItems.add(
                _BucketItem(item['id'] as int, item['name'] as String),
              );
            }
          }
        } catch (_) {}
      }
    }

    if (bucketItems.isEmpty && masterBuckets.isNotEmpty) {
      for (final mb in masterBuckets) {
        bucketItems.add(_BucketItem(mb.id, mb.name));
      }
    }
    bucketItems.add(const _BucketItem(-1, 'Out of Bucket'));

    final selectedBucket = bucketItems
        .where((b) => b.id == _selectedBucketId)
        .firstOrNull;

    final parsedAmount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final amountHasError = _showValidationErrors && parsedAmount <= 0;
    final accountHasError = _showValidationErrors && _selectedAccountId == null;
    final categoryHasError =
        _showValidationErrors && _selectedCategoryId == null;
    final bucketHasError = _showValidationErrors && _selectedBucketId == null;

    final amountFormatted = parsedAmount > 0
        ? '₹${NumberFormat('#,##,##0.00').format(parsedAmount)}'
        : '₹0.00';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: ModernAppBar(
        title: _isEditPending ? 'Verify UPI Payment' : 'Scan & Pay',
        subtitle: 'SECURE NPCI PAYMENT',
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Capture the full unconstrained height when keyboard is closed.
                  // When keyboard opens, constraints.maxHeight shrinks, but we preserve
                  // the natural unconstrained tile height so fields DO NOT shrink!
                  if (_normalAvailableHeight == null ||
                      constraints.maxHeight > _normalAvailableHeight!) {
                    _normalAvailableHeight = constraints.maxHeight;
                  }

                  const fixedHeight = 212.0;
                  final fullAvailable =
                      _normalAvailableHeight ?? constraints.maxHeight;
                  final availableForTiles = fullAvailable - fixedHeight;
                  // Dynamic tile height that perfectly fills the screen without blank space when keyboard is closed,
                  // and keeps its full comfortable size so the user can scroll to fields below the keyboard.
                  final tileHeight = math.max(64.0, availableForTiles / 5.0);

                  final merchantHero = _buildMerchantHero(
                    theme,
                    isDark,
                    primary,
                  );
                  final amountCard = _buildAmountCard(
                    theme,
                    isDark,
                    primary,
                    amountHasError,
                  );

                  Widget buildSizedTile(Widget tile) {
                    return SizedBox(
                      height: tileHeight,
                      child: tile,
                    );
                  }

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        merchantHero,
                        const SizedBox(height: 7),
                        amountCard,
                        const SizedBox(height: 7),
                        buildSizedTile(_buildFieldTile(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'DEBIT FROM *',
                          value: selectedAcc?.name ?? 'Select Account',
                          subtitle: selectedAcc != null
                              ? 'Balance: ₹${selectedAcc.balance.toStringAsFixed(0)} • ${selectedAcc.type}'
                              : 'Mandatory debit source',
                          hasError: accountHasError,
                          errorLabel: 'REQUIRED',
                          onTap: () => _pickAccount(rawAccounts),
                        )),
                        const SizedBox(height: 7),
                        buildSizedTile(_buildFieldTile(
                          icon: selectedCat != null
                              ? _iconFromCode(selectedCat.iconCode)
                              : Icons.category_rounded,
                          title: 'EXPENSE CATEGORY *',
                          value: selectedCat?.name ?? 'Select Category',
                          subtitle: _selectedSubCategory != null
                              ? 'Subcategory: $_selectedSubCategory'
                              : (selectedCat != null
                                    ? 'Tap to change subcategory'
                                    : 'Mandatory classification'),
                          hasError: categoryHasError,
                          errorLabel: 'REQUIRED',
                          onTap: () => _pickCategory(rawCategories),
                        )),
                        const SizedBox(height: 7),
                        buildSizedTile(_buildFieldTile(
                          icon: selectedBucket?.id == -1
                              ? Icons.block_rounded
                              : Icons.pie_chart_rounded,
                          title: 'BUDGET BUCKET *',
                          value: selectedBucket?.name ?? 'Assign Bucket',
                          subtitle: selectedBucket != null
                              ? 'Assigned to active budget'
                              : 'Mandatory budget allocation',
                          hasError: bucketHasError,
                          errorLabel: 'REQUIRED',
                          onTap: () => _pickBucket(bucketItems),
                        )),
                        const SizedBox(height: 7),
                        buildSizedTile(_buildFieldTile(
                          icon: Icons.edit_note_rounded,
                          title: 'REMARKS & TAGS',
                          value: _notesCtrl.text.isNotEmpty
                              ? _notesCtrl.text
                              : (_tags.isNotEmpty
                                    ? '#${_tags.first}'
                                    : 'Add Remarks / Tags'),
                          subtitle: _tags.isNotEmpty
                              ? _tags.map((t) => '#$t').join(' ')
                              : 'Optional tags and transaction note',
                          hasError: false,
                          errorLabel: '',
                          onTap: _openTagsAndNoteSheet,
                        )),
                        const SizedBox(height: 7),
                        buildSizedTile(_buildFieldTile(
                          icon: _isFetchingLoc
                              ? Icons.gps_fixed_rounded
                              : Icons.pin_drop_rounded,
                          title: 'LOCATION',
                          value: _isFetchingLoc
                              ? 'Fetching GPS...'
                              : (_locationName ?? 'Add Location'),
                          subtitle: _locationName != null
                              ? 'Attached location'
                              : 'Optional GPS or map coordinates',
                          hasError: false,
                          errorLabel: '',
                          onTap: _isFetchingLoc ? null : _fetchLocation,
                          trailing: _locationName != null && !_isFetchingLoc
                              ? GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _locationName = null;
                                      _latitude = null;
                                      _longitude = null;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 2.0),
                                    child: Icon(
                                      Icons.cancel_rounded,
                                      size: 18,
                                      color: theme.colorScheme.error.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        )),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ─── 4. Screen-Size Action Button (Floats Above Keyboard) ───
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 4,
                        shadowColor: primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.shield_outlined, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isEditPending
                                          ? 'CONFIRM & SAVE'
                                          : 'PAY VIA UPI APP',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      amountFormatted,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 19,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 11,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'NPCI Standard 256-Bit Encrypted UPI Link',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.65,
                          ),
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
    );
  }

  // ─── Individual Modern Field Card ─────────────────────────────────

  Widget _buildFieldTile({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required bool hasError,
    required String errorLabel,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError
                  ? theme.colorScheme.error
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : theme.dividerColor.withValues(alpha: 0.3)),
              width: hasError ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: hasError
                    ? theme.colorScheme.error.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with Tinted Container
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: hasError
                      ? theme.colorScheme.error.withValues(alpha: 0.12)
                      : primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: hasError ? theme.colorScheme.error : primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Content (Title, Value, Subtitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: hasError
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (hasError)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              errorLabel,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.error,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: hasError
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null) trailing,
              if (trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: hasError
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantHero(ThemeData theme, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withValues(alpha: 0.85),
                ]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withValues(alpha: 0.95),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : theme.dividerColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gradient Merchant Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _payeeName.isNotEmpty ? _payeeName[0].toUpperCase() : 'M',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _payeeName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alternate_email_rounded,
                            size: 11,
                            color: primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'UPI',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _payeeVpa));
                    HapticFeedback.selectionClick();
                    CustomSnackbars.showSuccess(
                      context,
                      message: 'UPI ID copied',
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _payeeVpa,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.copy_rounded,
                        size: 12,
                        color: primary.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(
    ThemeData theme,
    bool isDark,
    Color primary,
    bool amountHasError,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: amountHasError
              ? theme.colorScheme.error
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : theme.dividerColor.withValues(alpha: 0.25)),
          width: amountHasError ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: amountHasError ? theme.colorScheme.error : primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1,
                    color: amountHasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: theme.hintColor.withValues(alpha: 0.35),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_amountCtrl.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _amountCtrl.clear();
                    setState(() {});
                  },
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 20,
                    color: theme.hintColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickChip('+₹50', 50, primary),
              const SizedBox(width: 6),
              _buildQuickChip('+₹100', 100, primary),
              const SizedBox(width: 6),
              _buildQuickChip('+₹200', 200, primary),
              const SizedBox(width: 6),
              _buildQuickChip('+₹500', 500, primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, double amount, Color primary) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _addQuickAmount(amount),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primary.withValues(alpha: 0.22)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
