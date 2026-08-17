import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/vault_provider.dart';
import '../models/vault_models.dart';

class VaultRecordFormPage extends ConsumerStatefulWidget {
  final DecryptedVaultRecord? existingRecord;
  const VaultRecordFormPage({Key? key, this.existingRecord}) : super(key: key);

  @override
  ConsumerState<VaultRecordFormPage> createState() =>
      _VaultRecordFormPageState();
}

class _VaultRecordFormPageState extends ConsumerState<VaultRecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  int _typeIndex = 0;

  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _secPasswordCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _cardNumberCtrl;
  late TextEditingController _validFromCtrl;
  late TextEditingController _validToCtrl;
  late TextEditingController _cvvCtrl;
  late TextEditingController _pinCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initScreenProtection();

    // Pre-fill data if editing
    final isEdit = widget.existingRecord != null;
    _typeIndex = isEdit && widget.existingRecord!.recordType == 'Card' ? 1 : 0;

    _nameCtrl = TextEditingController(
      text: isEdit ? widget.existingRecord!.recordName : '',
    );

    // Credential fields
    final cred = isEdit && _typeIndex == 0
        ? widget.existingRecord!.payload as CredentialPayload
        : null;
    _usernameCtrl = TextEditingController(text: cred?.username ?? '');
    _passwordCtrl = TextEditingController(text: cred?.password ?? '');
    _secPasswordCtrl = TextEditingController(
      text: cred?.secondaryPassword ?? '',
    );
    _urlCtrl = TextEditingController(text: cred?.urlOrApp ?? '');

    // Card fields
    final card = isEdit && _typeIndex == 1
        ? widget.existingRecord!.payload as CardPayload
        : null;
    _bankCtrl = TextEditingController(text: card?.bankProvider ?? '');
    _cardNumberCtrl = TextEditingController(text: card?.cardNumber ?? '');
    _validFromCtrl = TextEditingController(text: card?.validFrom ?? '');
    _validToCtrl = TextEditingController(text: card?.validTo ?? '');
    _cvvCtrl = TextEditingController(text: card?.cvv ?? '');
    _pinCtrl = TextEditingController(text: card?.pin ?? '');

    _notesCtrl = TextEditingController(
      text: cred?.notes ?? card?.otherDetails ?? '',
    );
  }

  void _initScreenProtection() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    ScreenProtector.protectDataLeakageOff();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _secPasswordCtrl.dispose();
    _urlCtrl.dispose();
    _bankCtrl.dispose();
    _cardNumberCtrl.dispose();
    _validFromCtrl.dispose();
    _validToCtrl.dispose();
    _cvvCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    SystemChannels.textInput.invokeMethod('TextInput.hide');
    HapticFeedback.selectionClick();

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      VaultPayload payload;
      String recordType = _typeIndex == 0 ? 'Credential' : 'Card';

      if (_typeIndex == 0) {
        payload = CredentialPayload(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          secondaryPassword: _secPasswordCtrl.text.trim(),
          urlOrApp: _urlCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      } else {
        payload = CardPayload(
          bankProvider: _bankCtrl.text.trim(),
          cardNumber: _cardNumberCtrl.text.trim(),
          validFrom: _validFromCtrl.text.trim(),
          validTo: _validToCtrl.text.trim(),
          cvv: _cvvCtrl.text.trim(),
          pin: _pinCtrl.text.trim(),
          otherDetails: _notesCtrl.text.trim(),
        );
      }

      if (widget.existingRecord != null) {
        await ref
            .read(vaultProvider.notifier)
            .updateRecord(
              id: widget.existingRecord!.id,
              recordType: recordType,
              recordName: _nameCtrl.text.trim(),
              payload: payload,
            );
      } else {
        await ref
            .read(vaultProvider.notifier)
            .saveRecord(
              recordType: recordType,
              recordName: _nameCtrl.text.trim(),
              payload: payload,
            );
      }

      if (mounted) {
        ref.invalidate(vaultRecordsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        CustomSnackbars.showError(context, message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingRecord != null;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: ModernAppBar(
        title: isEditing ? 'Edit Secret' : 'Add Secret',
        subtitle: 'SECURE VAULT',
        leadingIcon: Icons.close_rounded,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: Colors.cyanAccent,
            onSurface: Colors.white,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ModernBoxyToggle(
                  labels: const ['Credential', 'Credit/Debit Card'],
                  selectedIndex: _typeIndex,
                  onSelected: (i) {
                    HapticFeedback.lightImpact();
                    setState(() => _typeIndex = i);
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ModernBoxyInput(
                      controller: _nameCtrl,
                      labelText: 'Record Name (e.g., Netflix Login)',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_typeIndex == 0) ...[
                      // --- MANDATORY USERNAME ---
                      ModernBoxyInput(
                        controller: _usernameCtrl,
                        labelText: 'Username / Email',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      ModernBoxyInput(
                        controller: _passwordCtrl,
                        labelText: 'Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      ModernBoxyInput(
                        controller: _secPasswordCtrl,
                        labelText: 'Secondary Password (Optional)',
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      ModernBoxyInput(
                        controller: _urlCtrl,
                        labelText: 'URL / App Name',
                      ),
                    ] else ...[
                      ModernBoxyInput(
                        controller: _bankCtrl,
                        labelText: 'Bank / Provider',
                      ),
                      const SizedBox(height: 16),
                      // --- MANDATORY CARD NUMBER ---
                      ModernBoxyInput(
                        controller: _cardNumberCtrl,
                        labelText: 'Card Number',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _validFromCtrl,
                              labelText: 'Valid From (MM/YY)',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _validToCtrl,
                              labelText: 'Valid To (MM/YY)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _cvvCtrl,
                              labelText: 'CVV',
                              obscureText: true,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _pinCtrl,
                              labelText: 'PIN',
                              obscureText: true,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    ModernBoxyInput(
                      controller: _notesCtrl,
                      labelText: 'Other Notes / Instructions',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),
                    ModernBoxyButton(
                      onPressed: _submit,
                      label: isEditing ? 'Update & Encrypt' : 'Encrypt & Save',
                      backgroundColor: Colors.cyanAccent.shade700,
                      foregroundColor: Colors.black,
                      isLoading: _isSaving,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
