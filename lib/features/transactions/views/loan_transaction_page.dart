import 'dart:math';
import 'package:budgetr/features/accounts/providers/account_provider.dart';
import 'package:budgetr/features/transactions/components/interest_payable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../providers/transaction_provider.dart';
import '../components/transaction_card.dart';
import '../components/tax_rate_bottom_sheet.dart';
import 'transaction_form_page.dart';

// Local state provider to hold the tax rate for this specific session
final loanTaxRateProvider = StateProvider.autoDispose.family<double?, String>((ref, accountId) => null);

class LoanTransactionPage extends ConsumerWidget {
  final Account account;
  
  const LoanTransactionPage({Key? key, required this.account}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(accountTransactionsProvider(account.id));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: account.providerName.toUpperCase(),
        subtitle: account.name.toUpperCase(),
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionFormPage(preSelectedAccountId: account.id)));
        },
        icon: Icons.add_rounded,
        label: 'Log',
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingMd),
                  child: _LoanSummaryCard(account: account),
                ),
              ),
              
              if (transactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No repayments logged yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
                          child: TransactionCard(data: transactions[index], currentAccountId: account.id),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _LoanSummaryCard extends ConsumerWidget {
  final Account account;

  const _LoanSummaryCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- MATHEMATICAL ENGINE ---
    final double principal = account.loanPrincipal ?? 0.0;
    final double rate = account.interestRate ?? 0.0;
    final int months = account.tenureMonths ?? 0;
    final double currentBalance = account.balance.abs();
    
    // Attempt to pull from Database first, fallback to EMI calculation
    double totalInterest = account.totalInterestPayable ?? 0.0;
    bool isCustomInterest = account.totalInterestPayable != null;

    if (!isCustomInterest && principal > 0 && rate > 0 && months > 0) {
      double r = rate / 12 / 100;
      double emi = principal * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
      totalInterest = (emi * months) - principal;
    }

    // Pull Tax from Database
    double? taxAmount = account.totalTaxPayable;

    // --- REPAYMENT PROGRESS ---
    double progress = 0.0;
    if (principal > 0) {
      double paid = principal - currentBalance;
      if (paid < 0) paid = 0;
      progress = (paid / principal).clamp(0.0, 1.0);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OUTSTANDING PRINCIPAL', 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: theme.colorScheme.onSurfaceVariant)
              ),
              if (principal > 0)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% PAID', 
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 0.5)
                ),
            ],
          ),
          const SizedBox(height: 4),
          
          CurrencyText(
            amount: currentBalance,
            sign: '₹ ',
            amountStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -0.5),
            symbolStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
          ),
          
          if (principal > 0) ...[
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 4,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }
            ),
          ],
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('INTEREST PAYABLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
                          GestureDetector(
                            onTap: () => _triggerInterestEdit(context, ref, totalInterest),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                              child: Icon(Icons.edit_rounded, size: 12, color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      CurrencyText(
                        amount: totalInterest,
                        sign: '+ ₹ ',
                        amountStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.error, letterSpacing: -0.5),
                        symbolStyle: TextStyle(fontSize: 10, color: theme.colorScheme.error.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCustomInterest ? 'Custom Override' : '@ ${rate.toStringAsFixed(1)}% / $months mo', 
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)
                      ),
                    ],
                  ),
                ),
                VerticalDivider(width: 24, thickness: 1, color: theme.dividerColor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('EST. TAX', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
                          GestureDetector(
                            onTap: () => _triggerTaxCalculation(context, ref, totalInterest),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                              child: Icon(Icons.edit_rounded, size: 12, color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (taxAmount != null) ...[
                        CurrencyText(
                          amount: taxAmount,
                          sign: '+ ₹ ',
                          amountStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.orangeAccent.shade700, letterSpacing: -0.5),
                          symbolStyle: TextStyle(fontSize: 10, color: Colors.orangeAccent.shade700.withOpacity(0.8)),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: () => _triggerTaxCalculation(context, ref, totalInterest),
                          child: Text('Set tax rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDatabase(WidgetRef ref, {double? newInterest, double? newTax}) async {
    await ref.read(accountActionProvider.notifier).saveAccount(
      existingId: account.id,
      name: account.name,
      providerName: account.providerName,
      type: account.type,
      last4: account.last4 ?? '',
      balance: account.balance,
      creditLimit: account.creditLimit,
      billDate: account.billDate,
      dueDate: account.dueDate,
      loanPurpose: account.loanPurpose,
      loanPrincipal: account.loanPrincipal,
      interestRate: account.interestRate,
      tenureMonths: account.tenureMonths,
      emiDate: account.emiDate,
      loanStartDate: account.loanStartDate,
      loanEndDate: account.loanEndDate,
      totalInterestPayable: newInterest ?? account.totalInterestPayable,
      totalTaxPayable: newTax ?? account.totalTaxPayable,
    );
  }

  Future<void> _triggerInterestEdit(BuildContext context, WidgetRef ref, double currentAmount) async {
    HapticFeedback.lightImpact();
    final newInterest = await InterestPayableBottomSheet.show(context, currentAmount);
    if (newInterest != null) {
      await _updateDatabase(ref, newInterest: newInterest);
    }
  }

  Future<void> _triggerTaxCalculation(BuildContext context, WidgetRef ref, double currentInterest) async {
    HapticFeedback.lightImpact();
    final rate = await TaxRateBottomSheet.show(context);
    if (rate != null) {
      final calculatedTax = currentInterest * (rate / 100);
      await _updateDatabase(ref, newTax: calculatedTax);
    }
  }
}