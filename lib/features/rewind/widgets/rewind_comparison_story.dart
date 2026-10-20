import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/rewind_data.dart';

class RewindComparisonStory extends StatefulWidget {
  final RewindData data;
  final String currency;

  const RewindComparisonStory({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  State<RewindComparisonStory> createState() => _RewindComparisonStoryState();
}

class _RewindComparisonStoryState extends State<RewindComparisonStory>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _topSlideAnimation;
  late Animation<Offset> _bottomSlideAnimation;

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

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _topSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _bottomSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final diffPct = widget.data.expenseChangePercent;
    final currentExp = widget.data.totalExpense;
    final prevExp = widget.data.prevTotalExpense;
    final absDiff = (currentExp - prevExp).abs();
    final isDecrease = diffPct != null && diffPct < 0;
    final isIncrease = diffPct != null && diffPct > 0;

    final Color trendColor = isDecrease
        ? const Color(0xFF00E676)
        : isIncrease
            ? const Color(0xFFFF5252)
            : const Color(0xFF00E5FF);

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
                    color: const Color(0xFF2979FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PERIOD SHOWDOWN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isEn ? 'HEAD-TO-HEAD' : 'SO SÁNH ĐỐI CHIẾU',
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
              isEn ? 'HOW YOUR HABITS\nEVOLVED.' : 'BƯỚC TIẾN SO VỚI\nKỲ TRƯỚC.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 20),

            // Delta Callout Pill with Scale Animation
            if (diffPct != null)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: trendColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: trendColor.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDecrease
                            ? Icons.trending_down_rounded
                            : isIncrease
                                ? Icons.trending_up_rounded
                                : Icons.trending_flat_rounded,
                        color: trendColor,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${diffPct > 0 ? '+' : ''}${diffPct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: trendColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              isDecrease
                                  ? (isEn ? 'Spent less than previous period' : 'Chi tiêu ít hơn kỳ trước')
                                  : isIncrease
                                      ? (isEn ? 'Spent more than previous period' : 'Chi tiêu nhiều hơn kỳ trước')
                                      : (isEn ? 'Spending remained steady' : 'Chi tiêu tương đương kỳ trước'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Dual Showdown Cards
            // 1. Current Period Card (Slide from top)
            SlideTransition(
              position: _topSlideAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (isEn ? 'CURRENT PERIOD' : 'KỲ NÀY').toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF82B1FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Icon(Icons.bolt_rounded, color: Color(0xFF82B1FF), size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppCurrencyFormatter.formatFromVnd(
                        amountVnd: currentExp,
                        currency: widget.currency,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.data.totalTransactions} ${isEn ? 'transactions' : 'giao dịch'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. Previous Period Card (Slide from bottom)
            SlideTransition(
              position: _bottomSlideAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (isEn ? 'PREVIOUS PERIOD' : 'KỲ TRƯỚC').toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Icon(
                          Icons.history_rounded,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppCurrencyFormatter.formatFromVnd(
                        amountVnd: prevExp,
                        currency: widget.currency,
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isEn ? 'Difference' : 'Chênh lệch'}: ${AppCurrencyFormatter.formatFromVnd(amountVnd: absDiff, currency: widget.currency)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                isEn
                    ? 'MEME REWIND • COMPARISON SNAPSHOT'
                    : 'MEME REWIND • BỨC TRANH ĐỐI CHIẾU',
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
