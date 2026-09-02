// lib/features/heatmap/views/heatmap_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/components/modern_app_bar.dart';
import '../../../core/theme/design_tokens.dart';
import '../components/heatmap_header_card.dart';
import '../components/heatmap_grid.dart';
import '../components/heatmap_selected_day_view.dart';
import '../providers/heatmap_bucket_selection_provider.dart';
import '../components/heatmap_bucket_filter_sheet.dart';

class HeatmapPage extends ConsumerWidget {
  const HeatmapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedBuckets = ref.watch(heatmapSelectedBucketsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: 'Spending Heatmap',
        subtitle: 'ANALYTICS',
        leadingIcon: Icons.arrow_back_rounded,
        trailingIcon: Icons.filter_alt_rounded,
        onTrailingPressed: () => HeatmapBucketFilterSheet.show(context, ref),
      ),
      body: selectedBuckets != null && selectedBuckets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.donut_small_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Buckets Selected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select at least one bucket to calculate pacing.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        HeatmapBucketFilterSheet.show(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text(
                      'Select Buckets',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.spacingMd),
                    child: HeatmapHeaderCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingMd,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: const HeatmapGrid(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: HeatmapSelectedDayView()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}
