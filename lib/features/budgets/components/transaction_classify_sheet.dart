// lib/features/budgets/components/transaction_classify_sheet.dart
//
// Redesigned Smart Classification Sheet:
// • Shows ALL transactions (not just unclassified) — any can be edited
// • Auto-classification suggestions shown with confidence badges
// • Search bar to filter by any keyword
// • Swipe-to-classify (left/right swipe actions per card)
// • Persists each change immediately
// • Re-classify = edit mode (unchanged items stay unchanged)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/constants/icon_constants.dart';
import '../../../core/database/app_database.dart';
import '../models/transaction_classification.dart';
import '../services/transaction_classification_store.dart';
import '../services/transaction_auto_classifier.dart';

class TransactionClassifySheet extends StatefulWidget {
  final List<TransactionRecord> transactions;
  final int month;
  final int year;
  final Map<String, TransactionClassification> existingClassifications;

  /// If true, all items already have auto or user classifications — edit mode.
  final bool isEditMode;

  const TransactionClassifySheet({
    Key? key,
    required this.transactions,
    required this.month,
    required this.year,
    required this.existingClassifications,
    this.isEditMode = false,
  }) : super(key: key);

  static Future<Map<String, TransactionClassification>?> show(
    BuildContext context, {
    required List<TransactionRecord> transactions,
    required int month,
    required int year,
    required Map<String, TransactionClassification> existingClassifications,
    bool isEditMode = false,
  }) {
    return showModalBottomSheet<Map<String, TransactionClassification>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => TransactionClassifySheet(
        transactions: transactions,
        month: month,
        year: year,
        existingClassifications: existingClassifications,
        isEditMode: isEditMode,
      ),
    );
  }

  @override
  State<TransactionClassifySheet> createState() =>
      _TransactionClassifySheetState();
}

class _TransactionClassifySheetState extends State<TransactionClassifySheet> {
  late Map<String, TransactionClassification> _classifications;
  late Map<String, ClassificationGuess> _autoGuesses;
  late List<TransactionRecord> _allTransactions;
  List<TransactionRecord> _filtered = [];

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _allTransactions = List.from(widget.transactions);
    _classifications = Map.from(widget.existingClassifications);

    // Auto-classify everything that isn't already user-classified
    _autoGuesses = TransactionAutoClassifier.classifyAll(_allTransactions);

    // Pre-fill unclassified items with auto suggestions
    for (final tx in _allTransactions) {
      if (!_classifications.containsKey(tx.id)) {
        _classifications[tx.id] = _autoGuesses[tx.id]!.classification;
      }
    }

    _applyFilter();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.toLowerCase();
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = List.from(_allTransactions);
    } else {
      _filtered = _allTransactions.where((tx) {
        return (tx.categoryName ?? '').toLowerCase().contains(_query) ||
            (tx.subCategory ?? '').toLowerCase().contains(_query) ||
            (tx.notes ?? '').toLowerCase().contains(_query) ||
            (tx.bucketName ?? '').toLowerCase().contains(_query) ||
            tx.amount.toStringAsFixed(2).contains(_query) ||
            _formatDate(tx.date).toLowerCase().contains(_query);
      }).toList();
    }
  }

  Future<void> _setClassification(
    TransactionRecord tx,
    TransactionClassification clf,
  ) async {
    HapticFeedback.lightImpact();
    setState(() => _classifications[tx.id] = clf);
    await TransactionClassificationStore.save(
      widget.month,
      widget.year,
      tx.id,
      clf,
    );
  }

  Future<void> _saveAllAndClose() async {
    await TransactionClassificationStore.saveAll(
      widget.month,
      widget.year,
      _classifications,
    );
    if (mounted) Navigator.pop(context, _classifications);
  }

  int get _classifiedCount => _allTransactions
      .where((tx) => _classifications.containsKey(tx.id))
      .length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = _allTransactions.length;
    final classified = _classifiedCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.psychology_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditMode
                                ? 'Edit Classifications'
                                : 'Smart Classification',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            '$classified / $total classified — swipe or tap to change',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Done button
                    FilledButton(
                      onPressed: _saveAllAndClose,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Legend row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _LegendChip('🔁 Fixed', const Color(0xFF5B6EF5)),
                    const SizedBox(width: 6),
                    _LegendChip('🌊 Variable', const Color(0xFF00BFA5)),
                    const SizedBox(width: 6),
                    _LegendChip(
                      '⚡ One-off',
                      const Color.fromARGB(255, 182, 146, 89),
                    ),
                    const Spacer(),
                    // Auto-detect info
                    Row(
                      children: [
                        Icon(
                          Icons.auto_fix_high_rounded,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Auto-detected',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Swipe hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.swipe_rounded,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Swipe right → Fixed  ·  Swipe left → Variable / One-off',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by category, notes, amount...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),

              // Transaction list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'No transactions'
                              : 'No results for "$_query"',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = _filtered[index];
                          final current =
                              _classifications[tx.id] ??
                              TransactionClassification.variable;
                          final guess = _autoGuesses[tx.id];
                          final isAutoGuess =
                              guess != null && guess.classification == current;

                          return _SwipeClassifyCard(
                            tx: tx,
                            current: current,
                            autoGuess: guess,
                            isAutoGuess: isAutoGuess,
                            theme: theme,
                            isDark: isDark,
                            onClassify: (clf) => _setClassification(tx, clf),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
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
}

// ---------------------------------------------------------------------------
// Swipeable classification card
// ---------------------------------------------------------------------------
class _SwipeClassifyCard extends StatefulWidget {
  final TransactionRecord tx;
  final TransactionClassification current;
  final ClassificationGuess? autoGuess;
  final bool isAutoGuess;
  final ThemeData theme;
  final bool isDark;
  final ValueChanged<TransactionClassification> onClassify;

  const _SwipeClassifyCard({
    required this.tx,
    required this.current,
    required this.autoGuess,
    required this.isAutoGuess,
    required this.theme,
    required this.isDark,
    required this.onClassify,
  });

  @override
  State<_SwipeClassifyCard> createState() => _SwipeClassifyCardState();
}

class _SwipeClassifyCardState extends State<_SwipeClassifyCard> {
  bool _showPicker = false;

  Color get _currentColor {
    switch (widget.current) {
      case TransactionClassification.fixed:
        return const Color(0xFF5B6EF5);
      case TransactionClassification.variable:
        return const Color(0xFF00BFA5);
      case TransactionClassification.oneoff:
        return const Color.fromARGB(255, 182, 146, 89);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final tx = widget.tx;
    final color = _currentColor;

    return Dismissible(
      key: ValueKey('classify_${tx.id}'),
      confirmDismiss: (direction) async {
        // Swipe right → Fixed
        if (direction == DismissDirection.startToEnd) {
          widget.onClassify(TransactionClassification.fixed);
        }
        // Swipe left → cycle between Variable and One-off
        else {
          final next = widget.current == TransactionClassification.variable
              ? TransactionClassification.oneoff
              : TransactionClassification.variable;
          widget.onClassify(next);
        }
        return false; // Don't actually dismiss
      },
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: const Color(0xFF5B6EF5),
        icon: Icons.repeat_rounded,
        label: 'Fixed',
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: widget.current == TransactionClassification.variable
            ? const Color.fromARGB(255, 182, 146, 89)
            : const Color(0xFF00BFA5),
        icon: widget.current == TransactionClassification.variable
            ? Icons.flash_on_rounded
            : Icons.waves_rounded,
        label: widget.current == TransactionClassification.variable
            ? 'One-off'
            : 'Variable',
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: color.withOpacity(widget.isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Transaction info row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: tx.categoryIcon != null
                          ? Icon(
                              IconConstants.getIconByCode(tx.categoryIcon!),
                              color: color,
                              size: 20,
                            )
                          : Icon(
                              Icons.receipt_long_rounded,
                              color: color,
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tx.categoryName ?? 'Uncategorized',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Amount
                            CurrencyText(
                              amount: tx.amount,
                              sign: '₹ ',
                              amountStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                color: theme.colorScheme.error,
                              ),
                              symbolStyle: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.error.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (tx.subCategory != null &&
                                tx.subCategory!.isNotEmpty)
                              Flexible(
                                child: Text(
                                  '${tx.subCategory}  ·  ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            Text(
                              _formatDate(tx.date),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                            ),
                            if (widget.autoGuess != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_fix_high_rounded,
                                      size: 9,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      widget.isAutoGuess
                                          ? 'AUTO · ${widget.autoGuess!.confidenceLabel}'
                                          : '${widget.autoGuess!.classification.emoji} ${widget.autoGuess!.classification.label}',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (tx.notes != null && tx.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '"${tx.notes}"',
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Classification bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _showPicker
                  ? _ClassificationPicker(
                      current: widget.current,
                      onSelect: (clf) {
                        widget.onClassify(clf);
                        setState(() => _showPicker = false);
                      },
                    )
                  : Row(
                      children: [
                        // Current badge (tap to open picker)
                        GestureDetector(
                          onTap: () => setState(() => _showPicker = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.current.emoji,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.current.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.expand_more_rounded,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Quick change buttons
                        _QuickBtn(
                          label: '🔁',
                          active:
                              widget.current == TransactionClassification.fixed,
                          color: const Color(0xFF5B6EF5),
                          onTap: () => widget.onClassify(
                            TransactionClassification.fixed,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _QuickBtn(
                          label: '🌊',
                          active:
                              widget.current ==
                              TransactionClassification.variable,
                          color: const Color(0xFF00BFA5),
                          onTap: () => widget.onClassify(
                            TransactionClassification.variable,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _QuickBtn(
                          label: '⚡',
                          active:
                              widget.current ==
                              TransactionClassification.oneoff,
                          color: const Color.fromARGB(255, 182, 146, 89),
                          onTap: () => widget.onClassify(
                            TransactionClassification.oneoff,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static const _months = [
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
}

// ---------------------------------------------------------------------------
// Inline classification picker (shown when badge is tapped)
// ---------------------------------------------------------------------------
class _ClassificationPicker extends StatelessWidget {
  final TransactionClassification current;
  final ValueChanged<TransactionClassification> onSelect;

  const _ClassificationPicker({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PickerBtn(
            emoji: '🔁',
            label: 'Fixed',
            color: const Color(0xFF5B6EF5),
            isSelected: current == TransactionClassification.fixed,
            onTap: () => onSelect(TransactionClassification.fixed),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PickerBtn(
            emoji: '🌊',
            label: 'Variable',
            color: const Color(0xFF00BFA5),
            isSelected: current == TransactionClassification.variable,
            onTap: () => onSelect(TransactionClassification.variable),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PickerBtn(
            emoji: '⚡',
            label: 'One-off',
            color: const Color.fromARGB(255, 182, 146, 89),
            isSelected: current == TransactionClassification.oneoff,
            onTap: () => onSelect(TransactionClassification.oneoff),
          ),
        ),
      ],
    );
  }
}

class _PickerBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickerBtn({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small quick-tap button (emoji only)
// ---------------------------------------------------------------------------
class _QuickBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(active ? 0.0 : 0.3)),
        ),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 14))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipe background overlay
// ---------------------------------------------------------------------------
class _SwipeBg extends StatelessWidget {
  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend chip
// ---------------------------------------------------------------------------
class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
