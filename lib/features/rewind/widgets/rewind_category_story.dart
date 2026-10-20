import 'package:flutter/material.dart';

import '../../../core/constants/app_icon_registry.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/rewind_data.dart';

class RewindCategoryStory extends StatefulWidget {
  final RewindData data;
  final String currency;

  const RewindCategoryStory({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  State<RewindCategoryStory> createState() => _RewindCategoryStoryState();
}

class _RewindCategoryStoryState extends State<RewindCategoryStory>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.95, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF00E5FF);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF00E5FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final categories = widget.data.categories;

    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'No category data available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final top1 = categories.first;
    final top1Color = _parseHexColor(top1.colorHex);
    final top1Name = BudgetNameLocalizer.display(context, top1.name);
    final top1Icon = top1.iconCodePoint != null
        ? AppIconRegistry.fromCodePoint(top1.iconCodePoint!)
        : Icons.category_rounded;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 68, 20, 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Habit Tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TOP HABIT',
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
                  isEn ? 'SPENDING BREAKDOWN' : 'PHÂN BỔ DANH MỤC',
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
              isEn ? 'YOUR BIGGEST\nPASSION.' : 'NƠI TIỀN CỦA BẠN\nĐỔ VỀ NHIỀU NHẤT.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 20),

            // Hero Category Card with Scale & Glow
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: top1Color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: top1Color.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: top1Color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: top1Color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(top1Icon, color: top1Color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#1 ',
                                style: TextStyle(
                                  color: top1Color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  top1Name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppCurrencyFormatter.formatFromVnd(
                              amountVnd: top1.amount,
                              currency: widget.currency,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: top1Color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${top1.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: top1Color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Segmented Proportional Bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  height: 10,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: categories.map((cat) {
                      final color = _parseHexColor(cat.colorHex);
                      final flex = (cat.percentage * 10 * _progressAnimation.value).toInt().clamp(1, 1000);
                      return Expanded(
                        flex: flex,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: color,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // Runner-Up Categories List with Staggered Slide
            SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: List.generate(
                  categories.length > 1 ? (categories.length - 1).clamp(0, 4) : 0,
                  (index) {
                    final cat = categories[index + 1];
                    final catColor = _parseHexColor(cat.colorHex);
                    final catName = BudgetNameLocalizer.display(context, cat.name);
                    final catIcon = cat.iconCodePoint != null
                        ? AppIconRegistry.fromCodePoint(cat.iconCodePoint!)
                        : Icons.category_rounded;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '#${index + 2}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(catIcon, color: catColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  catName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppCurrencyFormatter.formatFromVnd(
                                    amountVnd: cat.amount,
                                    currency: widget.currency,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${cat.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Footer
            Center(
              child: Text(
                isEn
                    ? 'MEME REWIND • CATEGORY DYNAMICS'
                    : 'MEME REWIND • PHÂN TÍCH DANH MỤC',
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
