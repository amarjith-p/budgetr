import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart'; // Added import for confirmation sheet
import '../providers/reminder_provider.dart';
import '../components/create_reminder_bottom_sheet.dart';

class ReminderDashboardPage extends ConsumerWidget {
  const ReminderDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final remindersAsync = ref.watch(allRemindersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Reminders',
        subtitle: 'CUSTOM ALERTS',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () => CreateReminderBottomSheet.show(context),
        icon: Icons.add_alarm_rounded,
        label: 'Add',
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (reminders) {
          if (reminders.isEmpty) {
            return const PremiumEmptyState(
              title: 'No Reminders',
              subtitle:
                  'Set custom reminders to keep track of important financial deadlines, renewals, or personal tasks.',
              icon: Icons.notifications_active_rounded,
            );
          }

          final activeReminders = reminders
              .where((r) => r.targetDate.isAfter(DateTime.now()))
              .toList();
          final pastReminders = reminders
              .where(
                (r) =>
                    r.targetDate.isBefore(DateTime.now()) ||
                    r.targetDate.isAtSameMomentAs(DateTime.now()),
              )
              .toList();

          // Sort active so closest is at the top
          activeReminders.sort((a, b) => a.targetDate.compareTo(b.targetDate));
          // Sort past so most recent is at the top
          pastReminders.sort((a, b) => b.targetDate.compareTo(a.targetDate));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (activeReminders.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'UPCOMING ALERTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingLg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _LiveCountdownCard(
                        reminder: activeReminders[index],
                        ref: ref,
                      ),
                      childCount: activeReminders.length,
                    ),
                  ),
                ),
              ],

              if (pastReminders.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                    child: Text(
                      'PAST / COMPLETED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingLg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _LiveCountdownCard(
                        reminder: pastReminders[index],
                        ref: ref,
                        isPast: true,
                      ),
                      childCount: pastReminders.length,
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

class _LiveCountdownCard extends StatefulWidget {
  final Reminder reminder;
  final WidgetRef ref;
  final bool isPast;

  const _LiveCountdownCard({
    required this.reminder,
    required this.ref,
    this.isPast = false,
  });

  @override
  State<_LiveCountdownCard> createState() => _LiveCountdownCardState();
}

class _LiveCountdownCardState extends State<_LiveCountdownCard> {
  Timer? _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _setupTimer();
  }

  // --- FIXED: Instantly reacts to Riverpod streaming a modified reminder ---
  @override
  void didUpdateWidget(covariant _LiveCountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If any data changed, immediately recalculate
    _calculateTime();

    // If the target date changed, or if it moved between past and active lists, reset the timer logic
    if (oldWidget.isPast != widget.isPast ||
        oldWidget.reminder.targetDate != widget.reminder.targetDate) {
      _setupTimer();
    }
  }

  void _setupTimer() {
    _timer?.cancel();
    if (!widget.isPast) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _calculateTime(),
      );
    }
  }

  void _calculateTime() {
    final now = DateTime.now();
    final diff = widget.reminder.targetDate.difference(now);
    if (diff.isNegative && !widget.isPast) {
      _timer?.cancel();
    }
    if (mounted) setState(() => _timeLeft = diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown() {
    if (_timeLeft.isNegative) return 'COMPLETED';

    if (_timeLeft.inHours >= 24) {
      int days = _timeLeft.inDays;
      int hours = _timeLeft.inHours.remainder(24);
      return '$days Days, $hours Hrs';
    } else {
      String h = _timeLeft.inHours.toString().padLeft(2, '0');
      String m = _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
      String s = _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = widget.reminder;
    final isCritical =
        !widget.isPast && _timeLeft.inHours < 24 && !_timeLeft.isNegative;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: BoxySlidableCard(
        key: ValueKey(r.id),
        onEdit: () {
          HapticFeedback.selectionClick();
          CreateReminderBottomSheet.show(context, existingReminder: r);
        },
        onDelete: () {
          HapticFeedback.heavyImpact();
          ConfirmationBottomSheet.show(
            context,
            title: 'Delete Reminder?',
            description:
                'Are you sure you want to delete this reminder? This action cannot be undone.',
            confirmText: 'DELETE',
            isDestructive: true,
            onConfirm: () {
              widget.ref
                  .read(reminderActionProvider.notifier)
                  .deleteReminder(r);
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(
            10,
          ), // Reduced from 16 to keep it compact
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, // Restored global color
            borderRadius: BorderRadius.circular(8), // Restored global radius
            border: Border.all(
              color: isCritical
                  ? Colors.orangeAccent.withOpacity(0.5)
                  : theme.dividerColor, // Restored global border
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP ROW: Icon and Title ONLY ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                      8,
                    ), // Slightly tighter for compact look
                    decoration: BoxDecoration(
                      color: widget.isPast
                          ? theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5)
                          : (isCritical
                                ? Colors.orangeAccent.withOpacity(0.1)
                                : theme.colorScheme.primary.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(6), // Restored
                    ),
                    child: Icon(
                      widget.isPast
                          ? Icons.done_all_rounded
                          : (isCritical
                                ? Icons.timer_rounded
                                : Icons.notifications_active_rounded),
                      color: widget.isPast
                          ? theme.colorScheme.onSurfaceVariant
                          : (isCritical
                                ? Colors.orangeAccent
                                : theme.colorScheme.primary),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expanded Title takes ALL remaining space naturally
                  Expanded(
                    child: Text(
                      r.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14, // Restored original size
                        color: widget.isPast
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                        decoration: widget.isPast
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- BOTTOM ROW: Date, Notes, Due Counter, and Push Indicator ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // LEFT SIDE: Date and Notes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(r.targetDate),
                          style: TextStyle(
                            fontSize: 11, // Restored original
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (r.notes != null && r.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            r.notes!,
                            style: TextStyle(
                              fontSize: 12, // Restored original
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.8),
                            ),
                            maxLines: 1, // Kept at 1 to maintain reduced height
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // RIGHT SIDE: Due Counter (Top) & Push Indicator (Bottom)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Due Counter moved here
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isPast
                              ? Colors.transparent
                              : (isCritical
                                    ? Colors.orangeAccent
                                    : theme
                                          .colorScheme
                                          .primary), // Restored global
                          borderRadius: BorderRadius.circular(
                            4,
                          ), // Restored global
                          border: widget.isPast
                              ? Border.all(color: theme.dividerColor)
                              : null,
                        ),
                        child: Text(
                          _formatCountdown(),
                          style: TextStyle(
                            fontSize: 10, // Restored original size
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: widget.isPast
                                ? theme.colorScheme.onSurfaceVariant
                                : (isDark
                                      ? Colors.black
                                      : Colors
                                            .white), // Restored original logic
                          ),
                        ),
                      ),

                      // Notification Prior Text below the counter
                      if (r.isPushEnabled && !widget.isPast) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 12,
                              color: theme
                                  .colorScheme
                                  .primary, // Restored original
                            ),
                            const SizedBox(width: 2),
                            Text(
                              r.priorDays == 0
                                  ? 'On Time'
                                  : '${r.priorDays}d Prior',
                              style: TextStyle(
                                fontSize: 9, // Restored original
                                fontWeight: FontWeight.w800,
                                color: theme
                                    .colorScheme
                                    .primary, // Restored original
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
