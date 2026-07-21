import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
// Adjusted path to global constants
import '../../../core/constants/icon_constants.dart'; 

class IconPickerBottomSheet extends StatelessWidget {
// ... rest of the code
  const IconPickerBottomSheet({Key? key}) : super(key: key);

  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => const IconPickerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Icon', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: IconConstants.iconGroups.length, //[cite: 2]
                itemBuilder: (context, index) {
                  final group = IconConstants.iconGroups[index]; //[cite: 2]
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd, vertical: DesignTokens.spacingMd),
                        child: Text(
                          group.title, //[cite: 2]
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 60,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
                        itemCount: group.icons.length, //[cite: 2]
                        itemBuilder: (context, iconIndex) {
                          final iconMeta = group.icons[iconIndex]; //[cite: 2]
                          return InkWell(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                            onTap: () => Navigator.pop(context, iconMeta.icon.codePoint), //[cite: 2]
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                              ),
                              child: Icon(iconMeta.icon), //[cite: 2]
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: DesignTokens.spacingMd),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}