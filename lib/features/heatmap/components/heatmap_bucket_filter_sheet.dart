// lib/features/heatmap/components/heatmap_bucket_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/components/global_selection_sheet.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../providers/heatmap_bucket_selection_provider.dart';

class HeatmapBucketFilterSheet {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final allBuckets = ref.read(bucketsStreamProvider).asData?.value ?? [];
    if (allBuckets.isEmpty) return;

    final currentState = ref.read(heatmapSelectedBucketsProvider) ?? {};
    Set<int> initialSelection = currentState;
    if (initialSelection.isEmpty) {
      initialSelection = allBuckets.map((b) => b.id).toSet();
    }

    final newSelection = await GlobalSelectionSheet.show<Set<int>>(
      context: context,
      title: 'Filter Included Buckets',
      builder: (ctx, scrollController) {
        Set<int> tempSelection = Set<int>.from(initialSelection);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: allBuckets.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.3),
                      indent: 24,
                      endIndent: 24,
                    ),
                    itemBuilder: (context, index) {
                      final bucket = allBuckets[index];
                      final isSelected = tempSelection.contains(bucket.id);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        title: Text(
                          bucket.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            fontSize: 15,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 20,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.5,
                                ),
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            if (isSelected) {
                              tempSelection.remove(bucket.id);
                            } else {
                              tempSelection.add(bucket.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx, tempSelection);
                    },
                    child: const Text(
                      'APPLY FILTERS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (newSelection != null) {
      ref
          .read(heatmapSelectedBucketsProvider.notifier)
          .updateSelection(newSelection);
    }
  }
}
