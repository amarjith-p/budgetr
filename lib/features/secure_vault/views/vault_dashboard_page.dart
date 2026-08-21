import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/vault_provider.dart';
import '../models/vault_models.dart';
import 'vault_record_form_page.dart';

class VaultDashboardPage extends ConsumerStatefulWidget {
  const VaultDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<VaultDashboardPage> createState() => _VaultDashboardPageState();
}

class _VaultDashboardPageState extends ConsumerState<VaultDashboardPage> {
  @override
  void initState() {
    super.initState();
    _initScreenProtection();
  }

  void _initScreenProtection() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    ScreenProtector.protectDataLeakageOff();
    super.dispose();
  }

  void _lockVault() {
    HapticFeedback.heavyImpact();
    ref.read(vaultProvider.notifier).lockVault();
    Navigator.pop(context);
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0, top: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.folder_special_rounded,
            size: 16,
            color: color.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(vaultRecordsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF080C14), // Deep Space Blue/Black
      appBar: ModernAppBar(
        title: 'Secure Vault',
        subtitle: 'AES-256 GCM ENCRYPTION',
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () {
          ref.read(vaultProvider.notifier).lockVault();
          Navigator.pop(context);
        },
        trailingIcon: Icons.lock_outline_rounded,
        onTrailingPressed: _lockVault,
        extraIconColor: Colors.redAccent,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VaultRecordFormPage()),
          );
        },
        icon: Icons.add_moderator_rounded,
        label: 'Add Secret',
      ),
      body: Column(
        children: [
          // --- FUTURISTIC PULSING BANNER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: const Border(
                bottom: BorderSide(color: Colors.cyanAccent, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _PulsingDot(),
                const SizedBox(width: 8),
                Text(
                  'DECRYPTED SESSION ACTIVE',
                  style: TextStyle(
                    color: Colors.cyanAccent.shade100,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
              error: (e, st) => Center(
                child: Text(
                  'Decryption Error: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 80,
                          color: Colors.cyanAccent.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'VAULT IS EMPTY',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Store highly sensitive data safely.',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                // --- GROUP INTO SECTIONS ---
                final credentials = records
                    .where((r) => r.recordType == 'Credential')
                    .toList();
                final cards = records
                    .where((r) => r.recordType == 'Card')
                    .toList();

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  // --- FIX: 120px BOTTOM PADDING TO CLEAR THE FAB ---
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    if (credentials.isNotEmpty) ...[
                      _buildSectionHeader('CREDENTIALS', Colors.greenAccent),
                      ...credentials.map(
                        (r) => _FuturisticVaultCard(record: r, ref: ref),
                      ),
                    ],
                    if (cards.isNotEmpty) ...[
                      if (credentials.isNotEmpty) const SizedBox(height: 16),
                      _buildSectionHeader(
                        'CREDIT / DEBIT CARDS',
                        Colors.cyanAccent,
                      ),
                      ...cards.map(
                        (r) => _FuturisticVaultCard(record: r, ref: ref),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- FUTURISTIC EXPANDING CARD ---
class _FuturisticVaultCard extends StatefulWidget {
  final DecryptedVaultRecord record;
  final WidgetRef ref;

  const _FuturisticVaultCard({required this.record, required this.ref});

  @override
  State<_FuturisticVaultCard> createState() => _FuturisticVaultCardState();
}

class _FuturisticVaultCardState extends State<_FuturisticVaultCard> {
  bool _isExpanded = false;

  void _handleDelete() {
    ConfirmationBottomSheet.show(
      context,
      title: 'Delete Secret?',
      description:
          'This will permanently remove the decrypted data. This cannot be undone.',
      confirmText: 'DELETE',
      isDestructive: true,
      onConfirm: () async {
        await widget.ref
            .read(vaultProvider.notifier)
            .deleteRecord(widget.record.id);
        widget.ref.invalidate(vaultRecordsProvider);
      },
    );
  }

  void _handleEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VaultRecordFormPage(existingRecord: widget.record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCard = widget.record.recordType == 'Card';
    final accentColor = isCard ? Colors.cyanAccent : Colors.greenAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isExpanded = !_isExpanded);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121826),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isExpanded
                  ? accentColor.withOpacity(0.8)
                  : accentColor.withOpacity(0.2),
              width: _isExpanded ? 1.5 : 1.0,
            ),
            boxShadow: _isExpanded
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Icon(
                      isCard
                          ? Icons.credit_card_rounded
                          : Icons.password_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.record.recordName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCard
                              ? 'CARD DATA // TAP TO ${_isExpanded ? 'LOCK' : 'DECRYPT'}'
                              : 'CREDENTIAL // TAP TO ${_isExpanded ? 'LOCK' : 'DECRYPT'}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: accentColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: accentColor.withOpacity(0.5),
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        isCard
                            ? _buildCardDetails(
                                widget.record.payload as CardPayload,
                                accentColor,
                              )
                            : _buildCredentialDetails(
                                widget.record.payload as CredentialPayload,
                                accentColor,
                              ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Colors.white10),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _handleEdit();
                              },
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                              label: const Text(
                                'EDIT',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _handleDelete,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                              label: const Text(
                                'DELETE',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
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
  }

  // --- FIX: SET ALL isSecret PARAMETERS TO TRUE ---
  Widget _buildCredentialDetails(CredentialPayload payload, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payload.username.isNotEmpty)
          _SecretRow(
            label: 'USERNAME / EMAIL',
            value: payload.username,
            isSecret: true,
            accentColor: accentColor,
          ),
        if (payload.password.isNotEmpty)
          _SecretRow(
            label: 'PASSWORD',
            value: payload.password,
            isSecret: true,
            accentColor: accentColor,
          ),
        if (payload.secondaryPassword?.isNotEmpty == true)
          _SecretRow(
            label: 'SEC. PASSWORD',
            value: payload.secondaryPassword!,
            isSecret: true,
            accentColor: accentColor,
          ),
        if (payload.urlOrApp?.isNotEmpty == true)
          _SecretRow(
            label: 'URL / APP',
            value: payload.urlOrApp!,
            isSecret: true,
            accentColor: accentColor,
          ),
        if (payload.notes?.isNotEmpty == true)
          _SecretRow(
            label: 'NOTES',
            value: payload.notes!,
            isSecret: true,
            accentColor: accentColor,
          ),
      ],
    );
  }

  Widget _buildCardDetails(CardPayload payload, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payload.bankProvider.isNotEmpty)
          _SecretRow(
            label: 'BANK / PROVIDER',
            value: payload.bankProvider,
            isSecret: true,
            accentColor: accentColor,
          ),
        if (payload.cardNumber.isNotEmpty)
          _SecretRow(
            label: 'CARD NUMBER',
            value: payload.cardNumber,
            isSecret: true,
            accentColor: accentColor,
          ),
        Row(
          children: [
            Expanded(
              child: _SecretRow(
                label: 'VALID FROM',
                value: payload.validFrom,
                isSecret: true,
                accentColor: accentColor,
              ),
            ),
            Expanded(
              child: _SecretRow(
                label: 'VALID TO',
                value: payload.validTo,
                isSecret: true,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _SecretRow(
                label: 'CVV',
                value: payload.cvv,
                isSecret: true,
                accentColor: accentColor,
              ),
            ),
            Expanded(
              child: _SecretRow(
                label: 'PIN',
                value: payload.pin,
                isSecret: true,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
        if (payload.otherDetails?.isNotEmpty == true)
          _SecretRow(
            label: 'NOTES',
            value: payload.otherDetails!,
            isSecret: true,
            accentColor: accentColor,
          ),
      ],
    );
  }
}

// --- TERMINAL STYLE SECRET ROW ---
class _SecretRow extends StatefulWidget {
  final String label;
  final String value;
  final bool isSecret;
  final Color accentColor;

  const _SecretRow({
    required this.label,
    required this.value,
    required this.isSecret,
    required this.accentColor,
  });

  @override
  State<_SecretRow> createState() => _SecretRowState();
}

class _SecretRowState extends State<_SecretRow> {
  bool _isRevealed = false;

  void _copyToClipboard(BuildContext context) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: widget.value));
    CustomSnackbars.showSuccess(context, message: 'Copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = (widget.isSecret && !_isRevealed)
        ? '••••••••'
        : widget.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '> ${widget.label}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: widget.accentColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (widget.isSecret)
                IconButton(
                  icon: Icon(
                    _isRevealed
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                  ),
                  color: Colors.white54,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isRevealed = !_isRevealed);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: Colors.white54,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => _copyToClipboard(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.cyanAccent,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.cyanAccent, blurRadius: 4)],
        ),
      ),
    );
  }
}
