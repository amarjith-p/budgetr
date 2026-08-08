// features/transactions/components/transaction_filter_bottom_sheet.dart
import 'package:budgetr/features/accounts/providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../../core/components/currency_text.dart';
import '../../category_manager/providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/transaction_filter_provider.dart';
import '../services/transaction_service.dart';

class TransactionFilterBottomSheet extends ConsumerStatefulWidget {
  final String accountId;
  final List<TransactionWithDetails> allTransactions;

  const TransactionFilterBottomSheet({
    Key? key,
    required this.accountId,
    required this.allTransactions,
  }) : super(key: key);

  static void show(
    BuildContext context,
    String accountId,
    List<TransactionWithDetails> allTransactions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionFilterBottomSheet(
        accountId: accountId,
        allTransactions: allTransactions,
      ),
    );
  }

  @override
  ConsumerState<TransactionFilterBottomSheet> createState() =>
      _TransactionFilterBottomSheetState();
}

class _TransactionFilterBottomSheetState
    extends ConsumerState<TransactionFilterBottomSheet> {
  late TransactionFilterState _draft;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  int _liveMatchCount = 0;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(transactionFilterProvider(widget.accountId));

    _minCtrl = TextEditingController(
      text: _draft.minAmount?.toStringAsFixed(0) ?? '',
    );
    _maxCtrl = TextEditingController(
      text: _draft.maxAmount?.toStringAsFixed(0) ?? '',
    );

    _minCtrl.addListener(_updateDraftFromInputs);
    _maxCtrl.addListener(_updateDraftFromInputs);

    _calculateLiveMatches();
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _updateDraftFromInputs() {
    setState(() {
      _draft = _draft.copyWith(
        minAmount: double.tryParse(_minCtrl.text),
        maxAmount: double.tryParse(_maxCtrl.text),
        clearMin: _minCtrl.text.isEmpty,
        clearMax: _maxCtrl.text.isEmpty,
      );
      _calculateLiveMatches();
    });
  }

  void _calculateLiveMatches() {
    if (widget.accountId == 'GLOBAL') {
      _liveMatchCount = TransactionFilterHelper.applyForRecords(
        widget.allTransactions,
        _draft,
      ).length;
    } else {
      _liveMatchCount = TransactionFilterHelper.apply(
        widget.allTransactions,
        _draft,
        widget.accountId,
      ).length;
    }
  }

  void _updateState(TransactionFilterState newState) {
    HapticFeedback.selectionClick();
    setState(() {
      _draft = newState;
      _calculateLiveMatches();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateState(
        _draft.copyWith(
          timeframe: TimeframeOption.custom,
          customStartDate: picked.start,
          customEndDate: picked.end,
        ),
      );
    }
  }

  void _apply() {
    ref.read(transactionFilterProvider(widget.accountId).notifier).state =
        _draft;
    Navigator.pop(context);
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    ref.read(transactionFilterProvider(widget.accountId).notifier).state =
        const TransactionFilterState();
    Navigator.pop(context);
  }

  String _formatShortDate(DateTime d) {
    return '${d.day} ${DateTimeConstants.shortMonths[d.month - 1]}';
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 12,
        left: DesignTokens.spacingLg,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPill<T>({
    required String label,
    required T value,
    required T currentValue,
    required ValueChanged<T> onSelected,
  }) {
    final isSelected = value == currentValue;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withOpacity(
                  isDark ? 0.3 : 0.5,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiPill<T>({
    required String label,
    required T value,
    required Set<T> currentSet,
    required Function(Set<T>) onUpdate,
  }) {
    final isSelected = currentSet.contains(value);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        final newSet = Set<T>.from(currentSet);
        if (isSelected)
          newSet.remove(value);
        else
          newSet.add(value);
        onUpdate(newSet);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withOpacity(
                  isDark ? 0.3 : 0.5,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _openMultiSelectSheet<T>({
    required String title,
    required Set<T> availableItems,
    required Set<T> selectedItems,
    required String Function(T) titleBuilder,
    String? Function(T)? subtitleBuilder,
    required ValueChanged<Set<T>> onApply,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Set<T> tempSelection = Set<T>.from(selectedItems);
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(DesignTokens.radiusLg),
                    ),
                  ),
                  child: Column(
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
                        padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setModalState(() => tempSelection.clear());
                              },
                              child: Text(
                                'CLEAR',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w900,
                                ),
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
                          itemCount: availableItems.length,
                          itemBuilder: (context, index) {
                            final item = availableItems.elementAt(index);
                            final isChecked = tempSelection.contains(item);

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? theme.colorScheme.primaryContainer
                                          .withOpacity(0.3)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isChecked
                                      ? theme.colorScheme.primary
                                      : theme.dividerColor.withOpacity(0.5),
                                ),
                              ),
                              child: CheckboxListTile(
                                value: isChecked,
                                activeColor: theme.colorScheme.primary,
                                title: Text(
                                  titleBuilder(item),
                                  style: TextStyle(
                                    fontWeight: isChecked
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 15,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle:
                                    subtitleBuilder != null &&
                                        subtitleBuilder(item) != null
                                    ? Text(
                                        subtitleBuilder(item)!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      )
                                    : null,
                                onChanged: (bool? checked) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    if (checked == true) {
                                      tempSelection.add(item);
                                    } else {
                                      tempSelection.remove(item);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.spacingLg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: theme.dividerColor,
                              width: 1.0,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ModernBoxyButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(ctx);
                                },
                                label: 'CANCEL',
                                isOutlined: true,
                              ),
                            ),
                            const SizedBox(width: DesignTokens.spacingMd),
                            Expanded(
                              flex: 2,
                              child: ModernBoxyButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  onApply(tempSelection);
                                  Navigator.pop(ctx);
                                },
                                label: 'APPLY',
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
          },
        );
      },
    );
  }

  Widget _buildDropdownTrigger({
    required String label,
    required int count,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isActive = count > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingLg,
        vertical: DesignTokens.spacingSm,
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.dividerColor.withOpacity(0.5),
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEnabled
                    ? (isActive ? '$label ($count Selected)' : 'Select $label')
                    : 'No $label found in history',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isEnabled
                      ? (isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface)
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isEnabled
                    ? (isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant)
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rawAccounts = ref.watch(accountsStreamProvider).asData?.value ?? [];

    // --- FIX: USE SNAPSHOT NAMES FROM HISTORY ---
    final activeCatNames = widget.allTransactions
        .map(
          (t) =>
              t.transaction.categoryName ?? t.category?.name ?? 'Uncategorized',
        )
        .toSet();

    final activeSubCats = widget.allTransactions
        .map((t) => t.transaction.subCategory ?? 'Uncategorized')
        .toSet();

    // --- FIX: USE SNAPSHOT NAMES FROM HISTORY ---
    final activeBucketNames = widget.allTransactions
        .map(
          (t) => t.transaction.bucketName ?? t.bucket?.name ?? 'Out of Bucket',
        )
        .toSet();

    String customDateText = 'Custom Range...';
    if (_draft.timeframe == TimeframeOption.custom &&
        _draft.customStartDate != null &&
        _draft.customEndDate != null) {
      customDateText =
          '${_formatShortDate(_draft.customStartDate!)} - ${_formatShortDate(_draft.customEndDate!)}';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusLg),
            ),
          ),
          child: Column(
            children: [
              // --- MODERN DRAG HANDLE ---
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
                padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter & Sort',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      child: const Text(
                        'RESET',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 100,
                  ),
                  children: [
                    _buildSectionTitle('SORT BY'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingLg,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildPill(
                            label: 'Newest First',
                            value: SortOption.newest,
                            currentValue: _draft.sortBy,
                            onSelected: (val) =>
                                _updateState(_draft.copyWith(sortBy: val)),
                          ),
                          _buildPill(
                            label: 'Oldest First',
                            value: SortOption.oldest,
                            currentValue: _draft.sortBy,
                            onSelected: (val) =>
                                _updateState(_draft.copyWith(sortBy: val)),
                          ),
                          _buildPill(
                            label: 'Highest',
                            value: SortOption.highestAmount,
                            currentValue: _draft.sortBy,
                            onSelected: (val) =>
                                _updateState(_draft.copyWith(sortBy: val)),
                          ),
                          _buildPill(
                            label: 'Lowest',
                            value: SortOption.lowestAmount,
                            currentValue: _draft.sortBy,
                            onSelected: (val) =>
                                _updateState(_draft.copyWith(sortBy: val)),
                          ),
                        ],
                      ),
                    ),

                    _buildSectionTitle('TIMEFRAME'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingLg,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildPill(
                            label: 'All Time',
                            value: TimeframeOption.allTime,
                            currentValue: _draft.timeframe,
                            onSelected: (val) =>
                                _updateState(_draft.copyWith(timeframe: val)),
                          ),
                          _buildPill(
                            label: 'Current Month',
                            value: TimeframeOption.currentMonth,
                            currentValue: _draft.timeframe,
                            onSelected: (val) =>
                                _updateState(_draft.copyWith(timeframe: val)),
                          ),
                          _buildPill(
                            label: 'Last Month',
                            value: TimeframeOption.lastMonth,
                            currentValue: _draft.timeframe,
                            onSelected: (val) =>
                                _updateState(_draft.copyWith(timeframe: val)),
                          ),
                          GestureDetector(
                            onTap: _pickDateRange,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _draft.timeframe == TimeframeOption.custom
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest
                                          .withOpacity(isDark ? 0.3 : 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      _draft.timeframe == TimeframeOption.custom
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    size: 16,
                                    color:
                                        _draft.timeframe ==
                                            TimeframeOption.custom
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    customDateText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          _draft.timeframe ==
                                              TimeframeOption.custom
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color:
                                          _draft.timeframe ==
                                              TimeframeOption.custom
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildSectionTitle('TRANSACTION TYPE'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingLg,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildMultiPill(
                            label: 'Expense',
                            value: 'Expense',
                            currentSet: _draft.types,
                            onUpdate: (val) =>
                                _updateState(_draft.copyWith(types: val)),
                          ),
                          _buildMultiPill(
                            label: 'Income',
                            value: 'Income',
                            currentSet: _draft.types,
                            onUpdate: (val) =>
                                _updateState(_draft.copyWith(types: val)),
                          ),
                          _buildMultiPill(
                            label: 'Transfer In',
                            value: 'Transfer In',
                            currentSet: _draft.types,
                            onUpdate: (val) =>
                                _updateState(_draft.copyWith(types: val)),
                          ),
                          _buildMultiPill(
                            label: 'Transfer Out',
                            value: 'Transfer Out',
                            currentSet: _draft.types,
                            onUpdate: (val) =>
                                _updateState(_draft.copyWith(types: val)),
                          ),
                        ],
                      ),
                    ),

                    _buildSectionTitle('AMOUNT THRESHOLD'),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingLg,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _minCtrl,
                              labelText: 'Minimum (₹)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '-',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: theme.dividerColor,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _maxCtrl,
                              labelText: 'Maximum (₹)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildSectionTitle('DATA FILTERS'),
                    if (widget.accountId == 'GLOBAL') ...[
                      _buildDropdownTrigger(
                        label: 'Accounts',
                        count: _draft.accountIds.length,
                        isEnabled: true,
                        onTap: () {
                          _openMultiSelectSheet<String>(
                            title: 'Select Accounts',
                            availableItems: rawAccounts
                                .map((a) => a.id)
                                .toSet(),
                            selectedItems: _draft.accountIds,
                            titleBuilder: (id) {
                              final acc = rawAccounts
                                  .where((a) => a.id == id)
                                  .firstOrNull;
                              return acc?.name ?? 'Unknown Account';
                            },
                            subtitleBuilder: (id) {
                              final acc = rawAccounts
                                  .where((a) => a.id == id)
                                  .firstOrNull;
                              return acc?.providerName;
                            },
                            onApply: (val) =>
                                _updateState(_draft.copyWith(accountIds: val)),
                          );
                        },
                      ),
                    ],

                    _buildDropdownTrigger(
                      label: 'Categories',
                      count: _draft.categoryNames.length,
                      isEnabled: activeCatNames.isNotEmpty,
                      onTap: () => _openMultiSelectSheet<String>(
                        title: 'Select Categories',
                        availableItems: activeCatNames,
                        selectedItems: _draft.categoryNames,
                        titleBuilder: (name) => name,
                        onApply: (val) =>
                            _updateState(_draft.copyWith(categoryNames: val)),
                      ),
                    ),

                    _buildDropdownTrigger(
                      label: 'Subcategories',
                      count: _draft.subCategories.length,
                      isEnabled: activeSubCats.isNotEmpty,
                      onTap: () => _openMultiSelectSheet<String>(
                        title: 'Select Subcategories',
                        availableItems: activeSubCats,
                        selectedItems: _draft.subCategories,
                        titleBuilder: (sub) => sub,
                        onApply: (val) =>
                            _updateState(_draft.copyWith(subCategories: val)),
                      ),
                    ),

                    _buildDropdownTrigger(
                      label: 'Budget Buckets',
                      count: _draft.bucketNames.length,
                      isEnabled: activeBucketNames.isNotEmpty,
                      onTap: () => _openMultiSelectSheet<String>(
                        title: 'Select Buckets',
                        availableItems: activeBucketNames,
                        selectedItems: _draft.bucketNames,
                        titleBuilder: (name) => name,
                        onApply: (val) =>
                            _updateState(_draft.copyWith(bucketNames: val)),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // --- MAIN TWIN BUTTON DESIGN ---
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ModernBoxyButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        label: 'CANCEL',
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      flex: 2,
                      child: ModernBoxyButton(
                        onPressed: _liveMatchCount > 0 ? _apply : null,
                        label: _liveMatchCount == 0
                            ? 'NO MATCHES'
                            : 'SHOW ($_liveMatchCount)',
                        backgroundColor: _liveMatchCount == 0
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.primary,
                        foregroundColor: _liveMatchCount == 0
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onPrimary,
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
