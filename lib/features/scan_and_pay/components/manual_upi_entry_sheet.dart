// lib/features/scan_and_pay/components/manual_upi_entry_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/components/custom_snackbars.dart';
import '../models/upi_payment_models.dart';

class ManualUpiEntrySheet extends StatefulWidget {
  const ManualUpiEntrySheet({super.key});

  static Future<UpiQrData?> show(BuildContext context) {
    return showModalBottomSheet<UpiQrData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ManualUpiEntrySheet(),
    );
  }

  @override
  State<ManualUpiEntrySheet> createState() => _ManualUpiEntrySheetState();
}

class _ManualUpiEntrySheetState extends State<ManualUpiEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _upiCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _showValidationErrors = false;

  static const List<String> _allHandles = [
    '@okhdfcbank',
    '@okaxis',
    '@okicici',
    '@oksbi',
    '@paytm',
    '@ybl',
    '@ibl',
    '@axl',
    '@apl',
    '@barodampay',
    '@kotak',
    '@idfcbank',
    '@indus',
    '@federal',
    '@aubank',
    '@pnb',
    '@canarabank',
    '@unionbank',
    '@yesbank',
    '@upi',
    '@postbank',
    '@jupiteraxis',
    '@fifederal',
    '@slice',
    '@airtel',
    '@fbl',
    '@icici',
    '@sbi',
    '@hdfcbank',
    '@axisbank',
    '@hsbc',
    '@rbl',
    '@bandhan',
    '@sc',
    '@dbs',
  ];

  @override
  void dispose() {
    _upiCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Generates dynamic VPA suggestions capped at 5.
  /// If user enters prefix e.g. "amarjith", suggestions show "amarjith@okhdfcbank", etc.
  List<String> get _vpaSuggestions {
    final text = _upiCtrl.text.trim();
    if (text.isEmpty) {
      return _allHandles.take(5).toList();
    }

    if (text.contains('@')) {
      final atIndex = text.indexOf('@');
      final prefix = text.substring(0, atIndex);
      final handleQuery = text.substring(atIndex).toLowerCase();

      final matching = _allHandles
          .where((h) => h.toLowerCase().startsWith(handleQuery))
          .take(5)
          .toList();

      if (matching.isNotEmpty) {
        return matching
            .map((h) => prefix.isNotEmpty ? '$prefix$h' : h)
            .toList();
      }
      return const [];
    }

    // User has typed prefix only (e.g. "amarjith" or "9876543210")
    return _allHandles.take(5).map((h) => '$text$h').toList();
  }

  void _applySuggestion(String suggestion) {
    HapticFeedback.selectionClick();
    _upiCtrl.text = suggestion;
    _upiCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _upiCtrl.text.length),
    );
    setState(() {});
  }

  String? _validateUpiId(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'UPI ID is mandatory';
    }
    if (raw.contains(' ')) {
      return 'UPI ID cannot contain spaces';
    }
    if (!raw.contains('@')) {
      return 'Must include \'@\' and bank handle (e.g. name@okhdfcbank)';
    }

    final parts = raw.split('@');
    if (parts.length != 2) {
      return 'Invalid UPI ID format (must contain only one \'@\')';
    }

    final username = parts[0];
    final handle = parts[1];

    if (username.length < 2) {
      return 'Username must be at least 2 characters';
    }
    if (handle.length < 2) {
      return 'Bank handle must be at least 2 characters (e.g. @okaxis)';
    }

    // NPCI standard VPA regex
    final validVpaRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,64}@[a-zA-Z0-9]{2,30}$');
    if (!validVpaRegex.hasMatch(raw)) {
      return 'Enter a valid UPI ID (alphanumeric characters, dots, or hyphens)';
    }

    return null;
  }

  void _handleSubmit() {
    setState(() => _showValidationErrors = true);

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      CustomSnackbars.showError(
        context,
        message: 'Please enter a valid UPI ID to proceed',
      );
      return;
    }

    final upiId = _upiCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    HapticFeedback.mediumImpact();
    final qrData = UpiQrData.fromManual(
      pa: upiId,
      pn: name.isNotEmpty ? name : upiId.split('@').first.toUpperCase(),
      am: null, // Amount is entered on the Scan & Pay screen
    );

    Navigator.pop(context, qrData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final suggestions = _vpaSuggestions;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sheet Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.alternate_email_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ENTER UPI ID',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pay directly to any VPA, phone handle, or merchant',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // UPI ID / VPA Input with Strict Validator
                Row(
                  children: [
                    Text(
                      'UPI ID / VPA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '*',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _upiCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  validator: _validateUpiId,
                  decoration: InputDecoration(
                    hintText: 'e.g. amarjith@okhdfcbank or 9876543210@paytm',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.hintColor.withValues(alpha: 0.6),
                    ),
                    prefixIcon: const Icon(Icons.person_pin_rounded, size: 20),
                    suffixIcon: _upiCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _upiCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _upiCtrl.text.contains('@')
                        ? 'MATCHING HANDLES (MAX 5)'
                        : _upiCtrl.text.isNotEmpty
                        ? 'VPA SUGGESTIONS (MAX 5)'
                        : 'POPULAR HANDLES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: suggestions.map((suggestion) {
                      final isSelected = _upiCtrl.text == suggestion;
                      return InkWell(
                        onTap: () => _applySuggestion(suggestion),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  )
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.alternate_email_rounded,
                                size: 12,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Optional Payee Name
                Text(
                  'PAYEE NAME (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Ramesh Stores or Rahul Sharma',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.hintColor.withValues(alpha: 0.6),
                    ),
                    prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Screen-size Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PROCEED TO PAYMENT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
