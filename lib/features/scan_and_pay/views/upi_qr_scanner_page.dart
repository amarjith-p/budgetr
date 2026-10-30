// lib/features/scan_and_pay/views/upi_qr_scanner_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/custom_snackbars.dart';
import '../components/manual_upi_entry_sheet.dart';
import '../models/upi_payment_models.dart';
import 'upi_payment_form_page.dart';

class UpiQrScannerPage extends StatefulWidget {
  const UpiQrScannerPage({super.key});

  @override
  State<UpiQrScannerPage> createState() => _UpiQrScannerPageState();
}

class _UpiQrScannerPageState extends State<UpiQrScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        final upiData = UpiQrData.tryParse(raw);
        if (upiData != null) {
          _isProcessing = true;
          HapticFeedback.mediumImpact();
          await _controller.stop();

          if (!mounted) return;

          // Open dedicated UpiPaymentFormPage
          final launched = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => UpiPaymentFormPage(qrData: upiData),
            ),
          );

          if (!mounted) return;

          if (launched == true) {
            Navigator.pop(context, true);
            return;
          } else {
            _isProcessing = false;
            await _controller.start();
          }
          break;
        } else {
          _showNonUpiWarning();
        }
      }
    }
  }

  void _showNonUpiWarning() {
    if (_isProcessing) return;
    _isProcessing = true;
    HapticFeedback.lightImpact();

    CustomSnackbars.showError(
      context,
      message: 'Not a recognized UPI QR code. Please scan a merchant or UPI QR.',
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  void _toggleTorch() {
    HapticFeedback.selectionClick();
    _controller.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  Future<void> _handleManualUpiEntry() async {
    HapticFeedback.lightImpact();
    await _controller.stop();

    if (!mounted) return;

    final manualData = await ManualUpiEntrySheet.show(context);

    if (!mounted) return;

    if (manualData != null) {
      final launched = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => UpiPaymentFormPage(qrData: manualData),
        ),
      );

      if (!mounted) return;

      if (launched == true) {
        Navigator.pop(context, true);
        return;
      }
    }

    // Resume camera if user backed out
    _isProcessing = false;
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final boxSize = (size.width * 0.72).clamp(240.0, 310.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: ModernAppBar(
        title: 'Scan & Pay',
        subtitle: 'INSTANT UPI SCANNER',
        leadingIcon: Icons.close_rounded,
        trailingIcon: _isTorchOn
            ? Icons.flash_on_rounded
            : Icons.flash_off_rounded,
        onTrailingPressed: _toggleTorch,
      ),
      body: Stack(
        children: [
          // Live Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          // Dark vignette overlay with square transparent window
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.2),
                  child: Container(
                    width: boxSize,
                    height: boxSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reticle Frame with Animated Scan Bar
          Align(
            alignment: const Alignment(0, -0.2),
            child: SizedBox(
              width: boxSize,
              height: boxSize,
              child: Stack(
                children: [
                  // Corner brackets
                  _buildCornerBracket(Alignment.topLeft, top: true, left: true, theme: theme),
                  _buildCornerBracket(Alignment.topRight, top: true, left: false, theme: theme),
                  _buildCornerBracket(Alignment.bottomLeft, top: false, left: true, theme: theme),
                  _buildCornerBracket(Alignment.bottomRight, top: false, left: false, theme: theme),

                  // Animated Scanning Laser Line
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (ctx, child) {
                      return Positioned(
                        top: _scanAnimation.value * (boxSize - 4),
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(alpha: 0.1),
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(alpha: 0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Panel: Scan Hint + Direct UPI Entry Button
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan Hint pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 15),
                      SizedBox(width: 8),
                      Text(
                        'Align QR code inside the frame to pay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Screen-size Manual UPI Entry Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _handleManualUpiEntry,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.alternate_email_rounded,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                    ),
                    label: const Text(
                      'ENTER UPI ID / NUMBER MANUALLY',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E24),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket(
    Alignment alignment, {
    required bool top,
    required bool left,
    required ThemeData theme,
  }) {
    const double length = 26;
    const double thickness = 3.5;
    final color = theme.colorScheme.primary;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: length,
        height: length,
        child: Stack(
          children: [
            // Horizontal bar
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(
                width: length,
                height: thickness,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
            // Vertical bar
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(
                width: thickness,
                height: length,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
