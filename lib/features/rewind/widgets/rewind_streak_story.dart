import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/rewind_data.dart';

class RewindStreakStory extends StatefulWidget {
  final RewindData data;

  const RewindStreakStory({
    super.key,
    required this.data,
  });

  @override
  State<RewindStreakStory> createState() => _RewindStreakStoryState();
}

class _RewindStreakStoryState extends State<RewindStreakStory>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final streak = widget.data.streakDays;
    final activeDateKeys = widget.data.activeDateKeys;
    final activeDaysCount = activeDateKeys.length;

    // Generate recent 7 days timeline
    final today = DateTime.now();
    final recent7Days = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      return {
        'date': d,
        'hasLogged': activeDateKeys.contains(key),
        'label': _formatDayLabel(d, isEn),
      };
    });

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 68, 20, 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak Tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'STREAK & HABIT',
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
                  isEn ? 'FINANCIAL DISCIPLINE' : 'KỶ LUẬT TÀI CHÍNH',
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
              isEn
                  ? 'CONSISTENCY IS\nYOUR SUPERPOWER.'
                  : 'SỨC MẠNH CỦA\nSỰ KIÊN TRÌ.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 24),

            // Hero Circular Streak Showcase (Hình Tròn Hoàn Hảo Theo Yêu Cầu)
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF6D00).withValues(alpha: 0.35),
                          const Color(0xFFFF3D00).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.5),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6D00).withValues(alpha: 0.28),
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFF9E80),
                            size: 42,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$streak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (isEn ? 'DAYS STREAK' : 'NGÀY LIÊN TỤC').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFFFAB91),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Rhythm Punchcard with Slide Animation
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                          (isEn ? 'LOGGING RHYTHM' : 'NHỊP ĐỘ GHI CHÉP').toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isEn ? '$activeDaysCount Active Days' : '$activeDaysCount Ngày hoạt động',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grid of recent 7 days
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: recent7Days.map((item) {
                        final hasData = item['hasLogged'] as bool;
                        final dayLabel = item['label'] as String;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: hasData
                                    ? const Color(0xFFFF6D00)
                                    : Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                boxShadow: hasData
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Icon(
                                  hasData ? Icons.check_rounded : Icons.remove_rounded,
                                  color: hasData
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dayLabel,
                              style: TextStyle(
                                color: hasData
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),

                    const Divider(color: Colors.white12, height: 28),

                    // Quote
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: Color(0xFFFF9E80),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEn
                                ? 'Consistency in tracking is the foundation of financial control.'
                                : 'Mỗi lần ghi chép là một bước tiến gần hơn đến tự do tài chính.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Footer
            Center(
              child: Text(
                isEn
                    ? 'MEME REWIND • HABIT PULSE'
                    : 'MEME REWIND • NHỊP SỐNG KỶ LUẬT',
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
