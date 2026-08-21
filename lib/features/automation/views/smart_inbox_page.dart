// lib/features/automation/views/smart_inbox_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../providers/smart_inbox_provider.dart';
import 'parser_rules_playground_page.dart';

// --- IMPORT TRANSACTION FORM ---
import '../../transactions/views/transaction_form_page.dart';

class SmartInboxPage extends ConsumerStatefulWidget {
  const SmartInboxPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SmartInboxPage> createState() => _SmartInboxPageState();
}

class _SmartInboxPageState extends ConsumerState<SmartInboxPage> {
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await ref
        .read(smartInboxActionProvider.notifier)
        .checkPermission();
    if (mounted) setState(() => _hasPermission = granted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inboxAsync = ref.watch(stagedTransactionsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: 'Smart Inbox',
        subtitle: 'AUTOMATED LOGS',
        leadingIcon: Icons.arrow_back_rounded,
        trailingIcon: Icons.tune_rounded,
        onTrailingPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ParserRulesPlaygroundPage(),
            ),
          );
        },
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          if (!_hasPermission)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(DesignTokens.spacingMd),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_paused_rounded,
                      color: Colors.orangeAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notification Access Needed',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enable listener permission so FinStack 360 can detect UPI and bank notifications.',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                      ),
                      onPressed: () async {
                        await ref
                            .read(smartInboxActionProvider.notifier)
                            .requestPermissionsAndListen();
                        _checkPermission();
                      },
                      child: const Text(
                        'ENABLE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          inboxAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (stagedTxs) {
              if (stagedTxs.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: PremiumEmptyState(
                    title: 'Inbox Zero',
                    subtitle:
                        'Listening for UPI apps and banking SMS. Your unconfirmed logs will appear here.',
                    icon: Icons.all_inbox_rounded,
                  ),
                );
              }

              return SliverMainAxisGroup(
                slivers: [
                  // --- CLEAR ALL HEADER ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${stagedTxs.length} PENDING LOG${stagedTxs.length > 1 ? 'S' : ''}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ConfirmationBottomSheet.show(
                                context,
                                title: 'Clear All Logs?',
                                description:
                                    'This will permanently delete all unconfirmed transactions from your inbox. This cannot be undone.',
                                confirmText: 'CLEAR ALL',
                                isDestructive: true,
                                onConfirm: () {
                                  ref
                                      .read(smartInboxActionProvider.notifier)
                                      .clearAllStaged();
                                },
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Text(
                                'CLEAR ALL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.error,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- LIST OF STAGED TRANSACTIONS ---
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingMd,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tx = stagedTxs[index];
                        return _StagedTransactionCard(tx: tx);
                      }, childCount: stagedTxs.length),
                    ),
                  ),
                ],
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StagedTransactionCard extends ConsumerStatefulWidget {
  final StagedTransaction tx;

  const _StagedTransactionCard({required this.tx, super.key});

  @override
  ConsumerState<_StagedTransactionCard> createState() =>
      _StagedTransactionCardState();
}

class _StagedTransactionCardState
    extends ConsumerState<_StagedTransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = widget.tx.inferredType == 'Expense';
    final amountColor = TransactionColors.getTypeColor(
      widget.tx.inferredType,
      theme,
    );
    final activeRadius = BorderRadius.circular(DesignTokens.spacingXs);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      child: Slidable(
        key: ValueKey(widget.tx.id),

        // --- SWIPE RIGHT (LEFT PANE) -> DISCARD ---
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                ConfirmationBottomSheet.show(
                  context,
                  title: 'Discard Log?',
                  description:
                      'This auto-captured transaction will be removed from your inbox.',
                  confirmText: 'DISCARD',
                  isDestructive: true,
                  onConfirm: () => ref
                      .read(smartInboxActionProvider.notifier)
                      .deleteStaged(widget.tx.id),
                );
              },
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onErrorContainer,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.only(right: DesignTokens.spacingSm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: activeRadius,
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded),
                    SizedBox(height: 4),
                    Text(
                      'Discard',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // --- SWIPE LEFT (RIGHT PANE) -> APPROVE ---
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TransactionFormPage(stagedTransaction: widget.tx),
                  ),
                );
              },
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.only(left: DesignTokens.spacingSm),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: activeRadius,
                  border: Border.all(
                    color: Colors.green.shade800.withOpacity(0.5),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded),
                    SizedBox(height: 4),
                    Text(
                      'Approve',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // --- MAIN CARD CONTENT ---
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isExpanded = !_isExpanded);
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: activeRadius,
              border: Border.all(
                color: _isExpanded
                    ? theme.colorScheme.primary.withOpacity(0.5)
                    : theme.dividerColor.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: _isExpanded
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isExpense
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: amountColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.tx.sourceName.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.tx.accountLast4 != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• • • • ${widget.tx.accountLast4}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        alignment: Alignment.topCenter,
                        child: Text(
                          widget.tx.rawText,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_isExpanded && widget.tx.rawText.length > 60)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Tap to read more',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CurrencyText(
                      amount: widget.tx.extractedAmount,
                      sign: isExpense ? '- ' : '+ ',
                      amountStyle: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subtle hint indicating the swipe actions
                    Icon(
                      Icons.swipe_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
