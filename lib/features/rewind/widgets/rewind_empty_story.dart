import 'package:flutter/material.dart';

import '../../../core/extensions/localization_extension.dart';
import '../models/rewind_period.dart';

class RewindEmptyStory extends StatelessWidget {
  final RewindPeriod period;
  final VoidCallback onPickPeriod;

  const RewindEmptyStory({
    super.key,
    required this.period,
    required this.onPickPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.rewindEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.rewindEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onPickPeriod,
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(
                l10n.rewindSelectPeriod,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCCFF00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
