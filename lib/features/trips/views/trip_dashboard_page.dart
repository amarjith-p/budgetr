import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/trip_provider.dart';
import 'trip_detail_page.dart';
import '../components/create_trip_bottom_sheet.dart';

class TripDashboardPage extends ConsumerWidget {
  const TripDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tripsAsync = ref.watch(allTripsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Trip Mode',
        subtitle: 'EXPENSE TRACKER',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          CreateTripBottomSheet.show(context);
        },
        icon: Icons.flight_takeoff_rounded,
        label: 'New Trip',
      ),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (trips) {
          if (trips.isEmpty) {
            return const PremiumEmptyState(
              title: 'No Trips Yet',
              subtitle:
                  'Activate Trip Mode to seamlessly track your travel expenses without mixing them up.',
              icon: Icons.explore_rounded,
            );
          }

          final activeTrips = trips
              .where((t) => t.status != 'COMPLETED')
              .toList();
          final completedTrips = trips
              .where((t) => t.status == 'COMPLETED')
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (activeTrips.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'LIVE TRIPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildTripCard(context, ref, activeTrips[index]),
                    childCount: activeTrips.length,
                  ),
                ),
              ],
              if (completedTrips.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                    child: Text(
                      'PAST TRIPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildTripCard(context, ref, completedTrips[index]),
                    childCount: completedTrips.length,
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

  Widget _buildTripCard(BuildContext context, WidgetRef ref, trip) {
    final theme = Theme.of(context);
    final isActive = trip.status == 'ACTIVE';
    final isPaused = trip.status == 'PAUSED';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingLg,
        vertical: 6,
      ),
      child: BoxySlidableCard(
        key: ValueKey(trip.id),
        onDelete: () {
          ConfirmationBottomSheet.show(
            context,
            title: 'Delete Trip?',
            description:
                'This will delete the trip record. Transactions linked to it will remain in your main ledger.',
            confirmText: 'DELETE',
            isDestructive: true,
            onConfirm: () =>
                ref.read(tripActionProvider.notifier).deleteTrip(trip.id),
          );
        },
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TripDetailPage(trip: trip)),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? theme.colorScheme.primary.withOpacity(0.5)
                    : theme.dividerColor,
                width: isActive ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.flight_takeoff_rounded
                        : (isPaused
                              ? Icons.pause_rounded
                              : Icons.flight_land_rounded),
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isActive
                              ? Colors.green
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
