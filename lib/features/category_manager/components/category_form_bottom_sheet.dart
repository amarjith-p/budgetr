import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/icon_constants.dart';
import '../../../core/models/transaction_category_model.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../providers/category_provider.dart';
import 'icon_picker_bottom_sheet.dart';

class CategoryFormBottomSheet extends ConsumerStatefulWidget {
  final String initialType;
  final TransactionCategoryModel? categoryToEdit;

  const CategoryFormBottomSheet({
    Key? key,
    required this.initialType,
    this.categoryToEdit,
  }) : super(key: key);

  @override
  ConsumerState<CategoryFormBottomSheet> createState() => _CategoryFormBottomSheetState();
}

class _CategoryFormBottomSheetState extends ConsumerState<CategoryFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedType;
  late int _selectedIconCode;
  List<TextEditingController> _subCategoryControllers = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.categoryToEdit?.type ?? widget.initialType;
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _selectedIconCode = widget.categoryToEdit?.iconCode ?? Icons.category_outlined.codePoint;

    if (widget.categoryToEdit != null && widget.categoryToEdit!.subCategories.isNotEmpty) {
      for (var sub in widget.categoryToEdit!.subCategories) {
        _subCategoryControllers.add(TextEditingController(text: sub));
      }
    } else {
      _subCategoryControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _subCategoryControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _openIconPicker() async {
    final int? pickedIconCode = await IconPickerBottomSheet.show(context);
    if (pickedIconCode != null) {
      setState(() => _selectedIconCode = pickedIconCode);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final subs = _subCategoryControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final success = await ref.read(categoryActionProvider.notifier).saveCategory(
      id: widget.categoryToEdit?.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      subs: subs,
      iconCode: _selectedIconCode,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final actionState = ref.watch(categoryActionProvider);
    final theme = Theme.of(context);
    final boxyRadius = BorderRadius.circular(DesignTokens.spacingXs);

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + DesignTokens.spacingLg,
        left: DesignTokens.spacingLg,
        right: DesignTokens.spacingLg,
        top: DesignTokens.spacingSm, 
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtle Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                widget.categoryToEdit == null ? 'New $_selectedType' : 'Edit $_selectedType',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),

              // MAIN INPUT: Icon + Global Boxy Input
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _openIconPicker,
                    borderRadius: boxyRadius,
                    child: Container(
                      height: 56, // Matches standard OutlineInputBorder height
                      width: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: boxyRadius,
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.2),
                      ),
                      child: Icon(
                        IconConstants.getIconByCode(_selectedIconCode),
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: ModernBoxyInput(
                      controller: _nameController,
                      labelText: 'Category Name',
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: DesignTokens.spacingLg),
              
              // SUBCATEGORIES SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subcategories', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  
                  // SLEEK & MINIMAL "ADD" ICON
                  InkWell(
                    onTap: () => setState(() => _subCategoryControllers.add(TextEditingController())),
                    borderRadius: BorderRadius.circular(4.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Add', 
                            style: TextStyle(
                              color: theme.colorScheme.primary, 
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              
              // LIST OF GLOBAL BOXY INPUTS
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subCategoryControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
                    child: ModernBoxyInput(
                      controller: _subCategoryControllers[index],
                      labelText: 'Subcategory ${index + 1}',
                      // SLEEK & MINIMAL "DELETE" ICON
                      // Using a muted close icon instead of a heavy trashcan
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: theme.hintColor, // Muted grey so it doesn't distract
                        splashRadius: 20,
                        tooltip: 'Remove',
                        onPressed: () {
                          setState(() {
                            _subCategoryControllers[index].dispose();
                            _subCategoryControllers.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: DesignTokens.spacingMd),
              
              Row(
                children: [
                  Expanded(
                    child: ModernBoxyButton(
                      onPressed: () => Navigator.pop(context),
                      label: 'Close',
                      isOutlined: true, // Uses our new hollow variant
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    flex: 2, // Gives the primary action a slightly wider presence
                    child: ModernBoxyButton(
                      onPressed: _submitForm,
                      label: 'Save',
                      isLoading: actionState.isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}