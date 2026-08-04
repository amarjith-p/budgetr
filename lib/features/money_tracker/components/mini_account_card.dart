import 'dart:ui'; 
import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../../../core/database/app_database.dart'; 
import '../../../core/components/currency_text.dart'; 
import '../../accounts/providers/loan_math_provider.dart'; 

class MiniAccountCard extends ConsumerWidget {   
  final Account account;   
  final VoidCallback onTap;   
  
  const MiniAccountCard({     
    Key? key,     
    required this.account,     
    required this.onTap,   
  }) : super(key: key);   
  
  @override   
  Widget build(BuildContext context, WidgetRef ref) {     
    final theme = Theme.of(context);     
    final isDark = theme.brightness == Brightness.dark;     
    
    final isCreditCard = account.type == 'Credit Cards';     
    final isLoan = account.type == 'Loan';
    
    // UI RULE: Treat both Credit Cards and Loans as visual liabilities for the background
    final isDebtCard = isCreditCard || isLoan; 
    
    final bgColor = isDebtCard         
        ? theme.colorScheme.primary.withOpacity(0.85)         
        : theme.colorScheme.surface.withOpacity(isDark ? 0.5 : 0.8);              
        
    final fgColor = isDebtCard ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;          
    
    // --- FETCH EXACT UNCAPPED BALANCE ---
    final double rawBalance = isLoan ? ref.watch(loanTotalOutstandingProvider(account)) : account.balance;
    
    // --- CORRECTED SIGN LOGIC ---
    String signText = ' ';
    
    if (isLoan) {
      // For Loans: Positive is Debt (-), Negative is Surplus (+)
      signText = rawBalance > 0 ? '- ' : (rawBalance < 0 ? '+ ' : ' ');
    } else {
      // For Banks & Credit Cards: Negative is Debt/Overdrawn (-), Positive is Cash/Surplus ( )
      signText = rawBalance < 0 ? '- ' : ' ';
    }

    IconData cardIcon = Icons.account_balance_wallet_rounded;
    if (isCreditCard) cardIcon = Icons.credit_card_rounded;
    if (isLoan) cardIcon = Icons.account_balance_rounded;
    
    return Container(       
      width: 170,        
      decoration: BoxDecoration(         
        borderRadius: BorderRadius.circular(12.0),         
        boxShadow: [           
          BoxShadow(             
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),             
            blurRadius: 8,             
            offset: const Offset(0, 2),           
          )         
        ],       
      ),       
      child: ClipRRect(         
        borderRadius: BorderRadius.circular(12.0),         
        child: BackdropFilter(           
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),           
          child: Material(             
            color: Colors.transparent,             
            child: InkWell(               
              onTap: onTap,               
              child: Container(                 
                padding: const EdgeInsets.all(10.0),                  
                decoration: BoxDecoration(                   
                  color: bgColor,                   
                  borderRadius: BorderRadius.circular(12.0),                   
                  border: Border.all(                     
                    color: isDebtCard                          
                         ? theme.colorScheme.onPrimary.withOpacity(0.2)                          
                         : theme.dividerColor.withOpacity(0.5),                      
                    width: 1.0,                   
                  ),                 
                ),                 
                child: Column(                   
                  crossAxisAlignment: CrossAxisAlignment.start,                   
                  mainAxisSize: MainAxisSize.min,                    
                  children: [                     
                    Row(                       
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,                       
                      children: [                         
                        Flexible(                           
                          child: Container(                             
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),                             
                            decoration: BoxDecoration(                               
                              color: fgColor.withOpacity(0.15),                               
                              borderRadius: BorderRadius.circular(6),                             
                            ),                             
                            child: Text(                               
                              account.providerName.toUpperCase(),                               
                              style: TextStyle(                                 
                                fontSize: 8,                                  
                                fontWeight: FontWeight.w900,                                  
                                letterSpacing: 0.5,                                  
                                color: fgColor.withOpacity(0.8)                               
                              ),                               
                              maxLines: 1,                               
                              overflow: TextOverflow.ellipsis,                             
                            ),                           
                          ),                         ),                         
                        const SizedBox(width: 6),                         
                        Icon(                           
                          cardIcon,                           
                          size: 14,                            
                          color: fgColor.withOpacity(0.5),                         
                        ),                       
                      ],                     
                    ),                                          
                    const SizedBox(height: 10),                                           
                    Row(                       
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,                       
                      crossAxisAlignment: CrossAxisAlignment.end,                       
                      children: [                         
                        Expanded(                           
                          flex: 6,                            
                          child: FittedBox(                             
                            fit: BoxFit.scaleDown,                             
                            alignment: Alignment.centerLeft,                             
                            child: Text(                               
                              account.name,                               
                              style: TextStyle(                                 
                                fontSize: 11,                                  
                                fontWeight: FontWeight.w500,                                  
                                color: fgColor,                                 
                                letterSpacing: 0.2,                                
                              ),                             
                            ),                           
                          ),                         
                        ),                         
                        const SizedBox(width: 4),                         
                        Flexible(                           
                          flex: 5,                           
                          child: FittedBox(                              
                            fit: BoxFit.scaleDown,                             
                            alignment: Alignment.centerRight,                             
                            child: CurrencyText(                               
                              amount: rawBalance.abs(), // Strict Absolute Value                              
                              sign: signText,                               
                              amountStyle: TextStyle(                                 
                                fontSize: 13,                                  
                                fontWeight: FontWeight.w900,                                  
                                color: fgColor, // Reverted to pristine foreground color                                 
                                letterSpacing: -0.5                               
                              ),                               
                              symbolStyle: TextStyle(                                 
                                fontSize: 9,                                  
                                color: fgColor.withOpacity(0.8)                               
                              ),                             
                            ),                           
                          ),                         
                        ),                       
                      ],                     
                    ),                   
                  ],                 
                ),               
              ),             
            ),           
          ),         
        ),       
      ),     
    );   
  }
}