import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/database/database_provider.dart';

class TableCrudPage extends ConsumerStatefulWidget {
  final drift.TableInfo table;

  const TableCrudPage({Key? key, required this.table}) : super(key: key);

  @override
  ConsumerState<TableCrudPage> createState() => _TableCrudPageState();
}

class _TableCrudPageState extends ConsumerState<TableCrudPage> {
  List<drift.QueryRow> _rows = [];
  bool _isLoading = true;

  // --- SEARCH STATE ---
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<int, GlobalKey> _rowKeys = {}; // Keys to track row positions
  Timer? _debounce;
  List<int> _matchIndices = [];
  int _currentMatchIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final result = await db
        .customSelect('SELECT * FROM ${widget.table.actualTableName}')
        .get();

    setState(() {
      _rows = result;
      _rowKeys.clear(); // Clear keys on fresh data
      _isLoading = false;
    });

    if (_searchCtrl.text.isNotEmpty) {
      _onSearchChanged(_searchCtrl.text);
    }
  }

  // --- SEARCH LOGIC ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        setState(() {
          _matchIndices.clear();
          _currentMatchIndex = 0;
        });
        return;
      }

      final List<int> matches = [];
      for (int i = 0; i < _rows.length; i++) {
        final rowData = _rows[i].data;
        bool hasMatch = false;
        for (var value in rowData.values) {
          if (value != null && value.toString().toLowerCase().contains(q)) {
            hasMatch = true;
            break;
          }
        }
        if (hasMatch) matches.add(i);
      }

      setState(() {
        _matchIndices = matches;
        _currentMatchIndex = 0;
      });

      if (_matchIndices.isNotEmpty) {
        _scrollToCurrentMatch();
      }
    });
  }

  void _nextMatch() {
    if (_matchIndices.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchIndices.length;
    });
    _scrollToCurrentMatch();
  }

  void _prevMatch() {
    if (_matchIndices.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchIndices.length) %
          _matchIndices.length;
    });
    _scrollToCurrentMatch();
  }

  // Focuses the match directly in the center of the screen
  void _scrollToCurrentMatch() {
    if (_matchIndices.isEmpty || !_scrollController.hasClients) return;

    final targetIndex = _matchIndices[_currentMatchIndex];
    final key = _rowKeys[targetIndex];

    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        alignment:
            0.5, // 0.5 aligns the widget exactly in the center of the viewport
      );
    } else {
      // Fallback for lazy-loaded items that aren't built yet
      final colCount = widget.table.$columns.length;
      final estimatedRowHeight = 40.0 + (colCount * 22.0);
      double targetOffset = targetIndex * estimatedRowHeight;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (targetOffset > maxScroll) targetOffset = maxScroll;

      _scrollController
          .animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          )
          .then((_) {
            // Try precise centering again after rough estimation
            if (key?.currentContext != null) {
              Scrollable.ensureVisible(
                key!.currentContext!,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                alignment: 0.5,
              );
            }
          });
    }
  }

  // --- TEXT HIGHLIGHTER ---
  Widget _buildHighlightedText(
    String text,
    String query,
    ThemeData theme,
    bool isCurrentMatch,
  ) {
    if (query.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 13));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch = lowerText.indexOf(lowerQuery, start);

    if (indexOfMatch == -1) {
      return Text(text, style: const TextStyle(fontSize: 13));
    }

    while (indexOfMatch != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }

      // Highlight exact matched keyword
      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + query.length),
          style: TextStyle(
            backgroundColor: isCurrentMatch
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.3),
            color: isCurrentMatch
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

      start = indexOfMatch + query.length;
      indexOfMatch = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
        children: spans,
      ),
    );
  }

  Future<void> _deleteRow(Map<String, dynamic> rowData) async {
    final db = ref.read(databaseProvider);
    final pkCol = widget.table.$primaryKey.firstOrNull?.name ?? 'id';
    final pkValue = rowData[pkCol];

    if (pkValue == null) {
      CustomSnackbars.showError(
        context,
        message: 'Cannot delete: No Primary Key found.',
      );
      return;
    }

    await db.customStatement(
      'DELETE FROM ${widget.table.actualTableName} WHERE $pkCol = ?',
      [pkValue],
    );
    CustomSnackbars.showSuccess(context, message: 'Row deleted');
    _fetchData();
  }

  void _openEditor({Map<String, dynamic>? existingData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => _DynamicFormSheet(
        table: widget.table,
        existingData: existingData,
        onSave: (Map<String, dynamic> newData) async {
          final db = ref.read(databaseProvider);
          final columns = newData.keys.toList();
          final values = newData.values.toList();

          try {
            if (existingData == null) {
              final placeholders = List.filled(values.length, '?').join(', ');
              final colNames = columns.join(', ');
              await db.customInsert(
                'INSERT INTO ${widget.table.actualTableName} ($colNames) VALUES ($placeholders)',
                variables: values.map((v) => drift.Variable(v)).toList(),
              );
            } else {
              final pkCol = widget.table.$primaryKey.firstOrNull?.name ?? 'id';
              final pkValue = existingData[pkCol];
              final setClause = columns.map((c) => '$c = ?').join(', ');

              await db.customStatement(
                'UPDATE ${widget.table.actualTableName} SET $setClause WHERE $pkCol = ?',
                [...values, pkValue],
              );
            }
            if (mounted) {
              Navigator.pop(ctx);
              CustomSnackbars.showSuccess(
                context,
                message: 'Saved successfully',
              );
              _fetchData();
            }
          } catch (e) {
            CustomSnackbars.showError(context, message: e.toString());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: widget.table.actualTableName,
        subtitle: 'TABLE DATA',
        trailingIcon: Icons.add_rounded,
        onTrailingPressed: () => _openEditor(),
      ),
      body: Column(
        children: [
          // --- SMART SEARCH BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search keyword...',
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (_matchIndices.isNotEmpty) ...[
                  Text(
                    '${_currentMatchIndex + 1} / ${_matchIndices.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                        color: theme.colorScheme.onSurfaceVariant,
                        visualDensity: VisualDensity.compact,
                        onPressed: _prevMatch,
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        color: theme.colorScheme.onSurfaceVariant,
                        visualDensity: VisualDensity.compact,
                        onPressed: _nextMatch,
                      ),
                    ],
                  ),
                ],
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _searchCtrl.clear();
                      _onSearchChanged('');
                      FocusScope.of(context).unfocus();
                    },
                  ),
              ],
            ),
          ),

          // --- TABLE DATA LIST ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                ? Center(
                    child: Text(
                      'Table is empty.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: DesignTokens.pagePadding,
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final rowData = _rows[index].data;

                      // Track keys for scrolling
                      final rowKey = _rowKeys.putIfAbsent(
                        index,
                        () => GlobalKey(),
                      );

                      // Match Highlighting Logic
                      final isMatch = _matchIndices.contains(index);
                      final isCurrentMatch =
                          _matchIndices.isNotEmpty &&
                          _matchIndices[_currentMatchIndex] == index;

                      return Padding(
                        key: rowKey,
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: BoxySlidableCard(
                          key: ValueKey(rowData.toString()),
                          onEdit: () => _openEditor(existingData: rowData),
                          onDelete: () {
                            ConfirmationBottomSheet.show(
                              context,
                              title: 'Delete Row?',
                              description:
                                  'This will permanently remove this data.',
                              isDestructive: true,
                              onConfirm: () => _deleteRow(rowData),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isCurrentMatch
                                  ? theme.colorScheme.primary.withOpacity(0.1)
                                  : theme.colorScheme.surface,
                              border: Border.all(
                                color: isCurrentMatch
                                    ? theme.colorScheme.primary
                                    : (isMatch
                                          ? theme.colorScheme.primary
                                                .withOpacity(0.4)
                                          : theme.dividerColor),
                                width: isCurrentMatch ? 2.0 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: rowData.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: _buildHighlightedText(
                                    '${entry.key}: ${entry.value}',
                                    _searchCtrl.text,
                                    theme,
                                    isCurrentMatch,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// A dynamic bottom sheet that automatically generates BoxyInputs for every column.
class _DynamicFormSheet extends StatefulWidget {
  final drift.TableInfo table;
  final Map<String, dynamic>? existingData;
  final Function(Map<String, dynamic>) onSave;

  const _DynamicFormSheet({
    required this.table,
    this.existingData,
    required this.onSave,
  });

  @override
  State<_DynamicFormSheet> createState() => _DynamicFormSheetState();
}

class _DynamicFormSheetState extends State<_DynamicFormSheet> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var column in widget.table.$columns) {
      final initialVal = widget.existingData?[column.name]?.toString() ?? '';
      _controllers[column.name] = TextEditingController(text: initialVal);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final Map<String, dynamic> result = {};
    for (var column in widget.table.$columns) {
      final text = _controllers[column.name]!.text.trim();

      if (column.type == drift.DriftSqlType.int) {
        result[column.name] = int.tryParse(text) ?? 0;
      } else if (column.type == drift.DriftSqlType.double) {
        result[column.name] = double.tryParse(text) ?? 0.0;
      } else {
        result[column.name] = text;
      }
    }
    widget.onSave(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + DesignTokens.spacingLg,
        left: DesignTokens.spacingLg,
        right: DesignTokens.spacingLg,
        top: DesignTokens.spacingSm,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existingData == null ? 'Insert Row' : 'Edit Row',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            ...widget.table.$columns.map((column) {
              return Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
                child: ModernBoxyInput(
                  controller: _controllers[column.name]!,
                  labelText: column.name,
                  keyboardType:
                      column.type == drift.DriftSqlType.int ||
                          column.type == drift.DriftSqlType.double
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                ),
              );
            }).toList(),
            const SizedBox(height: DesignTokens.spacingMd),
            ModernBoxyButton(onPressed: _submit, label: 'SAVE TO DB'),
          ],
        ),
      ),
    );
  }
}
