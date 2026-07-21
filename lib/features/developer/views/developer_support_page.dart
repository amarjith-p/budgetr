import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/bento_card.dart';
import '../../../core/database/database_provider.dart';
import 'table_crud_page.dart';

class DeveloperSupportPage extends ConsumerWidget {
  const DeveloperSupportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final tables = db.allTables.toList();

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'DB INSPECTOR',
        subtitle: 'DEVELOPER MENU',
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final table = tables[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: BentoCard(
              height: 84,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TableCrudPage(table: table),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        table.actualTableName.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${table.$columns.length} Columns',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.table_chart_outlined, size: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}