import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/financial_record_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settlement/screens/settlement_screen.dart';
import '../widgets/add_record_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<String> _categoryOrder = [];

  @override
  void initState() {
    super.initState();
    _fetchCategoryOrder();
  }

  // Fetch the master order from settings
  Future<void> _fetchCategoryOrder() async {
    try {
      final config = await _firestoreService.getPercentageConfig();
      if (mounted) {
        setState(() {
          _categoryOrder = config.categories.map((e) => e.name).toList();
        });
      }
    } catch (e) {
      // Ignore errors, default order will be used
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    void _showAddRecordSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => const AddRecordSheet(),
      ).then((_) => _fetchCategoryOrder()); // Refresh order if settings changed
    }

    void _navigateToSettings() {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const SettingsScreen()))
          .then((_) => _fetchCategoryOrder()); // Refresh order on return
    }

    void _navigateToSettlement() {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const SettlementScreen()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: _navigateToSettlement,
            tooltip: 'Monthly Settlement',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: StreamBuilder<List<FinancialRecord>>(
        stream: _firestoreService.getFinancialRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No records found.\nPress the + button to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            );
          }

          final records = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final displayDate = DateTime(record.year, record.month);
              final headerFormat = DateFormat('MMMM yyyy');

              // SORTING LOGIC:
              // Convert map to list
              final sortedAllocations = record.allocations.entries.toList();

              // Sort based on the index in _categoryOrder
              sortedAllocations.sort((a, b) {
                int indexA = _categoryOrder.indexOf(a.key);
                int indexB = _categoryOrder.indexOf(b.key);

                // If not found in order (deleted category), put at end
                if (indexA == -1) indexA = 999;
                if (indexB == -1) indexB = 999;

                return indexA.compareTo(indexB);
              });

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headerFormat.format(displayDate),
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const Divider(height: 20, color: Colors.white12),
                      _buildRecordDetailRow(
                        'Salary:',
                        currencyFormat.format(record.salary),
                        context,
                      ),
                      _buildRecordDetailRow(
                        'Extra Income:',
                        currencyFormat.format(record.extraIncome),
                        context,
                      ),
                      _buildRecordDetailRow(
                        'EMI:',
                        currencyFormat.format(record.emi),
                        context,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Effective Income: ${currencyFormat.format(record.effectiveIncome)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // RENDER SORTED LIST
                      ...sortedAllocations.map((entry) {
                        final percent =
                            record.allocationPercentages[entry.key]
                                ?.toStringAsFixed(0) ??
                            '?';
                        return _buildRecordDetailRow(
                          '${entry.key} ($percent%):',
                          currencyFormat.format(entry.value),
                          context,
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRecordSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  Widget _buildRecordDetailRow(
    String title,
    String value,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
