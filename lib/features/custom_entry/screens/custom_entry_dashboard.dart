import 'package:budget/features/custom_entry/services/custom_entry_service.dart';
import 'package:flutter/material.dart';
import '../../../core/models/custom_data_models.dart';
import '../../../core/services/firestore_service.dart';
import 'template_editor_screen.dart';
import '../widgets/custom_data_page.dart';

class CustomEntryDashboard extends StatelessWidget {
  const CustomEntryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomTemplate>>(
      stream: CustomEntryService().getCustomTemplates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final templates = snapshot.data ?? [];

        if (templates.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Custom Data Entry')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 64,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No custom forms yet.',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const TemplateEditorScreen(),
                      ),
                    ),
                    child: const Text('Create Your First Form'),
                  ),
                ],
              ),
            ),
          );
        }

        return DefaultTabController(
          length: templates.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Custom Data Entry'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_to_photos_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const TemplateEditorScreen(),
                    ),
                  ),
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.white60,
                tabs: templates
                    .map((t) => Tab(text: t.name.toUpperCase()))
                    .toList(),
              ),
            ),
            body: TabBarView(
              children: templates
                  .map((t) => CustomDataPage(template: t))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
