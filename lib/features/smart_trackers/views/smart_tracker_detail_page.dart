// lib/features/smart_trackers/views/smart_tracker_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/premium_empty_state.dart';
import '../providers/smart_tracker_provider.dart';
import '../components/smart_tracker_table.dart';
import 'smart_tracker_entry_page.dart';

class SmartTrackerDetailPage extends ConsumerWidget {
  final SmartTrackerTemplate template;

  const SmartTrackerDetailPage({Key? key, required this.template})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final recordsAsync = ref.watch(smartTrackerRecordsProvider(template.id));
    final templateAsync = ref.watch(
      singleSmartTrackerTemplateProvider(template.id),
    );
    final liveTemplate = templateAsync.asData?.value ?? template;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // --- FIXED: App Bar is perfectly clean, no chart icon ---
      appBar: ModernAppBar(
        title: liveTemplate.name,
        subtitle: 'SMART TRACKER LEDGER',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          final count = recordsAsync.asData?.value.length ?? 0;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SmartTrackerEntryPage(
                template: liveTemplate,
                existingRecordCount: count,
              ),
            ),
          );
        },
        icon: Icons.add_rounded,
        label: 'Log Data',
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (records) {
          if (records.isEmpty) {
            return PremiumEmptyState(
              title: 'Ledger is Empty',
              subtitle:
                  'Tap Log Data to create your first entry in ${liveTemplate.name}.',
              icon: Icons.grid_on_rounded,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SmartTrackerTable(
                  template: liveTemplate,
                  records: records,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
