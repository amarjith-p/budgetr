import 'package:flutter/material.dart';

/// GLOBAL POM COMPONENT: Currency Formatting
/// Single Source of Truth for strict 2-decimal financial formatting and Rupee symbol isolation.
class CurrencyText extends StatelessWidget {
  final double amount;
  final String? sign; // <-- RESTORED: Allows explicit overrides (like '-₹' or '+₹')
  final TextStyle amountStyle;
  final TextStyle? symbolStyle;
  final TextAlign textAlign;
  final bool showSignForPositive; // If true, forces a '+' sign for numbers > 0 (when sign is null)

  const CurrencyText({
    Key? key,
    required this.amount,
    this.sign, // <-- RESTORED
    required this.amountStyle,
    this.symbolStyle,
    this.textAlign = TextAlign.left,
    this.showSignForPositive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Determine Sign Globally (Use explicit sign if provided, else auto-calculate)
    String displaySign = sign ?? '₹';
    if (sign == null) {
      if (amount < 0) {
        displaySign = '-₹';
      } else if (amount > 0 && showSignForPositive) {
        displaySign = '+₹';
      }
    }

    // 2. Prevent symbol blooming by locking stroke weight (Fixes the blob issue)
    final baseSymbolStyle = symbolStyle ?? amountStyle;
    final safeSymbolStyle = baseSymbolStyle.copyWith(
      fontWeight: FontWeight.w600, // Locks the stroke weight
      fontSize: amountStyle.fontSize != null ? amountStyle.fontSize! * 0.85 : null, // Scales cleanly
      letterSpacing: 0, 
    );

    return RichText(
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: displaySign, style: safeSymbolStyle),
          // STRICT 2-DECIMAL RULE APPLIED GLOBALLY
          TextSpan(text: amount.abs().toStringAsFixed(2), style: amountStyle),
        ],
      ),
    );
  }
}