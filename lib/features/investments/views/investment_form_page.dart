import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../providers/investment_provider.dart';

class InvestmentFormPage extends ConsumerStatefulWidget {
  final Investment? existingInvestment;

  const InvestmentFormPage({Key? key, this.existingInvestment})
    : super(key: key);

  @override
  ConsumerState<InvestmentFormPage> createState() => _InvestmentFormPageState();
}

class _InvestmentFormPageState extends ConsumerState<InvestmentFormPage> {
  final _formKey = GlobalKey<FormState>();

  // 1-5. Basics
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  // 6-10. Financials
  final _initialAmtCtrl = TextEditingController();
  final _targetAmtCtrl = TextEditingController();
  final _expectedReturnCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // 11-13. Portfolio Details
  final _folioCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  final _brokerCtrl = TextEditingController();

  // 14-18. Links & Notes
  final _linkedAccCtrl = TextEditingController();
  final _linkedIfscCtrl = TextEditingController();
  final _linkedBankCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // --- NEW: FOCUS NODES FOR ENTER-TO-NEXT ---
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _providerFocus = FocusNode();
  final FocusNode _urlFocus = FocusNode();
  final FocusNode _initialAmtFocus = FocusNode();
  final FocusNode _targetAmtFocus = FocusNode();
  final FocusNode _expectedReturnFocus = FocusNode();
  final FocusNode _folioFocus = FocusNode();
  final FocusNode _unitsFocus = FocusNode();
  final FocusNode _brokerFocus = FocusNode();
  final FocusNode _linkedAccFocus = FocusNode();
  final FocusNode _linkedIfscFocus = FocusNode();
  final FocusNode _linkedBankFocus = FocusNode();
  final FocusNode _purposeFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  late final List<FocusNode> _allFocusNodes = [
    _nameFocus,
    _providerFocus,
    _urlFocus,
    _initialAmtFocus,
    _targetAmtFocus,
    _expectedReturnFocus,
    _folioFocus,
    _unitsFocus,
    _brokerFocus,
    _linkedAccFocus,
    _linkedIfscFocus,
    _linkedBankFocus,
    _purposeFocus,
    _notesFocus,
  ];

  final List<String> _investmentTypes = [
    'Mutual Fund',
    'Stocks',
    'Bonds',
    'Fixed Deposit',
    'Recurring Deposit',
    'P2P Lending',
    'Savings Account',
    'Others',
  ];

  @override
  void initState() {
    super.initState();

    // Smooth scrolling listener for all focus nodes
    for (var node in _allFocusNodes) {
      node.addListener(() {
        if (node.hasFocus) {
          Future.delayed(const Duration(milliseconds: 150), () {
            final ctx = node.context;
            if (ctx != null && mounted) {
              Scrollable.ensureVisible(
                ctx,
                alignment: 0.5,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
              );
            }
          });
        }
      });
    }

    final inv = widget.existingInvestment;
    if (inv != null) {
      _nameCtrl.text = inv.name;
      _typeCtrl.text = inv.type;
      _providerCtrl.text = inv.provider;
      _urlCtrl.text = inv.providerUrl ?? '';
      _tagCtrl.text = inv.specialTag ?? '';
      _initialAmtCtrl.text = inv.initialAmount.toStringAsFixed(2);
      _targetAmtCtrl.text = inv.targetAmount?.toStringAsFixed(2) ?? '';
      _expectedReturnCtrl.text = inv.expectedReturn?.toStringAsFixed(2) ?? '';
      _startDate = inv.startDate;
      _endDate = inv.expectedEndDate;
      _folioCtrl.text = inv.folioNo ?? '';
      _unitsCtrl.text = inv.units?.toStringAsFixed(4) ?? '';
      _brokerCtrl.text = inv.brokerName ?? '';
      _linkedAccCtrl.text = inv.linkedAccountNo ?? '';
      _linkedIfscCtrl.text = inv.linkedAccountIfsc ?? '';
      _linkedBankCtrl.text = inv.linkedBankName ?? '';
      _purposeCtrl.text = inv.purpose ?? '';
      _notesCtrl.text = inv.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _providerCtrl.dispose();
    _urlCtrl.dispose();
    _tagCtrl.dispose();
    _initialAmtCtrl.dispose();
    _targetAmtCtrl.dispose();
    _expectedReturnCtrl.dispose();
    _folioCtrl.dispose();
    _unitsCtrl.dispose();
    _brokerCtrl.dispose();
    _linkedAccCtrl.dispose();
    _linkedIfscCtrl.dispose();
    _linkedBankCtrl.dispose();
    _purposeCtrl.dispose();
    _notesCtrl.dispose();

    // Dispose Focus Nodes safely
    for (var node in _allFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _selectType() async {
    HapticFeedback.lightImpact();
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Investment Type',
      items: _investmentTypes,
      selectedValue: _typeCtrl.text,
    );
    if (selected != null) setState(() => _typeCtrl.text = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.selectionClick();

    final isEdit = widget.existingInvestment != null;
    final String id = isEdit
        ? widget.existingInvestment!.id
        : const Uuid().v4();

    // STRICTLY OMIT `initialAmount` and `currentValue` HERE
    final entry = InvestmentsCompanion(
      id: drift.Value(id),
      name: drift.Value(_nameCtrl.text.trim()),
      type: drift.Value(_typeCtrl.text.trim()),
      provider: drift.Value(_providerCtrl.text.trim()),
      providerUrl: drift.Value(_urlCtrl.text.trim()),
      specialTag: drift.Value(_tagCtrl.text.trim()),
      targetAmount: drift.Value(double.tryParse(_targetAmtCtrl.text)),
      startDate: drift.Value(_startDate),
      expectedEndDate: drift.Value(_endDate),
      expectedReturn: drift.Value(double.tryParse(_expectedReturnCtrl.text)),
      folioNo: drift.Value(_folioCtrl.text.trim()),
      units: drift.Value(double.tryParse(_unitsCtrl.text)),
      brokerName: drift.Value(_brokerCtrl.text.trim()),
      linkedAccountNo: drift.Value(_linkedAccCtrl.text.trim()),
      linkedAccountIfsc: drift.Value(_linkedIfscCtrl.text.trim()),
      linkedBankName: drift.Value(_linkedBankCtrl.text.trim()),
      purpose: drift.Value(_purposeCtrl.text.trim()),
      notes: drift.Value(_notesCtrl.text.trim()),
    );

    final success = await ref
        .read(investmentActionProvider.notifier)
        .saveInvestment(
          entry: entry,
          isEdit: isEdit,
          initialDeposit: isEdit ? null : double.parse(_initialAmtCtrl.text),
        );

    if (success && mounted) Navigator.pop(context);
  }

  Widget _buildHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionState = ref.watch(investmentActionProvider);
    final isEdit = widget.existingInvestment != null;

    final investmentsList =
        ref.watch(investmentsStreamProvider).asData?.value ?? [];
    final List<String> existingTags = investmentsList
        .map((e) => e.specialTag ?? '')
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: isEdit ? 'Edit Asset' : 'New Investment',
        subtitle: 'ASSET DETAILS',
        leadingIcon: Icons.close_rounded,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader('BASIC INFO', theme),
              ModernBoxyInput(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_providerFocus),
                labelText: 'Investment Name *',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectType,
                borderRadius: BorderRadius.circular(8),
                child: AbsorbPointer(
                  child: ModernBoxyInput(
                    controller: _typeCtrl,
                    labelText: 'Investment Type *',
                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ModernBoxyInput(
                controller: _providerCtrl,
                focusNode: _providerFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_urlFocus),
                labelText: 'Provider (e.g., Zerodha, HDFC) *',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ModernBoxyInput(
                controller: _urlCtrl,
                focusNode: _urlFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(
                  context,
                ).nextFocus(), // Drops into Autocomplete
                labelText: 'Provider Website URL (For Icon)',
              ),
              const SizedBox(height: 12),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return existingTags.where(
                    (tag) => tag.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                onSelected: (String selection) {
                  _tagCtrl.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      if (controller.text.isEmpty && _tagCtrl.text.isNotEmpty) {
                        controller.text = _tagCtrl.text;
                      }
                      controller.addListener(() {
                        _tagCtrl.text = controller.text;
                      });
                      return ModernBoxyInput(
                        controller: controller,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          onFieldSubmitted(); // Call internal Autocomplete submit
                          FocusScope.of(context).requestFocus(
                            isEdit ? _targetAmtFocus : _initialAmtFocus,
                          );
                        },
                        labelText: 'Special ID / Tag *',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width:
                            MediaQuery.of(context).size.width -
                            (DesignTokens.spacingLg * 2),
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: theme.dividerColor),
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              _buildHeader('FINANCIALS', theme),

              // --- UPGRADED PROFESSIONAL WARNING BANNER ---
              if (isEdit)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Financial balances are locked in this form. To ensure mathematical precision, please manage all deposits, withdrawals, and market updates exclusively through the Activity Ledger.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: isEdit
                        ? AbsorbPointer(
                            child: ModernBoxyInput(
                              controller: TextEditingController(
                                text:
                                    '₹ ${widget.existingInvestment!.initialAmount.toStringAsFixed(2)}',
                              ),
                              labelText: 'Total Invested (Auto)',
                              readOnly: true,
                            ),
                          )
                        : ModernBoxyInput(
                            controller: _initialAmtCtrl,
                            focusNode: _initialAmtFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_targetAmtFocus),
                            labelText: 'Initial Amount (₹) *',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Required';
                              final val = double.tryParse(v);
                              if (val == null || val <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernBoxyInput(
                      controller: _targetAmtCtrl,
                      focusNode: _targetAmtFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(
                        context,
                      ).requestFocus(_expectedReturnFocus),
                      labelText: 'Target Amount (₹)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: AbsorbPointer(
                        child: ModernBoxyInput(
                          controller: TextEditingController(
                            text:
                                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          ),
                          labelText: 'Start Date',
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: AbsorbPointer(
                        child: ModernBoxyInput(
                          controller: TextEditingController(
                            text: _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : '',
                          ),
                          labelText: 'Expected End Date',
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ModernBoxyInput(
                controller: _expectedReturnCtrl,
                focusNode: _expectedReturnFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_folioFocus),
                labelText: 'Expected Return (%)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              _buildHeader('PORTFOLIO DATA', theme),
              ModernBoxyInput(
                controller: _folioCtrl,
                focusNode: _folioFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_unitsFocus),
                labelText: 'Folio / Account No.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ModernBoxyInput(
                      controller: _unitsCtrl,
                      focusNode: _unitsFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_brokerFocus),
                      labelText: 'Units / Qty',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernBoxyInput(
                      controller: _brokerCtrl,
                      focusNode: _brokerFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_linkedAccFocus),
                      labelText: 'Broker Name',
                    ),
                  ),
                ],
              ),

              _buildHeader('LINKED BANK (Auto-Debit/Credit)', theme),
              ModernBoxyInput(
                controller: _linkedAccCtrl,
                focusNode: _linkedAccFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_linkedIfscFocus),
                labelText: 'Linked Account No.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ModernBoxyInput(
                      controller: _linkedIfscCtrl,
                      focusNode: _linkedIfscFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_linkedBankFocus),
                      labelText: 'IFSC Code',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernBoxyInput(
                      controller: _linkedBankCtrl,
                      focusNode: _linkedBankFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_purposeFocus),
                      labelText: 'Bank Name',
                    ),
                  ),
                ],
              ),

              _buildHeader('EXTRA DETAILS', theme),
              ModernBoxyInput(
                controller: _purposeCtrl,
                focusNode: _purposeFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_notesFocus),
                labelText: 'Purpose of Investment',
              ),
              const SizedBox(height: 12),
              ModernBoxyInput(
                controller: _notesCtrl,
                focusNode: _notesFocus,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                labelText: 'Notes',
              ),

              const SizedBox(height: 40),
              ModernBoxyButton(
                onPressed: _submit,
                label: isEdit ? 'SAVE CHANGES' : 'SAVE INVESTMENT',
                isLoading: actionState.isLoading,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
