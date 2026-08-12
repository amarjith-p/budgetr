// lib/features/smart_trackers/views/smart_trackers_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/boxy_slidable_card.dart'; // <-- IMPORTED SLIDABLE
import '../../../core/components/confirmation_bottom_sheet.dart'; // <-- IMPORTED CONFIRMATION
import '../../../core/theme/design_tokens.dart';
import '../providers/smart_tracker_provider.dart';
import 'smart_tracker_builder_page.dart';
import 'smart_tracker_detail_page.dart';

class SmartTrackersDashboardPage extends ConsumerWidget {
  const SmartTrackersDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(smartTrackerTemplatesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Smart Trackers',
        subtitle: 'CUSTOM MODULES',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SmartTrackerBuilderPage()),
          );
        },
        icon: Icons.add_rounded,
        label: 'Build',
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (templates) {
          if (templates.isEmpty) {
            return const PremiumEmptyState(
              title: 'No Trackers Yet',
              subtitle:
                  'Build your first Smart Tracker to monitor anything you want, entirely on your terms.',
              icon: Icons.extension_rounded,
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(DesignTokens.spacingLg),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];

              return BoxySlidableCard(
                key: ValueKey(template.id),
                onEdit: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SmartTrackerBuilderPage(existingTemplate: template),
                    ),
                  );
                },
                onDelete: () {
                  ConfirmationBottomSheet.show(
                    context,
                    title: 'Delete Smart Tracker?',
                    description:
                        'This will permanently delete the "${template.name}" tracker and ALL associated data records. This cannot be undone.',
                    confirmText: 'DELETE EVERYTHING',
                    isDestructive: true,
                    onConfirm: () {
                      ref
                          .read(smartTrackerActionProvider.notifier)
                          .deleteTrackerTemplate(template.id);
                    },
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SmartTrackerDetailPage(template: template),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.dynamic_form_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to view records',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
