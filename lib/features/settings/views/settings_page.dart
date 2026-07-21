import 'package:flutter/material.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/theme_switcher_card.dart';
import '../../../core/theme/design_tokens.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Settings',
        subtitle: 'PREFERENCES',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        children: const [
          // Drop in our global theme switcher card
          ThemeSwitcherCard(),
          
          // You can add more setting cards here later!
        ],
      ),
    );
  }
}