import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/components/futuristic_loader.dart';
import '../providers/net_worth_provider.dart';
import '../providers/net_worth_record_provider.dart';
import 'net_worth_view.dart';

class NetWorthPage extends ConsumerWidget {
  const NetWorthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(netWorthMetricsProvider);
    final recordsAsync = ref.watch(netWorthRecordsStreamProvider);

    return metricsAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: FuturisticLoader(size: 80, label: "CALCULATING NET WORTH.."),
        ),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text('Error: $e')),
      ),
      data: (metrics) =>
          NetWorthView(metrics: metrics, recordsAsync: recordsAsync),
    );
  }
}
