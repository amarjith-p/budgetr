import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/models/transaction_category_model.dart';
import '../../../core/services/category_service.dart';
import '../../../core/widgets/modern_loader.dart';
import '../../../core/constants/icon_constants.dart';
// --- New Design System Imports ---
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/aurora_scaffold.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_fab.dart';
import '../../../core/widgets/glass_bottom_sheet.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CategoryService _service = CategoryService();
  int _selectedTabIndex = 0;

  late Stream<List<TransactionCategoryModel>> _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream = _service.getCategories();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRestoreDefaults() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset to Defaults?"),
        content: const Text(
          "This will DELETE all your custom categories and revert any changes made to default ones.\n\nAre you sure you want to start fresh?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Reset All"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: ModernLoader()),
      );
    }

    try {
      await _service.resetToDefaults();
      if (mounted) {
        Navigator.pop(context); // Close Loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All categories reset to system defaults."),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      accentColor1: AppColors.electricPink,
      accentColor2: AppColors.royalBlue,

      appBar: GlassAppBar(
        title: "Categories",
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            color: AppColors.deepVoid,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.glassBorder),
            ),
            onSelected: (val) {
              if (val == 'restore') _handleRestoreDefaults();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: AppColors.dangerRed, size: 20),
                    SizedBox(width: 12),
                    Text(
                      "Reset to Defaults",
                      style: TextStyle(color: AppColors.dangerRed),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              _buildSyncedSlidingToggle(),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<TransactionCategoryModel>>(
                  stream: _categoriesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: ModernLoader());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final allCategories = snapshot.data!;
                    final expenses = allCategories
                        .where((c) => c.type == 'Expense')
                        .toList();
                    final income = allCategories
                        .where((c) => c.type == 'Income')
                        .toList();

                    return TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildCategoryList(expenses, AppColors.electricPink),
                        _buildCategoryList(income, AppColors.successGreen),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          GlassFAB(
            label: "Add Category",
            icon: Icons.add_rounded,
            onTap: () => _showAddEditSheet(context, null),
            accentColor: AppColors.royalBlue,
          ),
        ],
      ),
    );
  }

  void _showAddEditSheet(
    BuildContext context,
    TransactionCategoryModel? category,
  ) {
    final initialType =
        category?.type ?? (_tabController.index == 0 ? 'Expense' : 'Income');

    GlassBottomSheet.show(
      context,
      child: _ModernAddEditCategorySheet(
        category: category,
        initialType: initialType,
        service: _service,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category?"),
        content: const Text(
          "This will remove the category from selection. Existing transactions will remain unaffected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _service.deleteCategory(id);
              Navigator.pop(ctx);
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                color: AppColors.dangerRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncedSlidingToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          final double value = _tabController.animation!.value;
          final double alignmentX = (value * 2) - 1;

          final Color indicatorColor = Color.lerp(
            AppColors.electricPink,
            AppColors.successGreen,
            value,
          )!;

          return Stack(
            children: [
              Align(
                alignment: Alignment(alignmentX, 0),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: indicatorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: indicatorColor.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: indicatorColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildAnimatedText("EXPENSE", 0, value),
                  _buildAnimatedText("INCOME", 1, value),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedText(String label, int index, double animationValue) {
    final double dist = (animationValue - index).abs();
    final bool isActive = dist < 0.5;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _tabController.animateTo(index);
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? Colors.white : Colors.white54,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 60,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "No categories found",
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    List<TransactionCategoryModel> categories,
    Color themeColor,
  ) {
    if (categories.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _CategoryCard(
          category: categories[index],
          themeColor: themeColor,
          onEdit: () => _showAddEditSheet(context, categories[index]),
          onDelete: () => _confirmDelete(context, categories[index].id),
        );
      },
    );
  }
}

class _ModernAddEditCategorySheet extends StatefulWidget {
  final TransactionCategoryModel? category;
  final String initialType;
  final CategoryService service;

  const _ModernAddEditCategorySheet({
    this.category,
    required this.initialType,
    required this.service,
  });

  @override
  State<_ModernAddEditCategorySheet> createState() =>
      _ModernAddEditCategorySheetState();
}

class _ModernAddEditCategorySheetState
    extends State<_ModernAddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _subCtrl;

  final FocusNode _nameNode = FocusNode();
  final FocusNode _subNode = FocusNode();

  late List<String> _currentSubs;
  late int _selectedIconCode;
  late String _type;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _subCtrl = TextEditingController();
    _currentSubs = widget.category != null
        ? List.from(widget.category!.subCategories)
        : [];
    _currentSubs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    _selectedIconCode = widget.category?.iconCode ?? Icons.category.codePoint;
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameNode.dispose();
    _subNode.dispose();
    _nameCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We keep accent for small details, but NOT for the main button
    final accentColor = _type == 'Income'
        ? AppColors.successGreen
        : AppColors.electricPink;

    // WRAP CONTENT FIX: No Expanded here, just Padding + Column(min)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hug content height
          children: [
            const SizedBox(height: 12),
            Text(
              widget.category == null ? "Create New Category" : "Edit Category",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      _nameNode.unfocus();
                      _subNode.unfocus();
                      final code = await GlassBottomSheet.show<int>(
                        context,
                        child: const _IconPickerSheet(),
                      );
                      if (code != null)
                        setState(() => _selectedIconCode = code);
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.glassFill,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            IconConstants.getIconByCode(_selectedIconCode),
                            color: Colors.white,
                            size: 40,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextFormField(
                    focusNode: _nameNode,
                    controller: _nameCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Category Name",
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  if (widget.category == null) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.glassFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildTypeOption("Expense", AppColors.electricPink),
                          _buildTypeOption("Income", AppColors.successGreen),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "SUB-CATEGORIES",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    focusNode: _subNode,
                    controller: _subCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add sub-category (e.g. Uber, Groceries)",
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add_circle, color: accentColor),
                        onPressed: _addSubCategory,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _addSubCategory(),
                  ),
                  const SizedBox(height: 16),

                  if (_currentSubs.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        runSpacing: 8,
                        children: _currentSubs
                            .map(
                              (s) => Chip(
                                label: Text(
                                  s,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: AppColors.glassFill,
                                deleteIcon: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white54,
                                ),
                                onDeleted: () =>
                                    setState(() => _currentSubs.remove(s)),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.all(4),
                                side: BorderSide(color: AppColors.glassBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide.none,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // PROFESSIONAL BUTTON DESIGN
                  // No Gradient, no neon. Solid Royal Blue.
                  // Radius 12 for professional look (less rounded).
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.royalBlue, // Standard Primary
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.glassBorder),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.category == null
                                  ? "Create Category"
                                  : "Save Changes",
                              style: const TextStyle(
                                color: Colors.white, // High Contrast
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSubCategory() {
    final val = _subCtrl.text.trim();
    if (val.isEmpty) return;
    if (_currentSubs.any((s) => s.toLowerCase() == val.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'$val' already added!"),
          backgroundColor: AppColors.vibrantOrange,
        ),
      );
      return;
    }
    setState(() {
      _currentSubs.add(val);
      _currentSubs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      _subCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final name = _nameCtrl.text.trim();
      final isDuplicate = await widget.service.checkDuplicate(
        name,
        _type,
        excludeId: widget.category?.id,
      );
      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Category '$name' already exists."),
              backgroundColor: AppColors.dangerRed,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      if (widget.category == null) {
        await widget.service.addCategory(
          name,
          _type,
          _currentSubs,
          _selectedIconCode,
        );
      } else {
        await widget.service.updateCategory(
          TransactionCategoryModel(
            id: widget.category!.id,
            name: name,
            type: _type,
            subCategories: _currentSubs,
            iconCode: _selectedIconCode,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTypeOption(String label, Color color) {
    final isSelected = _type == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final TransactionCategoryModel category;
  final Color themeColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.themeColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.category_outlined;
    if (widget.category.iconCode != null) {
      icon = IconConstants.getIconByCode(widget.category.iconCode!);
    }

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isExpanded
                ? widget.themeColor.withOpacity(0.5)
                : AppColors.glassBorder,
            width: 1,
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.themeColor.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(icon, color: widget.themeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.category.subCategories.length} sub-categories",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 16),
                          if (widget.category.subCategories.isEmpty)
                            Text(
                              "No sub-categories defined.",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.category.subCategories
                                  .map(
                                    (sub) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.glassFill,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.glassBorder,
                                        ),
                                      ),
                                      child: Text(
                                        sub,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _ActionButton(
                                icon: Icons.edit_outlined,
                                label: "Edit",
                                color: Colors.white,
                                onTap: widget.onEdit,
                              ),
                              const SizedBox(width: 12),
                              _ActionButton(
                                icon: Icons.delete_outline,
                                label: "Delete",
                                color: AppColors.dangerRed,
                                onTap: widget.onDelete,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPickerSheet extends StatefulWidget {
  const _IconPickerSheet();

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // WRAP CONTENT: We rely on GlassBottomSheet's Flexible behavior.
    // For a picker with GridView, we might WANT it to expand, but for now we follow the rule.
    // We give it a fixed height for usability, or let it wrap if content is small.
    // However, a GridView typically needs bounded height.
    // We will use a Container with a max height constraint here just for the picker.

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height *
            0.7, // Picker needs height to scroll
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              "Select Icon",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search icons...",
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildGroupedList(IconConstants.iconGroups)
                  : _buildSearchResults(IconConstants.iconGroups),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(List<IconGroup> groups) {
    List<IconGroup> filtered = groups;
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final group = filtered[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.title.toUpperCase(),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: group.icons.length,
              itemBuilder: (context, i) => _buildIconTile(group.icons[i]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(List<IconGroup> groups) {
    List<IconMetadata> flatSearchResults = [];
    for (var group in groups) {
      for (var meta in group.icons) {
        if (meta.tags.any((t) => t.contains(_searchQuery.toLowerCase()))) {
          flatSearchResults.add(meta);
        }
      }
    }
    if (flatSearchResults.isEmpty)
      return Center(
        child: Text(
          "No icons found",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: flatSearchResults.length,
      itemBuilder: (context, index) => _buildIconTile(flatSearchResults[index]),
    );
  }

  Widget _buildIconTile(IconMetadata meta) {
    return InkWell(
      onTap: () => Navigator.pop(context, meta.icon.codePoint),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(meta.icon, color: Colors.white70, size: 24),
      ),
    );
  }
}
