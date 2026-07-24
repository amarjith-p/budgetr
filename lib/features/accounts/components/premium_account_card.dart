import 'dart:math';
import 'package:budgetr/core/components/currency_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';

class PremiumAccountCard extends StatefulWidget {
  final Account account;
  final VoidCallback? onCardTap;
  const PremiumAccountCard({
    Key? key, 
    required this.account, 
    this.onCardTap
  }) : super(key: key);

  @override
  State<PremiumAccountCard> createState() => _PremiumAccountCardState();
}

class _PremiumAccountCardState extends State<PremiumAccountCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    HapticFeedback.lightImpact();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  String _getOrdinal(int? number) {
    if (number == null) return 'N/A';
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCreditCard = widget.account.type == 'Credit Cards';
    
    final bgColor = isCreditCard
         ? theme.colorScheme.primary
         : (isDark ? const Color(0xFF141414) : const Color(0xFF1E1E1E));
    final fgColor = isCreditCard
         ? theme.colorScheme.onPrimary
         : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final isFrontVisible = angle <= pi / 2;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onCardTap,
            borderRadius: BorderRadius.circular(16.0),
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: isFrontVisible
                  ? _buildFront(bgColor, fgColor, isCreditCard)
                  : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _buildBack(bgColor, fgColor, isCreditCard),
                    ),
            ),
          ),
        );
      },
    );
  }

// ... inside _PremiumAccountCardState
  Widget _buildFront(Color bgColor, Color fgColor, bool isCreditCard) {
    final textTheme = Theme.of(context).textTheme; // POM
    final balance = widget.account.balance;
    final labelText = isCreditCard ? 'OUTSTANDING BALANCE' : 'CURRENT BALANCE';

    return Container(
      height: 190,
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.transparent),
        boxShadow: [
          BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.account.providerName.toUpperCase(),
                  style: textTheme.titleMedium?.copyWith(color: fgColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleCard,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(color: fgColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.info_outline_rounded, color: fgColor.withOpacity(0.9), size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.contactless_outlined, color: fgColor.withOpacity(0.7)),
                ],
              ),
            ],
          ),
          Text(
            '**** **** **** ${widget.account.last4}',
            style: TextStyle(color: fgColor.withOpacity(0.8), fontSize: 18, fontFamily: 'monospace', letterSpacing: 2.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.account.name.toUpperCase(), style: textTheme.bodySmall?.copyWith(color: fgColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(widget.account.type, style: textTheme.bodySmall?.copyWith(color: fgColor.withOpacity(0.6), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(labelText, style: textTheme.labelSmall?.copyWith(color: fgColor.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      // POM: Replaced messy inline formatting with Global Component
                      child: CurrencyText(
                        amount: balance,
                        showSignForPositive: true,
                        amountStyle: textTheme.headlineSmall!.copyWith(color: fgColor),
                        symbolStyle: textTheme.titleMedium?.copyWith(color: fgColor.withOpacity(0.9)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(Color bgColor, Color fgColor, bool isCreditCard) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Container(height: 40, color: Colors.black87),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
            child: isCreditCard
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBackData(fgColor, 'BILL DATE', _getOrdinal(widget.account.billDate)),
                    _buildBackData(fgColor, 'DUE DATE', _getOrdinal(widget.account.dueDate)),
                    // --- STRICT 2 DECIMALS ---
                    _buildBackData(fgColor, 'CREDIT LIMIT', '₹${widget.account.creditLimit?.toStringAsFixed(2) ?? "0.00"}'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBackData(fgColor, 'ACCOUNT TYPE', widget.account.type),
                    _buildBackData(fgColor, 'ADDED ON', '${widget.account.createdAt.day}/${widget.account.createdAt.month}/${widget.account.createdAt.year}'),
                  ],
                ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleCard,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg, vertical: DesignTokens.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('FLIP TO FRONT', style: TextStyle(color: fgColor.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  Icon(Icons.flip_to_front_rounded, color: fgColor.withOpacity(0.7), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackData(Color fgColor, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: fgColor.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: fgColor, fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}