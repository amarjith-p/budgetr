// lib/features/investments/views/investment_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../components/investment_summary_card.dart';
import '../components/investment_passive_income_card.dart';
import '../components/investment_action_bottom_sheet.dart';
import '../components/investment_activity_ledger.dart';
import '../components/investment_close_bottom_sheet.dart';
import '../providers/investment_provider.dart';
import 'investment_form_page.dart';

class InvestmentDetailsPage extends ConsumerWidget {
  final Investment investment;

  const InvestmentDetailsPage({Key? key, required this.investment})
    : super(key: key);

  void _showOptionsMenu(
    BuildContext context,
    WidgetRef ref,
    Investment liveInvestment,
  ) {
    final theme = Theme.of(context);
    final isClosed = liveInvestment.isClosed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + DesignTokens.spacingMd,
          top: 16,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Investment Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (!isClosed) ...[
                _buildOptionTile(
                  context: ctx,
                  icon: Icons.edit_rounded,
                  title: 'Edit Details',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvestmentFormPage(
                          existingInvestment: liveInvestment,
                        ),
                      ),
                    );
                  },
                ),
                _buildOptionTile(
                  context: ctx,
                  icon: Icons.lock_outline_rounded,
                  title: 'Close Investment',
                  color: theme.colorScheme.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    InvestmentCloseBottomSheet.show(context, liveInvestment);
                  },
                ),
              ],

              _buildOptionTile(
                context: ctx,
                icon: Icons.delete_forever_rounded,
                title: 'Delete Permanently',
                color: theme.colorScheme.error,
                onTap: () {
                  Navigator.pop(ctx);
                  ConfirmationBottomSheet.show(
                    context,
                    title: 'Delete Portfolio?',
                    description:
                        'This permanently removes the investment and all its activity logs. Proceed?',
                    confirmText: 'DELETE',
                    isDestructive: true,
                    onConfirm: () {
                      ref
                          .read(investmentActionProvider.notifier)
                          .deleteInvestment(liveInvestment.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODERN BOXY TILE COMPONENT ---
  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final investmentsAsync = ref.watch(investmentsStreamProvider);
    final liveInvestment =
        investmentsAsync.asData?.value
            .where((inv) => inv.id == investment.id)
            .firstOrNull ??
        investment;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: liveInvestment.name.toUpperCase(),
        subtitle: liveInvestment.isClosed
            ? 'CLOSED ASSET'
            : liveInvestment.type.toUpperCase(),
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
        trailingIcon: Icons.more_vert_rounded,
        onTrailingPressed: () => _showOptionsMenu(context, ref, liveInvestment),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        children: [
          if (liveInvestment.isClosed) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Closed: ${liveInvestment.closeReason ?? "No reason provided"}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          InvestmentSummaryCard(investment: liveInvestment),
          const SizedBox(height: 12),
          InvestmentPassiveIncomeCard(investment: liveInvestment),
          const SizedBox(height: 32),
          InvestmentActivityLedger(investment: liveInvestment),
          const SizedBox(height: 40),
        ],
      ),

      bottomNavigationBar: liveInvestment.isClosed
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingLg,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ModernBoxyButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          InvestmentActionBottomSheet.show(
                            context,
                            investment: liveInvestment,
                            isUpdateMode: false,
                          );
                        },
                        label: 'Log Activity',
                        icon: Icons.add_card_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModernBoxyButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          InvestmentActionBottomSheet.show(
                            context,
                            investment: liveInvestment,
                            isUpdateMode: true,
                          );
                        },
                        label: 'Update Value',
                        icon: Icons.sync_rounded,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
