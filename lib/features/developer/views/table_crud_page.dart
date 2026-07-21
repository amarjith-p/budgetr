import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    // Dynamically fetch all data from the selected table
    final result = await db.customSelect('SELECT * FROM ${widget.table.actualTableName}').get();
    setState(() {
      _rows = result;
      _isLoading = false;
    });
  }

  Future<void> _deleteRow(Map<String, dynamic> rowData) async {
    final db = ref.read(databaseProvider);
    
    // Find the primary key column (default to 'id')
    final pkCol = widget.table.$primaryKey.firstOrNull?.name ?? 'id';
    final pkValue = rowData[pkCol];

    if (pkValue == null) {
      CustomSnackbars.showError(context, message: 'Cannot delete: No Primary Key found.');
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
              // INSERT
              final placeholders = List.filled(values.length, '?').join(', ');
              final colNames = columns.join(', ');
              await db.customInsert(
                'INSERT INTO ${widget.table.actualTableName} ($colNames) VALUES ($placeholders)',
                variables: values.map((v) => drift.Variable(v)).toList(),
              );
            } else {
              // UPDATE
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
              CustomSnackbars.showSuccess(context, message: 'Saved successfully');
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
    return Scaffold(
      appBar: ModernAppBar(
        title: widget.table.actualTableName,
        subtitle: 'TABLE DATA',
        trailingIcon: Icons.add_rounded,
        onTrailingPressed: () => _openEditor(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(child: Text('Table is empty.'))
              : ListView.builder(
                  padding: DesignTokens.pagePadding,
                  itemCount: _rows.length,
                  itemBuilder: (context, index) {
                    final rowData = _rows[index].data;
                    return BoxySlidableCard(
                      key: ValueKey(rowData.toString()),
                      onEdit: () => _openEditor(existingData: rowData),
                      onDelete: () {
                        ConfirmationBottomSheet.show(
                          context,
                          title: 'Delete Row?',
                          description: 'This will permanently remove this data.',
                          isDestructive: true,
                          onConfirm: () => _deleteRow(rowData),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: rowData.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
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
    // Generate a controller for every column in the table definition
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
      
      // Basic type casting based on Drift definitions
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
                width: 40, height: 4,
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
                  keyboardType: column.type == drift.DriftSqlType.int || column.type == drift.DriftSqlType.double 
                      ? const TextInputType.numberWithOptions(decimal: true) 
                      : TextInputType.text,
                ),
              );
            }).toList(),
            const SizedBox(height: DesignTokens.spacingMd),
            ModernBoxyButton(
              onPressed: _submit,
              label: 'SAVE TO DB',
            ),
          ],
        ),
      ),
    );
  }
}