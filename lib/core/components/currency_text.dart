import 'package:flutter/material.dart';

/// GLOBAL POM COMPONENT: Currency Formatting
/// Solves the "heavy stroke" issue for the Rupee symbol globally
/// by isolating the symbol's font weight from the amount's font weight.
class CurrencyText extends StatelessWidget {
  final double amount;
  final String sign; // e.g. '₹', '+₹', '-₹'
  final TextStyle amountStyle;
  final TextStyle? symbolStyle;
  final TextAlign textAlign;

  const CurrencyText({
    Key? key,
    required this.amount,
    this.sign = '₹',
    required this.amountStyle,
    this.symbolStyle,
    this.textAlign = TextAlign.left,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Enforce a maximum font weight of w500/w600 for the symbol
    // This explicitly prevents the Rupee symbol from blooming into a blob.
    final baseSymbolStyle = symbolStyle ?? amountStyle;
    final safeSymbolStyle = baseSymbolStyle.copyWith(
      fontWeight: FontWeight.w600, // Locks the stroke weight
      fontSize: amountStyle.fontSize != null ? amountStyle.fontSize! * 0.85 : null, // Scales it cleanly
      letterSpacing: 0, 
    );

    return RichText(
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: sign, style: safeSymbolStyle),
          TextSpan(text: amount.abs().toStringAsFixed(2), style: amountStyle),
        ],
      ),
    );
  }
}