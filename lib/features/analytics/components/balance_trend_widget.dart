import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../accounts/providers/account_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../../core/database/app_database.dart';

enum TrendTimeframe { week, month, year, allTime, custom }

class BalanceTrendWidget extends ConsumerStatefulWidget {
  const BalanceTrendWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<BalanceTrendWidget> createState() => _BalanceTrendWidgetState();
}

class _BalanceTrendWidgetState extends ConsumerState<BalanceTrendWidget> {
  String _accountFilterId = 'ALL'; 
  TrendTimeframe _timeframe = TrendTimeframe.month;
  
  DateTime? _customStart;
  DateTime? _customEnd;

  double? _touchX;

  String _formatShortDate(DateTime d) {
    return '${d.day} ${DateTimeConstants.shortMonths[d.month - 1]}';
  }

  Future<void> _pickCustomDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: Theme.of(context).colorScheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeframe = TrendTimeframe.custom;
        _customStart = picked.start;
        _customEnd = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  void _showAccountFilterSheet(List<Account> accounts) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 12),
                      decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Filter Chart', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildSheetOption(ctx, 'All Accounts', 'ALL', Icons.language_rounded, theme),
                        _buildSheetOption(ctx, 'Assets Only', 'ASSETS', Icons.account_balance_rounded, theme),
                        _buildSheetOption(ctx, 'Liabilities Only', 'CREDIT', Icons.credit_card_rounded, theme),
                        
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                          child: Text('SPECIFIC ACCOUNTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary)),
                        ),
                        
                        ...accounts.where((a) => a.type != 'Loan').map((acc) => _buildSheetOption(
                          ctx, 
                          acc.name, 
                          acc.id, 
                          acc.type == 'Credit Cards' ? Icons.credit_card_rounded : Icons.account_balance_wallet_rounded, 
                          theme,
                          subtitle: acc.providerName,
                        )).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildSheetOption(BuildContext ctx, String title, String value, IconData icon, ThemeData theme, {String? subtitle}) {
    final isSelected = _accountFilterId == value;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, size: 18, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)) : null,
      trailing: isSelected ? Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary) : null,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _accountFilterId = value);
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return accountsAsync.when(
      loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => SizedBox(height: 220, child: Center(child: Text('Error: $e'))),
      data: (rawAccounts) {
        return transactionsAsync.when(
          loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
          error: (e, st) => SizedBox(height: 220, child: Center(child: Text('Error: $e'))),
          data: (transactions) {
            
            final targetAccounts = rawAccounts.where((a) {
              if (a.type == 'Loan') return false; 
              if (_accountFilterId == 'ASSETS' && a.type == 'Credit Cards') return false;
              if (_accountFilterId == 'CREDIT' && a.type != 'Credit Cards') return false;
              if (_accountFilterId != 'ALL' && _accountFilterId != 'ASSETS' && _accountFilterId != 'CREDIT') {
                return a.id == _accountFilterId;
              }
              return true;
            }).toList();

            final targetIds = targetAccounts.map((a) => a.id).toSet();

            double currentTotalBalance = targetAccounts.fold(0.0, (sum, acc) => sum + acc.balance);
            double totalImpact = 0.0;

            for (var txData in transactions) {
              final t = txData.transaction;
              bool fromTarget = targetIds.contains(t.accountId);
              bool toTarget = targetIds.contains(t.toAccountId);

              if (t.type == 'Income' && fromTarget) {
                totalImpact += t.amount;
              } else if (t.type == 'Expense' && fromTarget) {
                totalImpact -= t.amount;
              } else if (t.type == 'Transfer') {
                if (fromTarget && !toTarget) totalImpact -= t.amount;
                if (!fromTarget && toTarget) totalImpact += t.amount;
              }
            }

            double runningBal = currentTotalBalance - totalImpact;

            Map<DateTime, List<dynamic>> txByDate = {};
            for (var txData in transactions) {
              final t = txData.transaction;
              DateTime pureDate = DateTime(t.date.year, t.date.month, t.date.day);
              txByDate.putIfAbsent(pureDate, () => []).add(txData);
            }

            DateTime now = DateTime.now();
            DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
            DateTime start;

            if (_timeframe == TrendTimeframe.custom && _customStart != null && _customEnd != null) {
              start = DateTime(_customStart!.year, _customStart!.month, _customStart!.day);
              end = _customEnd!;
            } else {
              switch (_timeframe) {
                case TrendTimeframe.week:
                  start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
                  break;
                case TrendTimeframe.month:
                  start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
                  break;
                case TrendTimeframe.year:
                  start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 364));
                  break;
                case TrendTimeframe.allTime:
                default:
                  if (transactions.isEmpty) {
                    start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
                  } else {
                    final oldestTx = transactions.last.transaction.date;
                    start = DateTime(oldestTx.year, oldestTx.month, oldestTx.day);
                  }
                  break;
              }
            }

            DateTime absoluteStart = transactions.isEmpty 
                ? DateTime(now.year, now.month, now.day) 
                : DateTime(transactions.last.transaction.date.year, transactions.last.transaction.date.month, transactions.last.transaction.date.day);
            
            if (start.isBefore(absoluteStart) && _timeframe != TrendTimeframe.custom) {
              absoluteStart = start;
            } else if (_timeframe == TrendTimeframe.custom) {
              absoluteStart = start;
            }

            Map<DateTime, double> plotData = {};
            DateTime pointer = absoluteStart;
            
            double highestBal = runningBal;
            double lowestBal = runningBal;

            while (!pointer.isAfter(end)) {
              if (txByDate.containsKey(pointer)) {
                for (var txData in txByDate[pointer]!) {
                  final t = txData.transaction;
                  bool fromTarget = targetIds.contains(t.accountId);
                  bool toTarget = targetIds.contains(t.toAccountId);

                  if (t.type == 'Income' && fromTarget) {
                    runningBal += t.amount;
                  } else if (t.type == 'Expense' && fromTarget) {
                    runningBal -= t.amount;
                  } else if (t.type == 'Transfer') {
                    if (fromTarget && !toTarget) runningBal -= t.amount;
                    if (!fromTarget && toTarget) runningBal += t.amount;
                  }
                }
              }

              if (!pointer.isBefore(start)) {
                plotData[pointer] = runningBal;
                if (runningBal > highestBal) highestBal = runningBal;
                if (runningBal < lowestBal) lowestBal = runningBal;
              }
              pointer = pointer.add(const Duration(days: 1));
            }

            final points = plotData.values.toList();
            final pointDates = plotData.keys.toList();
            
            if (highestBal == lowestBal) {
              highestBal += 100;
              lowestBal -= 100;
            }

            bool isLiabilityView = _accountFilterId == 'CREDIT' || (targetAccounts.isNotEmpty && targetAccounts.every((a) => a.type == 'Credit Cards'));
            
            // --- NEW: VIBRANT CHART COLORS ---
            Color trendColor = isLiabilityView ? Colors.redAccent.shade400 : Colors.lightBlue.shade400;

            String dropdownLabel = 'All Accounts';
            if (_accountFilterId == 'ASSETS') dropdownLabel = 'Assets Only';
            else if (_accountFilterId == 'CREDIT') dropdownLabel = 'Liabilities Only';
            else if (_accountFilterId != 'ALL') {
              dropdownLabel = rawAccounts.where((a) => a.id == _accountFilterId).firstOrNull?.name ?? 'Unknown';
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12), // BOXY RADIUS
                border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1.0),
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
                  // --- COMPACT HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.insights_rounded, size: 14, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 6),
                          Text('BALANCE TREND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      
                      // SLEEK DROPDOWN
                      GestureDetector(
                        onTap: () => _showAccountFilterSheet(rawAccounts),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                Text(dropdownLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // --- COMPACT HERO BALANCE ---
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: CurrencyText(
                      amount: currentTotalBalance.abs(),
                      sign: currentTotalBalance < 0 || isLiabilityView ? '-₹ ' : '₹ ',
                      amountStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: theme.colorScheme.onSurface),
                      symbolStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // --- PROFESSIONAL AXIS CHART ---
                  GestureDetector(
                    behavior: HitTestBehavior.opaque, 
                    onLongPressStart: (details) {
                      HapticFeedback.selectionClick();
                      setState(() => _touchX = details.localPosition.dx);
                    },
                    onLongPressMoveUpdate: (details) => setState(() => _touchX = details.localPosition.dx),
                    onLongPressEnd: (_) => setState(() => _touchX = null),
                    onLongPressCancel: () => setState(() => _touchX = null),
                    child: SizedBox(
                      height: 120, // REDUCED HEIGHT
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BoxyGridChartPainter(
                          data: points,
                          dates: pointDates,
                          minY: lowestBal,
                          maxY: highestBal,
                          lineColor: trendColor,
                          gradientColors: [
                            trendColor.withOpacity(isDark ? 0.3 : 0.2),
                            trendColor.withOpacity(0.0),
                          ],
                          textColor: theme.colorScheme.onSurfaceVariant,
                          gridColor: theme.dividerColor,
                          startDateText: _formatShortDate(start),
                          endDateText: _formatShortDate(end),
                          touchX: _touchX, 
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // --- SLIM TIMEFRAME SELECTOR ---
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(isDark ? 0.3 : 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildTimeframePill('1W', TrendTimeframe.week, theme),
                        _buildTimeframePill('1M', TrendTimeframe.month, theme),
                        _buildTimeframePill('1Y', TrendTimeframe.year, theme),
                        _buildTimeframePill('ALL', TrendTimeframe.allTime, theme),
                        
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickCustomDateRange,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: _timeframe == TrendTimeframe.custom ? theme.colorScheme.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: _timeframe == TrendTimeframe.custom ? [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 2, offset: const Offset(0, 1))] : [],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_month_rounded, size: 10, color: _timeframe == TrendTimeframe.custom ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    '',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: _timeframe == TrendTimeframe.custom ? FontWeight.w900 : FontWeight.w600,
                                      color: _timeframe == TrendTimeframe.custom ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeframePill(String label, TrendTimeframe type, ThemeData theme) {
    bool isSelected = _timeframe == type;
    final isDark = theme.brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _timeframe = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 2, offset: const Offset(0, 1))] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Boxy Grid Chart Painter with Faded Axes
class _BoxyGridChartPainter extends CustomPainter {
  final List<double> data;
  final List<DateTime> dates;
  final double minY;
  final double maxY;
  final Color lineColor;
  final List<Color> gradientColors;
  final Color textColor;
  final Color gridColor;
  final String startDateText;
  final String endDateText;
  final double? touchX; 

  _BoxyGridChartPainter({
    required this.data,
    required this.dates,
    required this.minY,
    required this.maxY,
    required this.lineColor,
    required this.gradientColors,
    required this.textColor,
    required this.gridColor,
    required this.startDateText,
    required this.endDateText,
    required this.touchX,
  });

  String _formatK(double value) {
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final textStyle = TextStyle(color: textColor.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w600);
    
    final maxLabel = TextPainter(text: TextSpan(text: _formatK(maxY), style: textStyle), textDirection: TextDirection.ltr)..layout();
    final midLabel = TextPainter(text: TextSpan(text: _formatK((maxY + minY) / 2), style: textStyle), textDirection: TextDirection.ltr)..layout();
    final minLabel = TextPainter(text: TextSpan(text: _formatK(minY), style: textStyle), textDirection: TextDirection.ltr)..layout();

    final leftPadding = [maxLabel.width, midLabel.width, minLabel.width].reduce(max) + 8.0;
    const bottomPadding = 16.0;
    
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    // --- FADED GRID LINES ---
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Y-Axis Lines & Labels
    canvas.drawLine(Offset(leftPadding, 0), Offset(size.width, 0), gridPaint);
    maxLabel.paint(canvas, Offset(leftPadding - maxLabel.width - 4, -maxLabel.height / 2));

    canvas.drawLine(Offset(leftPadding, chartHeight / 2), Offset(size.width, chartHeight / 2), gridPaint);
    midLabel.paint(canvas, Offset(leftPadding - midLabel.width - 4, (chartHeight / 2) - (midLabel.height / 2)));

    canvas.drawLine(Offset(leftPadding, chartHeight), Offset(size.width, chartHeight), gridPaint);
    minLabel.paint(canvas, Offset(leftPadding - minLabel.width - 4, chartHeight - (minLabel.height / 2)));

    // X-Axis Labels
    final startLabel = TextPainter(text: TextSpan(text: startDateText, style: textStyle), textDirection: TextDirection.ltr)..layout();
    final endLabel = TextPainter(text: TextSpan(text: endDateText, style: textStyle), textDirection: TextDirection.ltr)..layout();

    startLabel.paint(canvas, Offset(leftPadding, size.height - startLabel.height));
    endLabel.paint(canvas, Offset(size.width - endLabel.width, size.height - endLabel.height));

    // --- DRAW DATA LINE ---
    if (data.length == 1) {
      final y = chartHeight - ((data[0] - minY) / (maxY - minY)) * chartHeight;
      canvas.drawCircle(Offset(leftPadding + (chartWidth / 2), y), 3, Paint()..color = lineColor);
      return;
    }

    final double stepX = chartWidth / (data.length - 1);
    final Path path = Path();
    
    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final x = leftPadding + (i * stepX);
      final y = chartHeight - ((data[i] - minY) / (maxY - minY)) * chartHeight;
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final Path fillPath = Path.from(path);
    fillPath.lineTo(leftPadding + chartWidth, chartHeight);
    fillPath.lineTo(leftPadding, chartHeight);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(leftPadding, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);
    
    // --- INTERACTIVE TOOLTIP ---
    if (touchX != null) {
      int closestIndex = ((touchX! - leftPadding) / stepX).round().clamp(0, data.length - 1);
      final p = points[closestIndex];

      final vLinePaint = Paint()
        ..color = textColor.withOpacity(0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      double dashY = 0;
      while (dashY < chartHeight) {
        canvas.drawLine(Offset(p.dx, dashY), Offset(p.dx, dashY + 4), vLinePaint);
        dashY += 8;
      }

      canvas.drawCircle(p, 8.0, Paint()..color = lineColor.withOpacity(0.3));
      canvas.drawCircle(p, 4.0, Paint()..color = lineColor);
      canvas.drawCircle(p, 2.0, Paint()..color = Colors.white);

      final rawVal = data[closestIndex];
      final valStr = rawVal < 0 ? '-₹ ${rawVal.abs().toStringAsFixed(0)}' : '₹ ${rawVal.toStringAsFixed(0)}';
      final dateStr = '${dates[closestIndex].day} ${DateTimeConstants.shortMonths[dates[closestIndex].month - 1]}';

      final valuePainter = TextPainter(text: TextSpan(text: valStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: -0.5)), textDirection: TextDirection.ltr)..layout();
      final datePainter = TextPainter(text: TextSpan(text: dateStr, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 9)), textDirection: TextDirection.ltr)..layout();

      final ttWidth = max(valuePainter.width, datePainter.width) + 16;
      final ttHeight = valuePainter.height + datePainter.height + 12;

      double ttX = p.dx - (ttWidth / 2);
      double ttY = p.dy - ttHeight - 12;

      if (ttX < leftPadding) ttX = leftPadding;
      if (ttX + ttWidth > size.width) ttX = size.width - ttWidth;
      if (ttY < 0) ttY = p.dy + 12; 

      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(ttX, ttY, ttWidth, ttHeight), const Radius.circular(6));
      
      canvas.drawShadow(Path()..addRRect(rect), Colors.black, 4, false);
      canvas.drawRRect(rect, Paint()..color = Colors.grey.shade900);

      valuePainter.paint(canvas, Offset(ttX + 8, ttY + 6));
      datePainter.paint(canvas, Offset(ttX + 8, ttY + 6 + valuePainter.height + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BoxyGridChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.minY != minY || 
           oldDelegate.maxY != maxY || 
           oldDelegate.lineColor != lineColor ||
           oldDelegate.touchX != touchX; 
  }
}