import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_icon_registry.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/rewind_data.dart';

class RewindTopSpendingStory extends StatefulWidget {
  final RewindData data;
  final String currency;

  const RewindTopSpendingStory({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  State<RewindTopSpendingStory> createState() => _RewindTopSpendingStoryState();
}

class _RewindTopSpendingStoryState extends State<RewindTopSpendingStory>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
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
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
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
    final topExpenses = widget.data.topExpenses;

    if (topExpenses.isEmpty) {
      return const Center(
        child: Text(
          'No expenses found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final top1 = topExpenses.first;
    final top1CatName = BudgetNameLocalizer.display(
      context,
      top1.category.isNotEmpty ? top1.category : (isEn ? 'Other' : 'Khác'),
    );
    final top1Icon = top1.categoryIconCodePoint != null
        ? AppIconRegistry.fromCodePoint(top1.categoryIconCodePoint!)
        : Icons.receipt_long_rounded;

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
                    color: const Color(0xFFFFD600),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BIGGEST BILL',
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
                  isEn ? 'TOP TRANSACTIONS' : 'GIAO DỊCH NỔI BẬT',
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
              isEn ? 'THE HEAVYWEIGHT\nPURCHASE.' : 'KHOẢN CHI LỚN NHẤT\nTRONG KỲ.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 20),

            // Digital Receipt Hero Card with Scale Animation
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD600).withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(top1Icon, color: const Color(0xFFFFD600), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              top1CatName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(top1.createdAt),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppCurrencyFormatter.formatFromVnd(
                        amountVnd: top1.amount,
                        currency: widget.currency,
                      ),
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (top1.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${top1.note}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (top1.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 110,
                          width: double.infinity,
                          child: CachedNetworkImage(
                            imageUrl: top1.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Runner-Up Top Expenses with Slide Animation
            SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (isEn ? 'OTHER TOP SPENDS' : 'CÁC KHOẢN CHI LỚN KHÁC').toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(
                      topExpenses.length > 1 ? (topExpenses.length - 1).clamp(0, 3) : 0,
                      (index) {
                        final exp = topExpenses[index + 1];
                        final catName = BudgetNameLocalizer.display(
                          context,
                          exp.category.isNotEmpty ? exp.category : (isEn ? 'Other' : 'Khác'),
                        );
                        final icon = exp.categoryIconCodePoint != null
                            ? AppIconRegistry.fromCodePoint(exp.categoryIconCodePoint!)
                            : Icons.receipt_rounded;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
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
                              Icon(icon, color: Colors.white70, size: 18),
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(exp.createdAt),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppCurrencyFormatter.formatFromVnd(
                                  amountVnd: exp.amount,
                                  currency: widget.currency,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Footer
            Center(
              child: Text(
                isEn
                    ? 'MEME REWIND • BIGGEST EXPENSES'
                    : 'MEME REWIND • GIAO DỊCH TIÊU BIỂU',
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
