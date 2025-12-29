import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/bank_list.dart';
import '../models/credit_models.dart';

class CreditCardTile extends StatelessWidget {
  final CreditCardModel card;
  final NumberFormat currency;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const CreditCardTile({
    super.key,
    required this.card,
    required this.currency,
    required this.accentColor,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    double displayBalance = -card.currentBalance;
    if (displayBalance.abs() < 0.01) displayBalance = 0.0;
    final bool isSurplus = displayBalance > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1B263B),
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: CircleAvatar(
                radius: 90,
                backgroundColor: accentColor.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                BankConstants.getBankLogoPath(card.bankName),
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Center(
                                  child: Text(
                                    BankConstants.getBankInitials(
                                      card.bankName,
                                    ),
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            card.bankName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: onMoreTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.more_horiz,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "CREDIT BALANCE",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currency.format(displayBalance),
                            style: TextStyle(
                              color: isSurplus
                                  ? const Color(0xFF4CC9F0)
                                  : Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
