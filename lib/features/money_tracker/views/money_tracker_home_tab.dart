import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../../../core/database/app_database.dart'; 
import '../../../core/theme/design_tokens.dart'; 
import '../../../core/components/currency_text.dart'; 
import '../../accounts/providers/account_provider.dart';
import '../../accounts/providers/loan_math_provider.dart'; // <-- ADDED
import '../../transactions/views/account_transactions_page.dart'; 
import '../../transactions/views/credit_transaction_page.dart';
import '../../transactions/views/loan_transaction_page.dart'; // <-- ADDED
import '../components/mini_account_card.dart'; 
import '../components/manage_accounts_bottom_sheet.dart'; 
import '../components/credit_payable_bottom_sheet.dart'; 

class MoneyTrackerHomeTab extends ConsumerWidget {   
  const MoneyTrackerHomeTab({Key? key}) : super(key: key);   
  
  void _openManageSheet(BuildContext context, List<Account> allAccounts) {     
    showModalBottomSheet(       
      context: context,       
      isScrollControlled: true,       
      useSafeArea: true,       
      backgroundColor: Colors.transparent,       
      builder: (ctx) => ManageAccountsBottomSheet(allAccounts: allAccounts),     
    );   
  }

  void _openPayableSheet(BuildContext context, List<Account> bankAccounts, double crBalance) {     
    HapticFeedback.lightImpact();     
    showModalBottomSheet(       
      context: context,       
      isScrollControlled: true,       
      useSafeArea: true,       
      backgroundColor: Colors.transparent,       
      builder: (ctx) => CreditPayableBottomSheet(         
        bankAccounts: bankAccounts,          
        totalCreditLiability: crBalance,       
      ),     
    );   
  }

  @override   
  Widget build(BuildContext context, WidgetRef ref) {     
    final accountsAsync = ref.watch(accountsStreamProvider);     
    final theme = Theme.of(context);     
    final isDark = theme.brightness == Brightness.dark;     
    
    return Scaffold(       
      backgroundColor: Colors.transparent,       
      body: accountsAsync.when(         
        loading: () => const Center(child: CircularProgressIndicator()),         
        error: (e, st) => Center(child: Text('Error: $e')),         
        data: (accounts) {                      
          final visibleAccounts = accounts.where((a) => !a.isHidden).toList();           
          
          // --- STRICT SEPARATION OF ASSETS AND LIABILITIES ---
          final bankAccounts = visibleAccounts.where((a) => a.type != 'Credit Cards' && a.type != 'Loan').toList();           
          final creditCards = visibleAccounts.where((a) => a.type == 'Credit Cards').toList();           
          final loans = visibleAccounts.where((a) => a.type == 'Loan' && !a.isClosed).toList();
          final double drBalance = bankAccounts.fold(0.0, (sum, acc) => sum + acc.balance);           
          
          // Add Credit Cards to Liability
          double crBalance = creditCards.fold(0.0, (sum, acc) => sum + acc.balance);           
          
          // Add Total Outstanding Loans to Liability
          for (var loan in loans) {
            crBalance += ref.watch(loanTotalOutstandingProvider(loan));
          }
          
          final double allocatedFunds = bankAccounts.where((a) => a.isCreditPayable).fold(0.0, (sum, acc) => sum + acc.balance);           
          final double difference = allocatedFunds - crBalance.abs();           
          
          // Merge debts for the bottom carousel
          final debtAccounts = [...creditCards, ...loans];

          if (accounts.isEmpty) {             
            return Center(               
              child: Text(                 
                'Add accounts to populate your dashboard',                  
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)               
              )             
            );           
          }           
          return CustomScrollView(             
            physics: const BouncingScrollPhysics(),             
            slivers: [               
              SliverToBoxAdapter(                 
                child: Padding(                   
                  padding: const EdgeInsets.fromLTRB(DesignTokens.spacingLg, DesignTokens.spacingSm, DesignTokens.spacingLg, DesignTokens.spacingSm),                   
                  child: Row(                     
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,                     
                    children: [                       
                      Expanded(                         
                        child: Align(                           
                          alignment: Alignment.centerLeft,                           
                          child: FittedBox(                             
                            fit: BoxFit.scaleDown,                             
                            child: _buildSummaryPill(context, drBalance, crBalance, difference, bankAccounts, theme),                           
                          ),                         
                        ),                       
                      ),                                              
                      const SizedBox(width: 12),                       
                      SizedBox(                         
                        width: 36,                         
                        height: 36,                         
                        child: IconButton(                           
                          padding: EdgeInsets.zero,                           
                          onPressed: () => _openManageSheet(context, accounts),                           
                          icon: Icon(Icons.tune_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),                           
                          tooltip: 'Customize Dashboard',                           
                          style: IconButton.styleFrom(                             
                            backgroundColor: theme.colorScheme.surface,                             
                            shape: RoundedRectangleBorder(                               
                              borderRadius: BorderRadius.circular(10),                               
                              side: BorderSide(color: theme.dividerColor, width: 1.0),                             
                            ),                           
                          ),                         
                        ),                       
                      ),                     
                    ],                   
                  ),                 
                ),               
              ),               
              const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spacingSm)),                              
              
              if (bankAccounts.isNotEmpty) ...[                 
                SliverToBoxAdapter(child: _buildAccountCarousel(context, bankAccounts)),               
              ],               
              
              if (bankAccounts.isNotEmpty && debtAccounts.isNotEmpty) ...[                 
                SliverToBoxAdapter(                   
                  child: Padding(                     
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingMd),                     
                    child: Divider(                       
                      indent: DesignTokens.spacingLg,                       
                      endIndent: DesignTokens.spacingLg,                       
                      color: theme.dividerColor.withOpacity(isDark ? 0.3 : 0.5),                       
                      thickness: 1.5,                     
                    ),                   
                  ),                 
                ),               
              ],               
              
              if (debtAccounts.isNotEmpty) ...[                 
                SliverToBoxAdapter(child: _buildAccountCarousel(context, debtAccounts)),               
              ],               
              
              if (bankAccounts.isEmpty && debtAccounts.isEmpty && accounts.isNotEmpty)                  
                 SliverFillRemaining(                    
                   hasScrollBody: false,                    
                   child: Center(                      
                     child: TextButton.icon(                        
                       onPressed: () => _openManageSheet(context, accounts),                         
                        icon: const Icon(Icons.visibility_off_rounded),                         
                        label: const Text('All accounts hidden. Tap to manage.')                      
                     ),                    
                   ),                  
                 ),               
              const SliverToBoxAdapter(child: SizedBox(height: 120)),             
            ],           
          );         
        },       
      ),     
    );   
  }

  Widget _buildSummaryPill(BuildContext context, double drBalance, double crBalance, double difference, List<Account> bankAccounts, ThemeData theme) {     
    final isDark = theme.brightness == Brightness.dark;          
    
    Color diffColor = Colors.blueAccent.shade700;     
    String diffLabel = 'Tally:'; 
    if (difference > 0) {       
      diffColor = Colors.green.shade600;       
      diffLabel = 'Surplus:'; 
    } else if (difference < 0) {       
      diffColor = theme.colorScheme.error;       
      diffLabel = 'Short:'; 
    }     
    
    return Container(       
      decoration: BoxDecoration(         
        color: theme.colorScheme.surface,         
        borderRadius: BorderRadius.circular(20),         
        border: Border.all(color: theme.dividerColor, width: 1.0),         
        boxShadow: [           
          BoxShadow(             
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),             
            blurRadius: 8,             
            offset: const Offset(0, 2),           
          )         
        ],       
      ),       
      child: Material(         
        color: Colors.transparent,         
        child: InkWell(           
          borderRadius: BorderRadius.circular(20),           
          onTap: () => _openPayableSheet(context, bankAccounts, crBalance),           
          child: Padding(             
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),             
            child: Row(               
              mainAxisSize: MainAxisSize.min,               
              children: [                 
                _buildPillMetric('Dr:', drBalance, theme.colorScheme.primary, theme),                                  
                Container(margin: const EdgeInsets.symmetric(horizontal: 10), height: 14, width: 1.5, color: theme.dividerColor),                                  
                _buildPillMetric('Cr:', crBalance, theme.colorScheme.error, theme),                 
                Container(margin: const EdgeInsets.symmetric(horizontal: 10), height: 14, width: 1.5, color: theme.dividerColor),                                  
                _buildPillMetric(diffLabel, difference, diffColor, theme, showPlus: difference > 0),               
              ],             
            ),           
          ),         
        ),       
      ),     
    );   
  }

  Widget _buildPillMetric(String label, double amount, Color color, ThemeData theme, {bool showPlus = false}) {     
    String sign = amount < 0 ? '- ' : (showPlus && amount > 0 ? '+ ' : ' ');     
    return Row(       
      mainAxisSize: MainAxisSize.min,       
      crossAxisAlignment: CrossAxisAlignment.center,       
      children: [         
        Text(           
          label,            
          style: TextStyle(             
            fontSize: 10,              
            fontWeight: FontWeight.w900,              
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)           
          )         
        ),         
        const SizedBox(width: 4),         
        CurrencyText(           
          amount: amount.abs(),           
          sign: sign,           
          amountStyle: TextStyle(             
            fontSize: 13,              
            fontWeight: FontWeight.w800,              
            color: color,              
            letterSpacing: -0.2           
          ),           
          symbolStyle: TextStyle(             
            fontSize: 10,              
            color: color.withOpacity(0.8)           
          ),         
        ),       
      ],     
    );   
  }

  Widget _buildAccountCarousel(BuildContext context, List<Account> accounts) {     
    if (accounts.isEmpty) return const SizedBox.shrink();     
    int mid = (accounts.length / 2).ceil();     
    final topRow = accounts.sublist(0, mid);     
    final bottomRow = accounts.sublist(mid);     
    
    return Column(       
      crossAxisAlignment: CrossAxisAlignment.start,       
      children: [         
        SingleChildScrollView(           
          scrollDirection: Axis.horizontal,           
          physics: const BouncingScrollPhysics(),           
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),           
          child: Row(             
            children: topRow.map((acc) => Padding(               
              padding: const EdgeInsets.only(right: 12.0, bottom: 12.0),               
              child: MiniAccountCard(                 
                account: acc,                 
                onTap: () => _navigateToAccount(context, acc),               
              ),             
            )).toList(),           
          ),         
        ),                  
        if (bottomRow.isNotEmpty)           
          SingleChildScrollView(             
            scrollDirection: Axis.horizontal,             
            physics: const BouncingScrollPhysics(),             
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),             
            child: Row(               
              children: bottomRow.map((acc) => Padding(                 
                padding: const EdgeInsets.only(right: 12.0),                 
                child: MiniAccountCard(                   
                  account: acc,                   
                  onTap: () => _navigateToAccount(context, acc),                 
                ),               
              )).toList(),             
            ),           
          ),       
      ],     
    );   
  }

  void _navigateToAccount(BuildContext context, Account acc) {     
    HapticFeedback.lightImpact();     
    if (acc.type == 'Credit Cards') {       
      Navigator.push(context, MaterialPageRoute(builder: (_) => CreditTransactionPage(account: acc)));     
    } else if (acc.type == 'Loan') {       
      Navigator.push(context, MaterialPageRoute(builder: (_) => LoanTransactionPage(account: acc)));     
    } else {       
      Navigator.push(context, MaterialPageRoute(builder: (_) => AccountTransactionsPage(account: acc)));     
    }   
  }
}