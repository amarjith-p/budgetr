import 'package:flutter/material.dart';
import '../../../core/models/percentage_config_model.dart';
import '../../../core/services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  bool _isLoading = true;
  List<CategoryConfig> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _firestoreService.getPercentageConfig();
      setState(() {
        // Load exactly as saved in DB (User's manual order)
        _categories = config.categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addCategory() {
    setState(() {
      _categories.add(CategoryConfig(name: '', percentage: 0.0));
    });
  }

  void _removeCategory(int index) {
    setState(() {
      _categories.removeAt(index);
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      double total = _categories.fold(0, (sum, item) => sum + item.percentage);

      if ((total - 100.0).abs() > 0.1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Total percentage must be 100% (Current: ${total.toStringAsFixed(1)}%)',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // NO AUTO SORTING: Save exactly the order the user arranged
      try {
        await _firestoreService.setPercentageConfig(
          PercentageConfig(categories: _categories),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocation Buckets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCategory,
            tooltip: 'Add Bucket',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Drag and drop to reorder. This order will be used throughout the app.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _categories.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _categories.removeAt(oldIndex);
                          _categories.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildCategoryRow(index);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveSettings,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryRow(int index) {
    return Card(
      key: ValueKey(_categories[index]), // Key MUST be unique object/id
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 18, left: 8, right: 8),
              child: Icon(Icons.drag_handle, color: Colors.grey),
            ),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: _categories[index].name,
                decoration: const InputDecoration(labelText: 'Bucket Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
                onChanged: (val) => _categories[index].name = val,
                onSaved: (val) => _categories[index].name = val!,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                initialValue: _categories[index].percentage.toStringAsFixed(0),
                decoration: const InputDecoration(labelText: ' %'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    double.tryParse(val ?? '') == null ? 'Invalid' : null,
                onChanged: (val) {
                  if (val.isNotEmpty && double.tryParse(val) != null) {
                    _categories[index].percentage = double.parse(val);
                  }
                },
                onSaved: (val) =>
                    _categories[index].percentage = double.parse(val!),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _removeCategory(index),
            ),
          ],
        ),
      ),
    );
  }
}
