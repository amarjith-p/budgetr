import 'dart:ui';
import 'package:budgetr/core/components/custom_snackbars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/bento_card.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart'; 
import '../../../core/theme/app_theme.dart';
import '../providers/budget_bucket_provider.dart';
import '../models/bucket_draft_model.dart';

class BudgetBucketsPage extends ConsumerStatefulWidget {
  const BudgetBucketsPage({super.key});

  @override
  ConsumerState<BudgetBucketsPage> createState() => _BudgetBucketsPageState();
}

class _BudgetBucketsPageState extends ConsumerState<BudgetBucketsPage> {
  bool _isEditing = false;
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _handleUnlockAttempt() async {
    final shouldProceed = await ConfirmationBottomSheet.show(
      context,
      title: 'Unlock Core Allocations',
      description: 'These Bucket Allocation percentages are crucial. Modifying them changes how your Budget Buckets are distributed. Are you sure you want to edit?',
      confirmText: 'PROCEED',
      onConfirm: () {}, 
    );

    if (shouldProceed != true) return;

    bool authenticated = false;
    try {
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();

      if (!canCheck && !isSupported) {
        setState(() => _isEditing = true);
        return;
      }

      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to modify core budget allocations',
      );
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth Error: ${e.message}'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (mounted && authenticated) {
      setState(() => _isEditing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buckets = ref.watch(bucketDraftProvider);
    final totalPercentage = ref.watch(bucketDraftProvider.notifier).totalPercentage;
    
    final activeBuckets = buckets.where((b) => b.name.trim().isNotEmpty || b.percentage > 0).toList();
    
    final isTotalValid = totalPercentage == 100.0;
    
    // 2. Only require active buckets to be fully filled
    final areFieldsFilled = activeBuckets.isNotEmpty && 
                            activeBuckets.every((b) => b.name.trim().isNotEmpty && b.percentage > 0);
                            
    final canSave = isTotalValid && areFieldsFilled;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? const Color(0xFF3A86FF) : theme.colorScheme.primary;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // Scrub empty fields when the user leaves the screen
        ref.read(bucketDraftProvider.notifier).scrubEmptyBuckets();
      },
      child: Scaffold(
      appBar: ModernAppBar(
        title: 'ALLOCATION',
        subtitle: 'MONTHLY BUCKETS',
        trailingIcon: _isEditing ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        onTrailingPressed: _isEditing 
              ? () {
                  // Scrub empty fields when locking the UI
                  ref.read(bucketDraftProvider.notifier).scrubEmptyBuckets();
                  setState(() => _isEditing = false);
                }
              : _handleUnlockAttempt,
        ),
      // FocusTraversalGroup ensures Flutter maps out the "Next" jumps perfectly down the list
      body: FocusTraversalGroup(
        child: Stack(
          children: [
            // ─── DYNAMIC LIST ───
            Positioned.fill(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 200.0), 
                itemCount: _isEditing ? buckets.length + 1 : buckets.length,
                itemBuilder: (context, index) {
                  
                  if (_isEditing && index == buckets.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: BentoCard(
                        height: 64,
                        backgroundColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                        borderColor: theme.colorScheme.primary.withOpacity(0.3),
                        onTap: () => ref.read(bucketDraftProvider.notifier).addBucket(),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ADD NEW BUCKET',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final bucket = buckets[index];
                  
                  return _BucketInputCard(bucket: bucket, isEditing: _isEditing);
                },
              ),
            ),
            
            // ─── PREMIUM FROSTED GLASS ACTION BAR ───
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.85),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB).withOpacity(0.5),
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      minimum: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL ALLOCATED',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: isTotalValid 
                                      ? (isDark ? Colors.white70 : theme.colorScheme.primary) 
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${totalPercentage.toStringAsFixed(1)}%',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: isTotalValid 
                                      ? successColor
                                      : (totalPercentage > 100 ? theme.colorScheme.error : theme.colorScheme.onSurface),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          Container(
                            height: 8, 
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                              ),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (totalPercentage / 100).clamp(0.0, 1.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutQuart,
                                decoration: BoxDecoration(
                                  color: isTotalValid 
                                      ? successColor 
                                      : (totalPercentage > 100 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: isTotalValid ? [
                                    BoxShadow(
                                      color: successColor.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ] : null,
                                ),
                              ),
                            ),
                          ),
                          
                          if (_isEditing) ...[
                            const SizedBox(height: 16),
                            
                            if (isTotalValid && !areFieldsFilled)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(
                                  "All buckets must have a name and percentage.",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              
                            SizedBox(
                              width: double.infinity,
                              height: 56, 
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canSave ? successColor : (isDark ? Colors.white : Colors.black), 
                                  foregroundColor: canSave ? Colors.white : (isDark ? Colors.black : Colors.white),
                                  disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                                  disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
                                  elevation: 0, 
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8), 
                                  ),
                                ),
                                onPressed: canSave
    ? () async {
        // 1. Pause and ask for confirmation
        final shouldProceed = await ConfirmationBottomSheet.show(
          context,
          title: 'Confirm Allocation',
          description: 'This will replace all of your existing budget buckets with the new allocations. Do you want to proceed?',
          confirmText: 'CONFIRM',
          onConfirm: () {}, // Handled by the boolean return
        );

        // 2. If the user dismisses the sheet or clicks cancel, stop here
        if (shouldProceed != true) return;

        // 3. Proceed with the database save
        final success = await ref.read(bucketDraftProvider.notifier).saveBuckets();
        
        if (context.mounted) {
          if (success) {
            CustomSnackbars.showSuccess(context, message: 'Allocations saved successfully!');
            Navigator.pop(context); 
          } else {
            CustomSnackbars.showError(context, message: 'Failed to save allocations.');
          }
        }
      }
    : null,
                                child: Text(
                                  'CONFIRM ALLOCATION',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              "Tap the Lock Icon above to edit",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

// ─── STATEFUL CARD IMPLEMENTATION ───

class _BucketInputCard extends ConsumerStatefulWidget {
  final BucketDraft bucket;
  final bool isEditing; 
  
  const _BucketInputCard({
    super.key, 
    required this.bucket, 
    required this.isEditing,
  });

  @override
  ConsumerState<_BucketInputCard> createState() => _BucketInputCardState();
}

class _BucketInputCardState extends ConsumerState<_BucketInputCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _percentageController;
  
  // Track the last valid input to seamlessly revert if they cross 100%
  String _lastValidPercentage = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bucket.name);
    _percentageController = TextEditingController(
      text: widget.bucket.percentage > 0 ? widget.bucket.percentage.toString() : '',
    );
    
    _lastValidPercentage = _percentageController.text;

    _nameController.addListener(() {
      ref.read(bucketDraftProvider.notifier).updateName(widget.bucket.id, _nameController.text);
    });

    _percentageController.addListener(_onPercentageChanged);
  }

  void _onPercentageChanged() {
    final text = _percentageController.text;
    
    // Prevent infinite loops if we are just reverting the text programmatically
    if (text == _lastValidPercentage) return;

    final doubleValue = double.tryParse(text) ?? 0.0;
    
    // Calculate the total of ALL OTHER buckets excluding this one
    final buckets = ref.read(bucketDraftProvider);
    final otherTotal = buckets
        .where((b) => b.id != widget.bucket.id)
        .fold(0.0, (sum, b) => sum + b.percentage);
    
    // Check if adding this new value exceeds 100%
    if (otherTotal + doubleValue > 100.0) {
      // Revert the text to the last valid state
      _percentageController.text = _lastValidPercentage;
      
      // Move the cursor to the end of the input field so it feels natural
      _percentageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _percentageController.text.length)
      );
      
      // Notify the user globally
      CustomSnackbars.showError(context, message: 'Total allocation cannot exceed 100%');
      return; // Stop processing
    }

    // If valid, accept it as the new valid state and update the provider
    _lastValidPercentage = text;
    ref.read(bucketDraftProvider.notifier).updatePercentage(widget.bucket.id, doubleValue);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.isEditing ? 1.0 : 0.6, 
      child: BoxySlidableCard(
        key: ValueKey(widget.bucket.id),
        onDelete: widget.isEditing 
            ? () => ref.read(bucketDraftProvider.notifier).removeBucket(widget.bucket.id)
            : null,
        child: IgnorePointer(
          ignoring: !widget.isEditing,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: ModernBoxyInput(
                    controller: _nameController,
                    labelText: 'Bucket Name',
                    hintText: 'e.g. Groceries',
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next, // ─── KEYBOARD NEXT ACTION ───
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ModernBoxyInput(
                    controller: _percentageController,
                    labelText: '%',
                    hintText: '0.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), // ─── NUMERIC PAD ───
                    textInputAction: TextInputAction.next, // ─── KEYBOARD NEXT ACTION ───
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