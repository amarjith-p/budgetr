// lib/features/settings/views/factory_reset_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/factory_reset_provider.dart';

class FactoryResetPage extends ConsumerStatefulWidget {
  const FactoryResetPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FactoryResetPage> createState() => _FactoryResetPageState();
}

class _FactoryResetPageState extends ConsumerState<FactoryResetPage> {
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _isResetting = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(_validateInput);
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _confirmCtrl.text.trim();
    // Strict case-sensitive validation
    final isValid = text == 'RESET';
    if (_isButtonEnabled != isValid) {
      setState(() => _isButtonEnabled = isValid);
    }
  }

  Future<void> _executeReset() async {
    if (!_isButtonEnabled || _isResetting) return;

    HapticFeedback.heavyImpact();
    setState(() => _isResetting = true);

    try {
      final service = ref.read(factoryResetProvider);
      await service.performFactoryReset();
      // No need to set _isResetting to false because the app will instantly restart
    } catch (e) {
      if (mounted) {
        setState(() => _isResetting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Reset failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Factory Reset',
        subtitle: 'DANGER ZONE',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // ClampingScrollPhysics makes the screen static if the content fits
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingLg,
                  vertical: DesignTokens.spacingMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- HERO WARNING SECTION ---
                    const SizedBox(height: 8), // Tightened from 16
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20), // Tightened from 24
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.error.withOpacity(0.2),
                            width: 8,
                          ),
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          size: 48, // Tightened from 56
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Tightened from 24
                    Text(
                      'Complete Data Wipe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action is irreversible. All local data will be permanently destroyed and cannot be recovered.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24), // Tightened from 40
                    // --- CONSEQUENCES BENTO CARD ---
                    Text(
                      'WHAT WILL BE DELETED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16), // Tightened from 20
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.2),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.2 : 0.02,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConsequenceRow(
                            theme: theme,
                            icon: Icons.account_balance_wallet_rounded,
                            title: 'Financial Data',
                            subtitle: 'All accounts, transactions, and budgets',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ), // Tightened from 12
                            child: Divider(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.3),
                            ),
                          ),
                          _buildConsequenceRow(
                            theme: theme,
                            icon: Icons.security_rounded,
                            title: 'Security & Vault',
                            subtitle:
                                'App PIN, Biometrics, and encrypted secrets',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ), // Tightened from 12
                            child: Divider(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.3),
                            ),
                          ),
                          _buildConsequenceRow(
                            theme: theme,
                            icon: Icons.memory_rounded,
                            title: 'Automations',
                            subtitle:
                                'Smart Inbox rules, trackers, and reminders',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), // Tightened from 40
                    // --- CONFIRMATION INPUT CARD ---
                    Text(
                      'ACTION REQUIRED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16), // Tightened from 20
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isButtonEnabled
                              ? theme.colorScheme.error.withOpacity(0.5)
                              : theme.dividerColor.withOpacity(
                                  isDark ? 0.3 : 0.6,
                                ),
                          width: _isButtonEnabled ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type RESET to confirm',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ModernBoxyInput(
                            controller: _confirmCtrl,
                            labelText: 'Confirmation',
                            hintText: 'RESET',
                            keyboardType: TextInputType.text,
                          ),
                        ],
                      ),
                    ),
                    // Removed the bottom 40px spacing completely
                  ],
                ),
              ),
            ),

            // --- BOTTOM ACTION BUTTON ---
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingLg),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                ),
              ),
              child: ModernBoxyButton(
                onPressed: _isButtonEnabled
                    ? _executeReset
                    : null, // Replaced empty callback with null to trigger disabled styling correctly
                label: 'PERMANENTLY RESET & WIPE APP DATA',
                icon: Icons.delete_forever_rounded,
                isLoading: _isResetting,
                backgroundColor: _isButtonEnabled
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.15),
                foregroundColor: _isButtonEnabled
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsequenceRow({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8), // Tightened from 10
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18, // Tightened from 20
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(width: 12), // Tightened from 16
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
