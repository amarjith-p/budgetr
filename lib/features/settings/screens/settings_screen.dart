import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:ui';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/aurora_scaffold.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/modern_loader.dart';

import '../../../core/models/percentage_config_model.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService();
  final LocalAuthentication auth = LocalAuthentication();

  bool _isLoading = true;
  bool _isEditing = false;
  List<CategoryConfig> _categories = [];
  double _currentTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _calculateTotal() {
    double total = _categories.fold(0, (sum, item) => sum + item.percentage);
    setState(() {
      _currentTotal = total;
    });
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _settingsService.getPercentageConfig();
      setState(() {
        _categories = config.categories;
        _isLoading = false;
        _calculateTotal();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();

      if (!canCheck && !isSupported) {
        setState(() => _isEditing = true);
        return;
      }

      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to edit budget configurations',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auth Error: ${e.message}'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isEditing = authenticated;
      });
    }
  }

  void _addCategory() {
    setState(() {
      _categories.add(CategoryConfig(name: '', percentage: 0.0, note: ''));
      _calculateTotal();
    });
  }

  void _removeCategory(int index) {
    setState(() {
      _categories.removeAt(index);
      _calculateTotal();
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _calculateTotal();

      if ((_currentTotal - 100.0).abs() > 0.1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Total must be exactly 100% (Current: ${_currentTotal.toStringAsFixed(1)}%)',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.dangerRed,
              behavior: SnackBarBehavior.floating,
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
              backgroundColor: AppColors.successGreen,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.dangerRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      accentColor1: AppColors.royalBlue,
      accentColor2: AppColors.tealGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Budget Buckets',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.royalBlue.withOpacity(0.5),
                  ),
                ),
                child: const Icon(Icons.lock_outline, size: 18),
              ),
              onPressed: _authenticate,
              tooltip: 'Unlock to Edit',
            )
          else ...[
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: AppColors.successGreen,
                ),
              ),
              onPressed: _addCategory,
              tooltip: 'Add Bucket',
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.vibrantOrange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open,
                  size: 18,
                  color: AppColors.vibrantOrange,
                ),
              ),
              onPressed: () => setState(() => _isEditing = false),
              tooltip: 'Lock Editing',
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),

      // BODY NOW CONTAINS THE FOOTER IN A COLUMN
      body: _isLoading
          ? const Center(child: ModernLoader())
          : Column(
              children: [
                // 1. Content Area (Takes all available space above keyboard/footer)
                Expanded(
                  child: Column(
                    children: [
                      // Status Header
                      if (!_isEditing)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: 12,
                            backgroundColor: AppColors.royalBlue.withOpacity(
                              0.1,
                            ),
                            borderColor: AppColors.royalBlue.withOpacity(0.3),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color: AppColors.royalBlue.withOpacity(0.8),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    "Read-Only Mode. Tap the lock to modify splits.",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Reorderable List
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: ReorderableListView.builder(
                            // Reduced bottom padding because the footer is now separate
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            itemCount: _categories.length,
                            buildDefaultDragHandles: _isEditing,
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (BuildContext context, Widget? child) {
                                  return Material(
                                    elevation: 0,
                                    color: Colors.transparent,
                                    child: Transform.scale(
                                      scale: 1.05,
                                      child: child,
                                    ),
                                  );
                                },
                                child: child,
                              );
                            },
                            onReorder: (oldIndex, newIndex) {
                              if (!_isEditing) return;
                              setState(() {
                                if (oldIndex < newIndex) newIndex -= 1;
                                final item = _categories.removeAt(oldIndex);
                                _categories.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              return _buildProfessionalRow(index);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Edit Footer (Sits above keyboard)
                if (_isEditing) _buildEditFooter(),
              ],
            ),
    );
  }

  Widget _buildEditFooter() {
    Color statusColor = AppColors.dangerRed;
    if ((_currentTotal - 100.0).abs() < 0.1) {
      statusColor = AppColors.successGreen;
    } else if (_currentTotal < 100) {
      statusColor = AppColors.vibrantOrange;
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.deepVoid.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Allocation",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "${_currentTotal.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Animated Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentTotal / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: AppColors.royalBlue.withOpacity(0.5),
                  ).copyWith(elevation: MaterialStateProperty.all(8)),
                  child: const Text(
                    'Save Configuration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalRow(int index) {
    return Padding(
      key: ValueKey(_categories[index]),
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        child: Column(
          children: [
            // --- ROW 1: Header (Name & Delete) ---
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEditing
                          ? Icons.drag_handle_rounded
                          : Icons.pie_chart_outline,
                      color: AppColors.royalBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _categories[index].name,
                      enabled: _isEditing,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'Bucket Name',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                      onChanged: (val) => _categories[index].name = val,
                      onSaved: (val) => _categories[index].name = val!,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      icon: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.dangerRed.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.dangerRed,
                          size: 14,
                        ),
                      ),
                      onPressed: () => _removeCategory(index),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            // --- ROW 2: Controls (Allocation & Note) ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.royalBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ALLOCATION",
                          style: TextStyle(
                            color: AppColors.royalBlue.withOpacity(0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _categories[index].percentage
                                    .toStringAsFixed(0),
                                enabled: _isEditing,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  if (val.isNotEmpty &&
                                      double.tryParse(val) != null) {
                                    _categories[index].percentage =
                                        double.parse(val);
                                    _calculateTotal();
                                  }
                                },
                                onSaved: (val) =>
                                    _categories[index].percentage =
                                        double.parse(val!),
                              ),
                            ),
                            const Text(
                              "%",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Center(
                        child: TextFormField(
                          initialValue: _categories[index].note,
                          enabled: _isEditing,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Add a description...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            icon: Icon(
                              Icons.sticky_note_2_outlined,
                              color: Colors.white24,
                              size: 16,
                            ),
                          ),
                          onChanged: (val) => _categories[index].note = val,
                          onSaved: (val) => _categories[index].note = val ?? '',
                        ),
                      ),
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
}
