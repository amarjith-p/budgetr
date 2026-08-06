import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// GLOBAL UTILITY: Standardized Currency Formatting
class CurrencyFormatter {
  static String format(double amount) {
    // Enforces Indian Numbering System (e.g., 1,00,000.00) with strict 2 decimals
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(amount);
  }
}

/// GLOBAL POM COMPONENT: Currency Text Wrapper
/// Single Source of Truth for strict 2-decimal financial formatting and Rupee symbol isolation.
class CurrencyText extends StatelessWidget {
  final double amount;
  final String? sign;
  final TextStyle amountStyle;
  final TextStyle? symbolStyle;
  final TextAlign textAlign;
  final bool showSignForPositive;

  const CurrencyText({
    Key? key,
    required this.amount,
    this.sign,
    required this.amountStyle,
    this.symbolStyle,
    this.textAlign = TextAlign.left,
    this.showSignForPositive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Determine Sign Globally
    String displaySign = sign ?? '₹ ';
    if (sign == null) {
      if (amount < 0) {
        displaySign = '-₹ ';
      } else if (amount > 0 && showSignForPositive) {
        displaySign = '+₹ ';
      }
    }

    // 2. Prevent symbol blooming by locking stroke weight
    final baseSymbolStyle = symbolStyle ?? amountStyle;
    final safeSymbolStyle = baseSymbolStyle.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: amountStyle.fontSize != null
          ? amountStyle.fontSize! * 0.85
          : null,
      letterSpacing: 0,
    );

    return RichText(
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: displaySign, style: safeSymbolStyle),
          // STRICT GLOBAL COMMA & DECIMAL RULE APPLIED
          TextSpan(
            text: CurrencyFormatter.format(amount.abs()),
            style: amountStyle,
          ),
        ],
      ),
    );
  }
}
