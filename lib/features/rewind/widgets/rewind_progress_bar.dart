import 'package:flutter/material.dart';

class RewindProgressBar extends StatelessWidget {
  final int totalSegments;
  final int currentIndex;
  final double currentProgress; // 0.0 to 1.0

  const RewindProgressBar({
    super.key,
    required this.totalSegments,
    required this.currentIndex,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSegments <= 0) return const SizedBox.shrink();

    return Row(
      children: List.generate(totalSegments, (index) {
        double segmentProgress = 0.0;
        final bool isCurrent = index == currentIndex;
        if (index < currentIndex) {
          segmentProgress = 1.0;
        } else if (isCurrent) {
          segmentProgress = currentProgress.clamp(0.0, 1.0);
        } else {
          segmentProgress = 0.0;
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            height: 3.5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: segmentProgress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

