import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart'; // Import local_auth
import 'package:flutter/services.dart';
import '../../../core/models/percentage_config_model.dart';
import '../../../core/services/firestore_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService();
  final LocalAuthentication auth = LocalAuthentication(); // Auth instance

  bool _isLoading = true;
  bool _isEditing = false; // Track edit mode
  List<CategoryConfig> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _settingsService.getPercentageConfig();
      setState(() {
        _categories = config.categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Authentication Logic
  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        // Fallback for emulators or devices without security
        setState(() => _isEditing = true);
        return;
      }

      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to edit budget configurations',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Pattern as fallback
        ),
      );
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auth Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isEditing = authenticated;
      });
      if (authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edit mode enabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _addCategory() {
    setState(() {
      _categories.add(CategoryConfig(name: '', percentage: 0.0, note: ''));
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

      try {
        await _settingsService.setPercentageConfig(
          PercentageConfig(categories: _categories),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false; // Lock after saving
          });
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
          // Show Lock icon when locked, Add button when editing
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.lock_outline),
              onPressed: _authenticate,
              tooltip: 'Unlock to Edit',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addCategory,
              tooltip: 'Add Bucket',
            ),
            IconButton(
              icon: const Icon(Icons.lock_open),
              onPressed: () => setState(() => _isEditing = false),
              tooltip: 'Lock Editing',
            ),
          ],
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
                      _isEditing
                          ? 'Drag to reorder. Total must equal 100%.'
                          : 'View Only Mode. Tap the lock icon to edit.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _isEditing ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _categories.length,
                      buildDefaultDragHandles:
                          _isEditing, // Disable drag when locked
                      onReorder: (oldIndex, newIndex) {
                        if (!_isEditing) return;
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
                  if (_isEditing) // Only show Save button when editing
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
    // Style for disabled inputs
    final inputDecoration = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
      filled: !_isEditing,
      fillColor: Colors.transparent,
    );

    return Card(
      key: ValueKey(_categories[index]),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isEditing
          ? Theme.of(context).cardColor
          : Theme.of(context).cardColor.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing)
                  const Padding(
                    padding: EdgeInsets.only(top: 14, right: 12),
                    child: Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: _categories[index].name,
                    enabled: _isEditing,
                    decoration: inputDecoration.copyWith(labelText: 'Name'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                    onChanged: (val) => _categories[index].name = val,
                    onSaved: (val) => _categories[index].name = val!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _categories[index].percentage.toStringAsFixed(
                      0,
                    ),
                    enabled: _isEditing,
                    decoration: inputDecoration.copyWith(
                      labelText: '%',
                      suffixText: '%',
                    ),
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
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _removeCategory(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _categories[index].note,
              enabled: _isEditing,
              decoration: inputDecoration.copyWith(
                labelText: 'Note',
                prefixIcon: const Icon(Icons.notes, size: 18),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (val) => _categories[index].note = val,
              onSaved: (val) => _categories[index].note = val ?? '',
            ),
          ],
        ),
      ),
    );
  }
}
