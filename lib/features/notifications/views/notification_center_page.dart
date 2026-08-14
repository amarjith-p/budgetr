// lib/features/notifications/views/notification_center_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/futuristic_loader.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/in_app_notification_provider.dart';

// --- NEW IMPORT FOR AUTOMATION SHEET ---
import '../../automation/components/manual_rule_confirmation_sheet.dart';

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: 'Notifications',
        subtitle: 'ALERTS & UPDATES',
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
        trailingIcon: Icons.clear_all_rounded,
        onTrailingPressed: () {
          HapticFeedback.mediumImpact();
          ConfirmationBottomSheet.show(
            context,
            title: 'Clear All Notifications?',
            description:
                'This will permanently delete all your past alerts. This action cannot be undone.',
            confirmText: 'CLEAR ALL',
            isDestructive: true,
            onConfirm: () {
              ref
                  .read(inAppNotificationActionProvider.notifier)
                  .clearPastNotifications();
            },
          );
        },
      ),
      floatingActionButton:
          notificationsAsync.asData?.value.any((n) => !n.isRead) == true
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref
                    .read(inAppNotificationActionProvider.notifier)
                    .markAllAsRead();
              },
              icon: const Icon(Icons.checklist_rtl_rounded),
              label: const Text(
                'Mark All Read',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            )
          : null,
      body: notificationsAsync.when(
        loading: () => const Center(
          child: FuturisticLoader(size: 80, label: "LOADING ALERTS.."),
        ),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const PremiumEmptyState(
              title: 'You\'re All Caught Up!',
              subtitle:
                  'There are no new notifications or alerts at the moment.',
              icon: Icons.notifications_off_rounded,
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final notif = notifications[index];
                    final isUnread = !notif.isRead;

                    // --- NEW: PARSE PAYLOAD FOR AUTOMATION ---
                    Map<String, dynamic>? payloadMap;
                    if (notif.payload != null) {
                      try {
                        payloadMap = jsonDecode(notif.payload!);
                      } catch (_) {}
                    }
                    final isManualRule = payloadMap?['type'] == 'manual_rule';

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: DesignTokens.spacingMd,
                      ),
                      child: BoxySlidableCard(
                        key: ValueKey(notif.id),
                        onDelete: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(inAppNotificationActionProvider.notifier)
                              .deleteNotification(notif.id);
                        },
                        child: GestureDetector(
                          onTap: () {
                            if (isUnread) {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(
                                    inAppNotificationActionProvider.notifier,
                                  )
                                  .markAsRead(notif.id);
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? theme.colorScheme.primaryContainer
                                        .withOpacity(isDark ? 0.2 : 0.4)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isUnread
                                    ? theme.colorScheme.primary.withOpacity(0.5)
                                    : theme.dividerColor,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUnread
                                        ? theme.colorScheme.primary.withOpacity(
                                            0.15,
                                          )
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    isUnread
                                        ? Icons.mark_email_unread_rounded
                                        : Icons.mark_email_read_rounded,
                                    color: isUnread
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: TextStyle(
                                                fontWeight: isUnread
                                                    ? FontWeight.w900
                                                    : FontWeight.w700,
                                                fontSize: 15,
                                                color:
                                                    theme.colorScheme.onSurface,
                                                letterSpacing: -0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'MMM dd, HH:mm',
                                            ).format(notif.createdAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notif.body,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          fontWeight: isUnread
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isUnread
                                              ? theme.colorScheme.onSurface
                                                    .withOpacity(0.9)
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                      ),
                                      // --- NEW: RENDER EXECUTE BUTTON FOR RULES ---
                                      if (isManualRule &&
                                          payloadMap != null) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  theme.colorScheme.primary,
                                              foregroundColor:
                                                  theme.colorScheme.onPrimary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              elevation: 0,
                                            ),
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              ManualRuleConfirmationSheet.show(
                                                context,
                                                ruleId: payloadMap!['ruleId'],
                                                expectedDateStr:
                                                    payloadMap['expectedDate'],
                                                notificationId: notif.id,
                                              );
                                            },
                                            child: const Text(
                                              'EXECUTE NOW',
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: notifications.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}
