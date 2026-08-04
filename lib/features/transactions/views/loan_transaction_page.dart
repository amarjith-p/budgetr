import 'dart:math'; 
import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../../../core/database/app_database.dart'; 
import '../../../core/components/modern_app_bar.dart'; 
import '../../../core/components/modern_squircle_fab.dart'; 
import '../../../core/theme/design_tokens.dart'; 
import '../../../core/components/currency_text.dart'; 
import '../providers/transaction_provider.dart'; 
import '../services/transaction_service.dart'; 
import '../components/transaction_card.dart'; 
import '../components/tax_rate_bottom_sheet.dart'; 
import '../components/interest_payable_bottom_sheet.dart'; 
import '../components/loan_payment_bottom_sheet.dart'; 
import '../../accounts/providers/account_provider.dart'; 
import 'transaction_form_page.dart'; 

class LoanTransactionPage extends ConsumerWidget {   
  final Account account;   
  const LoanTransactionPage({Key? key, required this.account}) : super(key: key);   
  
  @override   
  Widget build(BuildContext context, WidgetRef ref) {     
    final accountsAsync = ref.watch(accountsStreamProvider);     
    final transactionsAsync = ref.watch(accountTransactionsProvider(account.id));     
    final theme = Theme.of(context);     
    final allAccounts = accountsAsync.asData?.value ?? [];     
    final currentAccount = allAccounts.where((a) => a.id == account.id).firstOrNull ?? account;     
    
    final bool isSettled = currentAccount.isClosed;

    return Scaffold(       
      backgroundColor: theme.scaffoldBackgroundColor,       
      appBar: ModernAppBar(         
        title: currentAccount.providerName.toUpperCase(),         
        subtitle: isSettled ? '${currentAccount.name.toUpperCase()} (SETTLED)' : currentAccount.name.toUpperCase(),         
        leadingIcon: Icons.arrow_back_rounded,         
        onLeadingPressed: () => Navigator.pop(context),       
      ),       
      floatingActionButton: isSettled ? null : ModernSquircleFab(         
        onPressed: () {           
          LoanPaymentBottomSheet.show(context, currentAccount.id);         
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
                  padding: const EdgeInsets.fromLTRB(DesignTokens.spacingMd, DesignTokens.spacingMd, DesignTokens.spacingMd, 0),                   
                  child: _LoanSummaryCard(account: currentAccount, transactions: transactions, isSettled: isSettled),                 
                ),               
              ),                              

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(DesignTokens.spacingLg, DesignTokens.spacingXl, DesignTokens.spacingLg, DesignTokens.spacingMd),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'REPAYMENT HISTORY', 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant)
                      ),
                      if (transactions.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '${transactions.length} RECORD${transactions.length > 1 ? 'S' : ''}', 
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 0.5)
                          ),
                        )
                    ],
                  ),
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
                        return TransactionCard(data: transactions[index], currentAccountId: currentAccount.id);                       
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
  final List<TransactionWithDetails> transactions;
  final bool isSettled;

  const _LoanSummaryCard({required this.account, required this.transactions, required this.isSettled});   
  
  @override   
  Widget build(BuildContext context, WidgetRef ref) {     
    final theme = Theme.of(context);     
    final isDark = theme.brightness == Brightness.dark;     
    
    final double principal = account.loanPrincipal ?? 0.0;     
    final double rate = account.interestRate ?? 0.0;     
    final int months = account.tenureMonths ?? 0;     
    final double currentBalance = account.balance;          
    
    double totalInterest = account.totalInterestPayable ?? 0.0;     
    bool isCustomInterest = account.totalInterestPayable != null;     
    
    if (!isCustomInterest && principal > 0 && rate > 0 && months > 0) {       
      double r = rate / 12 / 100;       
      double emi = principal * r * pow(1 + r, months) / (pow(1 + r, months) - 1);       
      totalInterest = (emi * months) - principal;     
    }     
    
    double? taxAmount = account.totalTaxPayable;          

    double interestPaid = 0.0;
    double taxPaid = 0.0;

    for (final item in transactions) {
      if (item.transaction.subCategory == 'Loan Interest') {
        interestPaid += item.transaction.amount;
      } else if (item.transaction.subCategory == 'Tax on Interest') {
        taxPaid += item.transaction.amount;
      }
    }

    double remainingInterest = totalInterest - interestPaid;
    double remainingTax = 0.0;
    if (taxAmount != null) {
      remainingTax = taxAmount - taxPaid;
    }

    final double totalOutstanding = currentBalance + remainingInterest + remainingTax;
    final double totalLoanAmount = principal + totalInterest + (taxAmount ?? 0.0);

    double progress = 0.0;     
    if (totalLoanAmount > 0) {       
      double paid = totalLoanAmount - totalOutstanding;       
      progress = (paid / totalLoanAmount).clamp(0.0, 1.0);     
    }     
    
    final outstandingSign = totalOutstanding > 0 ? '-₹ ' : (totalOutstanding < 0 ? '+₹ ' : '₹ ');
    final outstandingColor = (totalOutstanding <= 0 || isSettled) ? Colors.green : theme.colorScheme.onSurface;
    final outstandingLabel = isSettled ? 'SETTLED LOAN' : (totalOutstanding <= 0 ? 'CLEARED / SURPLUS' : 'TOTAL OUTSTANDING');

    final principalSign = currentBalance > 0 ? '-₹ ' : (currentBalance < 0 ? '+₹ ' : '₹ ');
    final principalColor = currentBalance <= 0 ? Colors.green : theme.colorScheme.onSurface;

    final interestSign = remainingInterest > 0 ? '-₹ ' : (remainingInterest < 0 ? '+₹ ' : '₹ ');
    final interestColor = remainingInterest <= 0 ? Colors.green : theme.colorScheme.error;

    final taxSign = remainingTax > 0 ? '-₹ ' : (remainingTax < 0 ? '+₹ ' : '₹ ');
    final taxColor = remainingTax <= 0 ? Colors.green : Colors.orangeAccent.shade700;

    final labelStyle = TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: theme.colorScheme.onSurfaceVariant);
    final valueStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface, letterSpacing: -0.5);
    final symbolStyle = TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8));

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
                outstandingLabel,                  
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: outstandingColor == Colors.green ? Colors.green : theme.colorScheme.onSurfaceVariant)               
              ),               
              if (totalLoanAmount > 0 && !isSettled)                 
                Text(                   
                  '${(progress * 100).toStringAsFixed(0)}% PAID',                    
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 0.5)                 
                ),             
            ],           
          ),           
          const SizedBox(height: 4),                      
          
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CurrencyText(             
              amount: totalOutstanding.abs(),             
              // FIX: Replaced `signText` with `outstandingSign`
              sign: outstandingSign,             
              amountStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: outstandingColor, letterSpacing: -0.5),             
              symbolStyle: TextStyle(fontSize: 14, color: outstandingColor.withOpacity(0.7)),           
            ),
          ),                      
          
          if (totalLoanAmount > 0) ...[             
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
                    widthFactor: isSettled ? 1.0 : progress,                     
                    child: Container(                       
                      decoration: BoxDecoration(                         
                        color: isSettled ? Colors.green : theme.colorScheme.primary,                         
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
                    mainAxisAlignment: MainAxisAlignment.start,                   
                    children: [                       
                      Text('PRINCIPAL', style: labelStyle),                       
                      const SizedBox(height: 6),                       
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: CurrencyText(                         
                          amount: currentBalance.abs(),                         
                          sign: principalSign,                         
                          amountStyle: valueStyle.copyWith(color: principalColor),                         
                          symbolStyle: symbolStyle.copyWith(color: principalColor.withOpacity(0.8)),                       
                        ),
                      ),                     
                    ],                   
                  ),                 
                ),                 
                VerticalDivider(width: 16, thickness: 1, color: theme.dividerColor),                 
                
                Expanded(                   
                  child: Column(                     
                    crossAxisAlignment: CrossAxisAlignment.start,     
                    mainAxisAlignment: MainAxisAlignment.start,                
                    children: [                       
                      Row(                         
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,                         
                        children: [                           
                          Text('INTEREST', style: labelStyle),                           
                          if (!isSettled)
                            GestureDetector(                             
                              onTap: () => _triggerInterestEdit(context, ref, totalInterest, isCustomInterest),                             
                              behavior: HitTestBehavior.opaque,                             
                              child: Padding(                               
                                padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),                               
                                child: Icon(Icons.edit_rounded, size: 10, color: theme.colorScheme.primary),                             
                              ),                           
                            ),                         
                        ],                       
                      ),                       
                      const SizedBox(height: 6),                       
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: CurrencyText(                         
                          amount: remainingInterest.abs(),                         
                          sign: interestSign,                         
                          amountStyle: valueStyle.copyWith(color: interestColor),                         
                          symbolStyle: symbolStyle.copyWith(color: interestColor.withOpacity(0.8)),                       
                        ),
                      ),                     
                    ],                   
                  ),                 
                ),                 
                VerticalDivider(width: 16, thickness: 1, color: theme.dividerColor),                 
                
                Expanded(                   
                  child: Column(                     
                    crossAxisAlignment: CrossAxisAlignment.start,                     
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [                       
                      Row(                         
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,                         
                        children: [                           
                          Text('TAX', style: labelStyle),                           
                          if (!isSettled)
                            GestureDetector(                             
                              onTap: () => _triggerTaxCalculation(context, ref, totalInterest),                             
                              behavior: HitTestBehavior.opaque,                             
                              child: Padding(                               
                                padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),                               
                                child: Icon(Icons.edit_rounded, size: 10, color: theme.colorScheme.primary),                             
                              ),                           
                            ),                         
                        ],                       
                      ),                       
                      const SizedBox(height: 6),                       
                      if (taxAmount != null || isSettled) ...[                         
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CurrencyText(                           
                            amount: remainingTax.abs(),                           
                            sign: taxSign,                           
                            amountStyle: valueStyle.copyWith(color: taxColor),                           
                            symbolStyle: symbolStyle.copyWith(color: taxColor.withOpacity(0.8)),                         
                          ),
                        ),                       
                      ] else ...[                         
                        GestureDetector(                           
                          onTap: () => _triggerTaxCalculation(context, ref, totalInterest),                           
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('Set Rate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                          ),                         
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

  Future<void> _updateDatabase(WidgetRef ref, {double? newInterest, double? newTax, bool clearInterest = false}) async {     
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
      totalInterestPayable: clearInterest ? null : (newInterest ?? account.totalInterestPayable),       
      totalTaxPayable: newTax ?? account.totalTaxPayable,     
    );   
  }

  Future<void> _triggerInterestEdit(BuildContext context, WidgetRef ref, double currentAmount, bool isCustom) async {     
    HapticFeedback.lightImpact();     
    final result = await InterestPayableBottomSheet.show(context, currentAmount, isCustom);     
    if (result != null) {       
      if (result == -1.0) {         
        await _updateDatabase(ref, clearInterest: true);       
      } else {         
        await _updateDatabase(ref, newInterest: result);       
      }     
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