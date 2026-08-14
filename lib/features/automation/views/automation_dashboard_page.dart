import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/components/currency_text.dart';
import '../providers/automation_provider.dart';
import 'automation_rule_form_page.dart';
import '../components/manual_rule_confirmation_sheet.dart';

// --- NEW: Live Countdown Badge Widget ---
class _CountdownBadge extends StatefulWidget {
  final DateTime targetDate;
  final ThemeData theme;

  const _CountdownBadge({required this.targetDate, required this.theme});

  @override
  State<_CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<_CountdownBadge> {
  late Timer _timer;
  late Duration _diff;

  @override
  void initState() {
    super.initState();
    _updateDiff();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDiff());
  }

  void _updateDiff() {
    final now = DateTime.now();
    setState(() {
      _diff = widget.targetDate.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_diff.isNegative) return const SizedBox.shrink();

    String text;
    bool isCritical = false;

    if (_diff.inHours >= 24) {
      text = 'Due in ${_diff.inDays}d';
    } else {
      isCritical = true;
      final h = _diff.inHours.toString().padLeft(2, '0');
      final m = _diff.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = _diff.inSeconds.remainder(60).toString().padLeft(2, '0');
      text = 'Due in $h:$m:$s';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCritical
            ? widget.theme.colorScheme.error.withOpacity(0.1)
            : widget.theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isCritical
              ? widget.theme.colorScheme.error
              : widget.theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class AutomationDashboardPage extends ConsumerWidget {
  const AutomationDashboardPage({super.key});

  Widget _buildRuleCard(
    BuildContext context,
    WidgetRef ref,
    RecurringTransactionRule rule,
    ThemeData theme,
    bool isDark,
    bool isPending,
  ) {
    final txColor = TransactionColors.getTypeColor(rule.transactionType, theme);
    final bool hasWebsite =
        rule.serviceWebsite != null && rule.serviceWebsite!.trim().isNotEmpty;
    final String faviconUrl = hasWebsite
        ? 'https://www.google.com/s2/favicons?domain=${rule.serviceWebsite}&sz=128'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      child: BoxySlidableCard(
        key: ValueKey(rule.id),
        onEdit: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AutomationRuleFormPage(existingRule: rule),
            ),
          );
        },
        onDelete: () {
          HapticFeedback.mediumImpact();
          ConfirmationBottomSheet.show(
            context,
            title: 'Delete Rule?',
            description:
                'Are you sure you want to stop automating "${rule.name}"?',
            confirmText: 'DELETE',
            isDestructive: true,
            onConfirm: () =>
                ref.read(automationActionProvider.notifier).deleteRule(rule.id),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPending
                ? theme.colorScheme.errorContainer.withOpacity(
                    isDark ? 0.2 : 0.4,
                  )
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPending
                  ? theme.colorScheme.error.withOpacity(0.5)
                  : theme.dividerColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: hasWebsite
                        ? EdgeInsets.zero
                        : const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPending
                          ? theme.colorScheme.error.withOpacity(0.15)
                          : txColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasWebsite
                        ? Image.network(
                            faviconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Icon(
                              Icons.autorenew_rounded,
                              color: txColor,
                              size: 22,
                            ),
                          )
                        : Icon(
                            Icons.autorenew_rounded,
                            color: isPending
                                ? theme.colorScheme.error
                                : txColor,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                rule.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (rule.amount != null)
                              CurrencyText(
                                amount: rule.amount!,
                                amountStyle: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: isPending
                                      ? theme.colorScheme.error
                                      : txColor,
                                ),
                              )
                            else
                              Text(
                                'VARIABLE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 12,
                              color: isPending
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            // --- UPDATED: 12-Hour Clock Format & Layout ---
                            Expanded(
                              child: Text(
                                isPending
                                    ? 'DUE: ${DateFormat('dd MMM yyyy, hh:mm a').format(rule.nextExecutionDate)}'
                                    : 'Next: ${DateFormat('dd MMM yyyy, hh:mm a').format(rule.nextExecutionDate)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isPending
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // --- NEW: Live Countdown inserted dynamically ---
                            if (!isPending)
                              _CountdownBadge(
                                targetDate: rule.nextExecutionDate,
                                theme: theme,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rule.advancedSchedule != null &&
                                        rule.advancedSchedule != 'Same Date'
                                    ? '${rule.advancedSchedule}'
                                    : 'Every ${rule.repetitionInterval} ${rule.repetitionSchedule}(s)',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: rule.isAutomatic
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orangeAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rule.isAutomatic ? 'AUTO' : 'MANUAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: rule.isAutomatic
                                      ? Colors.green
                                      : Colors.orangeAccent.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final notifId =
                          'manual_${rule.id}_${rule.nextExecutionDate.millisecondsSinceEpoch}';
                      ManualRuleConfirmationSheet.show(
                        context,
                        ruleId: rule.id,
                        expectedDateStr: rule.nextExecutionDate
                            .toIso8601String(),
                        notificationId: notifId,
                      );
                    },
                    child: const Text(
                      'EXECUTE PENDING TRANSACTION',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rulesAsync = ref.watch(allRecurringRulesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Automation',
        subtitle: 'RECURRING RULES',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AutomationRuleFormPage()),
          );
        },
        icon: Icons.add_rounded,
        label: 'Create',
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const PremiumEmptyState(
              title: 'No Automation Rules',
              subtitle:
                  'Set up recurring transactions to automate your logging and approvals.',
              icon: Icons.published_with_changes_rounded,
            );
          }

          final now = DateTime.now();
          final pendingRules = rules
              .where(
                (r) =>
                    (!r.isAutomatic || r.amount == null) &&
                    (r.nextExecutionDate.isBefore(now) ||
                        r.nextExecutionDate.isAtSameMomentAs(now)),
              )
              .toList();
          final upcomingRules = rules
              .where((r) => !pendingRules.contains(r))
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (pendingRules.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ACTION REQUIRED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildRuleCard(
                        context,
                        ref,
                        pendingRules[index],
                        theme,
                        isDark,
                        true,
                      ),
                      childCount: pendingRules.length,
                    ),
                  ),
                ),
              ],
              if (upcomingRules.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      'UPCOMING & ACTIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildRuleCard(
                        context,
                        ref,
                        upcomingRules[index],
                        theme,
                        isDark,
                        false,
                      ),
                      childCount: upcomingRules.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}
