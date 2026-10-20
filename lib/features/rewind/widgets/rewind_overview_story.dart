import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/rewind_data.dart';

class RewindOverviewStory extends StatefulWidget {
  final RewindData data;
  final String currency;

  const RewindOverviewStory({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  State<RewindOverviewStory> createState() => _RewindOverviewStoryState();
}

class _RewindOverviewStoryState extends State<RewindOverviewStory>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _numberAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _numberAnimation = Tween<double>(
      begin: 0.0,
      end: widget.data.totalExpense,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutQuart),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final currency = widget.currency;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final netSavings = data.totalIncome - data.totalExpense;
    final daysInPeriod = (data.period.endDateTime.difference(data.period.startDateTime).inDays + 1).clamp(1, 365);
    final dailyAvg = data.totalExpense / daysInPeriod;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 68, 20, 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editorial Magazine Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFF00),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FINANCIAL RECAP',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.period.getTitle(context).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Punchy Editorial Headline
              Text(
                isEn ? "YOUR MONEY\nAT A GLANCE." : "DÒNG TIỀN CỦA BẠN\nTRONG KỲ NÀY.",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 20),

              // Hero Stat Box - Clean Bold Poster Block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF5252),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (isEn ? 'TOTAL EXPENSE' : 'TỔNG CHI TIÊU').toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _numberAnimation,
                      builder: (context, child) {
                        return Text(
                          AppCurrencyFormatter.formatFromVnd(
                            amountVnd: _numberAnimation.value,
                            currency: currency,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEn
                          ? 'Spread across ${data.totalTransactions} transactions'
                          : 'Phân bổ qua ${data.totalTransactions} giao dịch ghi chép',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Dual Information Grid (Income & Daily Average)
              Row(
                children: [
                  // Income Block
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
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
                              Expanded(
                                child: Text(
                                  (isEn ? 'INCOME' : 'TỔNG THU').toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_downward_rounded,
                                color: Color(0xFF00E676),
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppCurrencyFormatter.formatFromVnd(
                              amountVnd: data.totalIncome,
                              currency: currency,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Daily Avg Block
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
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
                              Expanded(
                                child: Text(
                                  (isEn ? 'DAILY AVG' : 'TRUNG BÌNH/NGÀY').toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB300),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.speed_rounded,
                                color: Color(0xFFFFB300),
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppCurrencyFormatter.formatFromVnd(
                              amountVnd: dailyAvg,
                              currency: currency,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Net Cashflow / Savings Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: netSavings >= 0
                      ? const Color(0xFF00E676).withValues(alpha: 0.1)
                      : const Color(0xFFFF5252).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: netSavings >= 0
                        ? const Color(0xFF00E676).withValues(alpha: 0.3)
                        : const Color(0xFFFF5252).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          netSavings >= 0
                              ? Icons.savings_outlined
                              : Icons.account_balance_wallet_outlined,
                          color: netSavings >= 0
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFF5252),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          netSavings >= 0
                              ? (isEn ? 'Net Surplus' : 'Thặng dư ròng')
                              : (isEn ? 'Net Deficit' : 'Thâm hụt ròng'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppCurrencyFormatter.formatFromVnd(
                        amountVnd: netSavings.abs(),
                        currency: currency,
                      ),
                      style: TextStyle(
                        color: netSavings >= 0
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF5252),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Bottom Editorial Tagline
              Center(
                child: Text(
                  isEn
                      ? 'MEME REWIND • YOUR FINANCIAL STORY'
                      : 'MEME REWIND • HÀNH TRÌNH TÀI CHÍNH',
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
      ),
    );
  }
}
