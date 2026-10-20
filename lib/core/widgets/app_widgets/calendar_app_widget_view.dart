import 'dart:typed_data';
import 'package:flutter/material.dart';

class CalendarWidgetData {
  final String monthLabel;
  final int streak;
  final String totalExpenseCompact;
  final int transactionCount;
  final String totalIncomeCompact;
  final int year;
  final int month;
  final Map<int, Uint8List> dayThumbnails; // Kept for backward compatibility
  final Set<int> daysWithSpending; // Days that had transactions
  final Set<int> daysWithPhoto; // Days that had captured photo moments
  final int? today; // Today's day of month
  final bool isDark;
  final String expenseLabel;
  final String txCountLabel;
  final String incomeLabel;
  final List<String> weekdayLabels;

  const CalendarWidgetData({
    required this.monthLabel,
    required this.streak,
    required this.totalExpenseCompact,
    required this.transactionCount,
    required this.totalIncomeCompact,
    required this.year,
    required this.month,
    this.dayThumbnails = const {},
    this.daysWithSpending = const {},
    this.daysWithPhoto = const {},
    this.today,
    this.isDark = true,
    this.expenseLabel = 'Chi tiêu',
    this.txCountLabel = 'Số giao dịch',
    this.incomeLabel = 'Thu vào',
    this.weekdayLabels = const [
      'Th 2',
      'Th 3',
      'Th 4',
      'Th 5',
      'Th 6',
      'Th 7',
      'CN',
    ],
  });
}

class CalendarAppWidgetView extends StatelessWidget {
  final CalendarWidgetData data;

  const CalendarAppWidgetView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = data.isDark;

    final firstDayOfMonth = DateTime(data.year, data.month, 1);
    final lastDayOfMonth = DateTime(data.year, data.month + 1, 0);

    // Monday is 1, Sunday is 7. Empty slots before 1st day = (weekday - 1).
    final emptyLeadingDays = firstDayOfMonth.weekday - 1;
    final totalDays = lastDayOfMonth.day;

    final cells = <int?>[];
    for (int i = 0; i < emptyLeadingDays; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= totalDays; d++) {
      cells.add(d);
    }

    // Dynamic Theme Colors
    // Dynamic Theme Colors (Default Dark Theme for Launcher Widgets)
    final bgColor = isDark ? const Color(0xFF14151A) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE5E9F2);
    final monthTextColor =
        isDark ? Colors.white : const Color(0xFF181922);
    final summaryBgColor =
        isDark ? const Color(0xFF1E2028) : const Color(0xFFF1F4F9);
    final summarySubColor =
        isDark ? const Color(0xFF9EA2B4) : const Color(0xFF74788A);
    final weekdayTextColor =
        isDark ? const Color(0xFF9EA2B4) : const Color(0xFF74788A);

    return MediaQuery(
      data: const MediaQueryData(
        size: Size(370, 380),
        devicePixelRatio: 2.5,
        textScaler: TextScaler.noScaling,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 370,
            height: 380,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header: Month title + Streak Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      data.monthLabel,
                      style: TextStyle(
                        fontFamily: 'ProximaSoft',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: monthTextColor,
                      ),
                    ),

                    // Streak Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${data.streak}',
                            style: const TextStyle(
                              fontFamily: 'ProximaSoft',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Summary Overview Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: summaryBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Expense
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              data.expenseLabel,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: summarySubColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.totalExpenseCompact,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? const Color(0xFFFF5B5B)
                                    : const Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Number of transactions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              data.txCountLabel,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: summarySubColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${data.transactionCount}',
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? const Color(0xFF7DDC86)
                                    : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Income
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              data.incomeLabel,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: summarySubColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.totalIncomeCompact,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? const Color(0xFF59D4C8)
                                    : const Color(0xFF00ACC1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Weekday Row
                Row(
                  children: data.weekdayLabels
                      .map(
                        (w) => Expanded(
                          child: Center(
                            child: Text(
                              w,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: weekdayTextColor,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),

                // 4. Calendar Days Grid
                Expanded(
                  child: _buildDaysGrid(cells, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysGrid(List<int?> cells, bool isDark) {
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final rowCells =
          cells.sublist(i, (i + 7 > cells.length) ? cells.length : i + 7);
      while (rowCells.length < 7) {
        rowCells.add(null);
      }

      rows.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: rowCells.map((day) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _buildDayCell(day, isDark),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildDayCell(int? day, bool isDark) {
    if (day == null) {
      return const SizedBox.shrink();
    }

    final hasPhoto = data.daysWithPhoto.contains(day) ||
        (data.dayThumbnails[day]?.isNotEmpty ?? false);
    final hasSpending = data.daysWithSpending.contains(day);
    final isToday = data.today == day;

    Color cardColor;
    Color borderColor;
    double borderWidth;
    Color numColor;
    Widget? indicatorWidget;

    if (hasPhoto) {
      // 1. Ngày có ảnh khoảnh khắc (Cam ấm Terracotta / Copper nổi bật tách biệt hẳn với nền widget)
      cardColor = isDark ? const Color(0xFF4A2514) : const Color(0xFFFFF0E6);
      borderColor = isToday
          ? const Color(0xFF2979FF)
          : (isDark ? const Color(0xFFFF6A3D) : const Color(0xFFFF6A3D));
      borderWidth = isToday ? 2.2 : 1.5;
      numColor = isDark ? const Color(0xFFFFD4C4) : const Color(0xFFD84315);
      indicatorWidget = Icon(
        Icons.camera_alt_rounded,
        size: 10.5,
        color: isDark ? const Color(0xFFFF7A45) : const Color(0xFFFF5722),
      );
    } else if (hasSpending) {
      // 2. Ngày có chi tiêu (chưa chụp) (Đỏ rượu Crimson nổi bật trên nền tối)
      cardColor = isDark ? const Color(0xFF451724) : const Color(0xFFFFEAEC);
      borderColor = isToday
          ? const Color(0xFF2979FF)
          : (isDark ? const Color(0xFFFF4D6D) : const Color(0xFFFF5252));
      borderWidth = isToday ? 2.2 : 1.5;
      numColor = isDark ? const Color(0xFFFFCCD5) : const Color(0xFFC62828);
      indicatorWidget = Container(
        width: 5.0,
        height: 5.0,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFFF3366) : const Color(0xFFFF1744),
          shape: BoxShape.circle,
        ),
      );
    } else if (isToday) {
      // 3. Hôm nay (chưa có chi tiêu & chưa chụp)
      cardColor = isDark ? const Color(0xFF162744) : const Color(0xFFEEF5FF);
      borderColor = const Color(0xFF2979FF);
      borderWidth = 2.2;
      numColor = isDark ? const Color(0xFF82B1FF) : const Color(0xFF1E88E5);
      indicatorWidget = null;
    } else {
      // 4. Ngày trống (Thẻ màu sáng hơn nền widget 0xFF14151A, có viền rõ để thấy lưới lịch)
      cardColor = isDark ? const Color(0xFF242632) : const Color(0xFFF3F5FA);
      borderColor = isDark
          ? const Color(0xFF35394A)
          : const Color(0xFFE2E6F0);
      borderWidth = 1.0;
      numColor = isDark ? const Color(0xFF9095A8) : const Color(0xFF8A90A2);
      indicatorWidget = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      padding: const EdgeInsets.all(3.5),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              '$day',
              style: TextStyle(
                fontFamily: 'ProximaSoft',
                fontSize: 9.5,
                fontWeight: (hasPhoto || hasSpending || isToday)
                    ? FontWeight.w900
                    : FontWeight.w700,
                color: numColor,
                height: 1.0,
              ),
            ),
          ),
          if (indicatorWidget != null)
            Align(
              alignment: Alignment.bottomRight,
              child: indicatorWidget,
            ),
        ],
      ),
    );
  }
}
