import 'package:flutter/material.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../models/rewind_data.dart';

class RewindHighlightStory extends StatefulWidget {
  final RewindData data;

  const RewindHighlightStory({
    super.key,
    required this.data,
  });

  @override
  State<RewindHighlightStory> createState() => _RewindHighlightStoryState();
}

class _RewindHighlightStoryState extends State<RewindHighlightStory>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final highlight = widget.data.highlight;
    if (highlight == null) return const SizedBox.shrink();

    String title;
    String description;
    switch (highlight.type) {
      case RewindHighlightType.dominantCategory:
        final catDisplay = BudgetNameLocalizer.display(
          context,
          highlight.categoryName ?? '',
        );
        title = l10n.rewindHighlightDominantTitle;
        description = l10n.rewindHighlightDominantDesc(
          catDisplay,
          highlight.percentStr ?? '',
        );
        break;
      case RewindHighlightType.peakDay:
        title = l10n.rewindHighlightPeakDayTitle;
        description = l10n.rewindHighlightPeakDayDesc(
          highlight.dateStr ?? '',
          highlight.percentStr ?? '',
        );
        break;
      case RewindHighlightType.biggestExpense:
        final catDisplay = BudgetNameLocalizer.display(
          context,
          highlight.categoryName ?? '',
        );
        title = l10n.rewindHighlightBiggestExpenseTitle;
        description = l10n.rewindHighlightBiggestExpenseDesc(catDisplay);
        break;
    }

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
                    color: const Color(0xFFFF4081),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FINANCIAL PERSONA',
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
                  isEn ? 'YOUR MONEY IDENTITY' : 'ĐỊNH DANH TÀI CHÍNH',
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
              isEn ? 'THE ARCHETYPE\nOF YOUR SPENDING.' : 'CÁ TÍNH ĐẶC TRƯNG\nTRONG KỲ NÀY.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 24),

            // Collectible Tarot Card Hero with Pulsing Animation
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFFF4081).withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4081).withValues(alpha: 0.16),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Persona Emoji Avatar with Pulse
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4081).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF4081).withValues(alpha: 0.6),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4081).withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            highlight.emoji,
                            style: const TextStyle(fontSize: 46),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Description
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Trait Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Text(
                            '#PersonalStyle',
                            style: TextStyle(
                              color: Color(0xFFFF80AB),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Text(
                            '#MemeRewind',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
                    ? 'MEME REWIND • SPENDING IDENTITY'
                    : 'MEME REWIND • BẢN SẮC TÀI CHÍNH',
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
