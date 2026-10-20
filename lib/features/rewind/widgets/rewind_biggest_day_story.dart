import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/rewind_data.dart';

class RewindBiggestDayStory extends StatefulWidget {
  final RewindData data;
  final String currency;

  const RewindBiggestDayStory({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  State<RewindBiggestDayStory> createState() => _RewindBiggestDayStoryState();
}

class _ChartBarItem {
  final String label;
  final double amount;
  final bool isPeak;

  const _ChartBarItem({
    required this.label,
    required this.amount,
    required this.isPeak,
  });
}

class _RewindBiggestDayStoryState extends State<RewindBiggestDayStory>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _chartGrowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _chartGrowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.9, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDayLabel(DateTime date, bool isEn) {
    if (isEn) {
      return DateFormat('E', 'en_US').format(date);
    }
    switch (date.weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
      default:
        return 'CN';
    }
  }

  List<_ChartBarItem> _buildChartItems(
    List<RewindDaySpending> spendings,
    RewindBiggestDay biggest,
    bool isEn,
  ) {
    if (spendings.isEmpty) return [];

    // Case 1: Week (<= 7 days) -> Show each day directly
    if (spendings.length <= 7) {
      return spendings.map((day) {
        final isPeak = day.date.year == biggest.date.year &&
            day.date.month == biggest.date.month &&
            day.date.day == biggest.date.day;
        return _ChartBarItem(
          label: _formatDayLabel(day.date, isEn),
          amount: day.amount,
          isPeak: isPeak,
        );
      }).toList();
    }

    // Case 2: Month (8..31 days) -> Group into weeks or 7-8 sampled buckets
    if (spendings.length <= 31) {
      // Group by ~4-5 weeks
      final List<_ChartBarItem> items = [];
      const bucketSize = 4; // every ~4 days
      for (var i = 0; i < spendings.length; i += bucketSize) {
        final chunk = spendings.sublist(i, math.min(i + bucketSize, spendings.length));
        final totalAmount = chunk.fold<double>(0.0, (sum, e) => sum + e.amount);
        final hasPeak = chunk.any((e) =>
            e.date.year == biggest.date.year &&
            e.date.month == biggest.date.month &&
            e.date.day == biggest.date.day);

        final firstDay = chunk.first.date.day;
        final lastDay = chunk.last.date.day;
        final label = '$firstDay-$lastDay';

        items.add(_ChartBarItem(
          label: label,
          amount: totalAmount,
          isPeak: hasPeak,
        ));
      }
      return items;
    }

    // Case 3: Quarter or Year (> 31 days) -> Group by Month (12 months or 3 months)
    final Map<int, double> monthTotals = {};
    final Map<int, bool> monthHasPeak = {};

    for (final day in spendings) {
      final m = day.date.month;
      monthTotals[m] = (monthTotals[m] ?? 0.0) + day.amount;
      if (day.date.year == biggest.date.year &&
          day.date.month == biggest.date.month &&
          day.date.day == biggest.date.day) {
        monthHasPeak[m] = true;
      }
    }

    final sortedMonths = monthTotals.keys.toList()..sort();
    return sortedMonths.map((m) {
      final label = isEn ? 'M$m' : 'T$m';
      return _ChartBarItem(
        label: label,
        amount: monthTotals[m] ?? 0.0,
        isPeak: monthHasPeak[m] ?? false,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final biggest = widget.data.biggestDay;
    if (biggest == null) return const SizedBox.shrink();

    final totalExpense = widget.data.totalExpense;
    final daySharePercent = totalExpense > 0
        ? (biggest.amount / totalExpense * 100).clamp(0.0, 100.0)
        : 0.0;

    final dateFormatted = DateFormat(isEn ? 'EEEE, dd/MM/yyyy' : 'EEEE, dd/MM/yyyy', isEn ? 'en' : 'vi').format(biggest.date);

    final chartItems = _buildChartItems(biggest.dailySpendings, biggest, isEn);
    final maxAmount = chartItems.map((e) => e.amount).fold<double>(0.0, math.max);
    final safeMax = maxAmount <= 0 ? 1.0 : maxAmount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 68, 20, 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PEAK MOMENT',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isEn ? 'RECORD DAY' : 'NGÀY CHI ĐỈNH ĐIỂM',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Headline
            Text(
              isEn ? 'WHEN MONEY\nMOVED THE FASTEST.' : 'NGÀY BẠN BÙNG NỔ\nCHI TIÊU NHẤT.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 20),

            // Hero Date Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF00E5FF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateFormatted.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppCurrencyFormatter.formatFromVnd(
                      amountVnd: biggest.amount,
                      currency: widget.currency,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEn
                        ? '${biggest.transactionCount} transactions accounted for ${daySharePercent.toStringAsFixed(1)}% of total spend'
                        : '${biggest.transactionCount} giao dịch chiếm ${daySharePercent.toStringAsFixed(1)}% tổng chi tiêu cả kỳ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Adaptive Timeline Histogram Visualization
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (isEn ? 'SPENDING TIMELINE SPIKE' : 'BIỂU ĐỒ HOẠT ĐỘNG THEO KỲ').toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '⚡ ${DateFormat('dd/MM').format(biggest.date)}',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Adaptive Histogram Row
                  SizedBox(
                    height: 150,
                    child: AnimatedBuilder(
                      animation: _chartGrowAnimation,
                      builder: (context, child) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: chartItems.map((item) {
                            final heightFactor = (item.amount / safeMax * _chartGrowAnimation.value).clamp(0.06, 1.0);

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Peak indicator badge
                                    if (item.isPeak)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        margin: const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E5FF),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'TOP',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 18),

                                    // Bar
                                    Container(
                                      height: 85 * heightFactor,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: item.isPeak
                                            ? const Color(0xFF00E5FF)
                                            : Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(5),
                                        border: item.isPeak
                                            ? Border.all(color: Colors.white, width: 1.2)
                                            : null,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Label
                                    Text(
                                      item.label,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: item.isPeak
                                            ? const Color(0xFF00E5FF)
                                            : Colors.white.withValues(alpha: 0.5),
                                        fontSize: 10,
                                        fontWeight: item.isPeak ? FontWeight.w900 : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Footer
            Center(
              child: Text(
                isEn
                    ? 'MEME REWIND • PEAK ANALYSIS'
                    : 'MEME REWIND • KHOẢNH KHẮC ĐỈNH ĐIỂM',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
