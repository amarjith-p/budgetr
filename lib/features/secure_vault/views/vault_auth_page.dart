import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';

import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/vault_provider.dart';
import 'vault_dashboard_page.dart';

class VaultAuthPage extends ConsumerStatefulWidget {
  const VaultAuthPage({Key? key}) : super(key: key);

  @override
  ConsumerState<VaultAuthPage> createState() => _VaultAuthPageState();
}

class _VaultAuthPageState extends ConsumerState<VaultAuthPage>
    with SingleTickerProviderStateMixin {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _enableBiometrics = true;
  bool _isLoading = false;

  late AnimationController _dialController;

  @override
  void initState() {
    super.initState();
    _initScreenProtection();

    // Smooth rotating animation for the vault dial
    _dialController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  void _initScreenProtection() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    ScreenProtector.protectDataLeakageOff();
    _dialController.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit(VaultStateStatus status) async {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    final pwd = _passwordCtrl.text.trim();

    if (pwd.isEmpty) {
      CustomSnackbars.showError(context, message: 'Master Key is required');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 200));

    if (status == VaultStateStatus.setupRequired) {
      if (pwd != _confirmCtrl.text.trim()) {
        setState(() => _isLoading = false);
        CustomSnackbars.showError(context, message: 'Master Keys do not match');
        return;
      }
      if (pwd.length < 6) {
        setState(() => _isLoading = false);
        CustomSnackbars.showError(
          context,
          message: 'Master Key must be at least 6 characters',
        );
        return;
      }

      await ref.read(vaultProvider.notifier).setupVault(pwd, _enableBiometrics);
      _navigateToDashboard();
    } else {
      final success = await ref
          .read(vaultProvider.notifier)
          .unlockWithPassword(pwd);
      if (success) {
        _passwordCtrl.clear();
        _navigateToDashboard();
        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
        CustomSnackbars.showError(
          context,
          message: 'Access Denied: Incorrect Master Key',
        );
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _handleForgotAndReset() {
    FocusScope.of(context).unfocus();
    HapticFeedback.heavyImpact();
    ConfirmationBottomSheet.show(
      context,
      title: 'FACTORY RESET VAULT?',
      description:
          'WARNING: This will permanently vaporize ALL encrypted records. Since data is AES-256 encrypted, it is mathematically impossible to recover without the original password.\n\nAre you absolutely sure you want to breach and reset the vault?',
      confirmText: 'NUKE VAULT',
      isDestructive: true,
      onConfirm: () async {
        HapticFeedback.heavyImpact();
        await ref.read(vaultProvider.notifier).resetVault();
        _passwordCtrl.clear();
        _confirmCtrl.clear();
        if (mounted) {
          CustomSnackbars.showSuccess(
            context,
            message: 'Vault has been factory reset.',
          );
        }
      },
    );
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VaultDashboardPage()),
    );
  }

  Widget _buildVaultDial(bool isSetup, ThemeData theme) {
    final color = isSetup ? theme.colorScheme.primary : Colors.white;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Rotating Dial (Clockwise)
          AnimatedBuilder(
            animation: _dialController,
            builder: (_, __) => Transform.rotate(
              angle: _dialController.value * 2 * math.pi,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.1), width: 2),
                ),
                child: CustomPaint(
                  painter: _DialTicksPainter(color.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          // Inner Rotating Dial (Counter-Clockwise)
          AnimatedBuilder(
            animation: _dialController,
            builder: (_, __) => Transform.rotate(
              angle: -(_dialController.value * 2 * math.pi),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.15), width: 8),
                ),
                child: CustomPaint(
                  painter: _DialInnerPainter(color.withOpacity(0.4)),
                ),
              ),
            ),
          ),
          // Center Core
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withOpacity(0.1), Colors.black],
                radius: 1.0,
              ),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              isSetup ? Icons.lock_open_rounded : Icons.security_rounded,
              size: 40,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultState = ref.watch(vaultProvider);

    return Scaffold(
      backgroundColor:
          Colors.black, // Pure black background for absolute contrast
      body: vaultState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (state) {
          final isSetup = state.status == VaultStateStatus.setupRequired;

          return Stack(
            children: [
              // Deep Metallic/Radial Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0xFF1A1F2C), Colors.black],
                      center: Alignment(0, -0.3),
                      radius: 1.2,
                    ),
                  ),
                ),
              ),

              // Main Content wrapped in a scrollable LayoutBuilder
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const SizedBox(height: 60), // App Bar offset
                              const Spacer(flex: 1),

                              // Animated Vault Lock
                              _buildVaultDial(isSetup, theme),
                              const SizedBox(height: 32),

                              // High-end Typography Status
                              Text(
                                isSetup
                                    ? 'FORGE MASTER KEY'
                                    : 'AWAITING MASTER KEY',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 4.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  isSetup
                                      ? 'This key encrypts your data. It cannot be recovered.'
                                      : 'Encrypted Vault secured. Authentication required.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              const Spacer(flex: 2),

                              // Frosted Glass Bottom Input Panel
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(32),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 25,
                                    sigmaY: 25,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0F172A,
                                      ).withOpacity(0.6), // Slate 900
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.only(
                                      top: 32,
                                      left: 24,
                                      right: 24,
                                      bottom: 32, // Fixed: Standard padding
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Override theme specifically for this dark panel
                                        Theme(
                                          data: theme.copyWith(
                                            colorScheme: theme.colorScheme
                                                .copyWith(
                                                  surfaceContainerHighest:
                                                      Colors.black.withOpacity(
                                                        0.4,
                                                      ),
                                                  onSurface: Colors.white,
                                                  onSurfaceVariant:
                                                      Colors.white70,
                                                ),
                                          ),
                                          child: Column(
                                            children: [
                                              ModernBoxyInput(
                                                controller: _passwordCtrl,
                                                labelText: isSetup
                                                    ? 'New Master Key'
                                                    : 'Enter Master Key',
                                                obscureText: true,
                                                prefixIcon: Icon(
                                                  Icons.key_rounded,
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              if (isSetup) ...[
                                                const SizedBox(height: 16),
                                                ModernBoxyInput(
                                                  controller: _confirmCtrl,
                                                  labelText:
                                                      'Verify Master Key',
                                                  obscureText: true,
                                                  prefixIcon: Icon(
                                                    Icons.verified_user_rounded,
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white10,
                                                    ),
                                                  ),
                                                  child: SwitchListTile(
                                                    title: const Text(
                                                      'Enable Biometrics',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 13,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    value: _enableBiometrics,
                                                    activeColor: theme
                                                        .colorScheme
                                                        .primary,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    onChanged: (val) {
                                                      HapticFeedback.lightImpact();
                                                      setState(
                                                        () =>
                                                            _enableBiometrics =
                                                                val,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        if (!isSetup) ...[
                                          // Massive Biometric Button for existing users
                                          InkWell(
                                            onTap: () async {
                                              HapticFeedback.selectionClick();
                                              final success = await ref
                                                  .read(vaultProvider.notifier)
                                                  .unlockWithBiometric();
                                              if (success) {
                                                _navigateToDashboard();
                                              } else {
                                                CustomSnackbars.showError(
                                                  context,
                                                  message:
                                                      'Biometrics unavailable or failed.',
                                                );
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.fingerprint_rounded,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    size: 28,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'BIOMETRIC UNLOCK',
                                                    style: TextStyle(
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: 1.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ],

                                        ModernBoxyButton(
                                          onPressed: () =>
                                              _submit(state.status),
                                          label: isSetup
                                              ? 'INITIALIZE VAULT'
                                              : 'DECRYPT',
                                          isLoading: _isLoading,
                                        ),

                                        if (!isSetup) ...[
                                          const SizedBox(height: 24),
                                          Center(
                                            child: GestureDetector(
                                              onTap: _handleForgotAndReset,
                                              child: const Text(
                                                'FORGOT KEY? FACTORY RESET VAULT',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 10,
                                                  letterSpacing: 1.0,
                                                  decorationColor:
                                                      Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Custom Transparent App Bar (Fixed at top)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Text(
                            'AES-256 GCM',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- CUSTOM PAINTERS FOR VAULT DIAL ---

class _DialTicksPainter extends CustomPainter {
  final Color color;
  _DialTicksPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * math.pi / 180;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 12.0 : 6.0;

      final p1 = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      paint.strokeWidth = isMajor ? 3.0 : 1.5;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DialInnerPainter extends CustomPainter {
  final Color color;
  _DialInnerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw broken arcs to look like a mechanical lock mechanism
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi / 3,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.5 * math.pi,
      math.pi / 4,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
