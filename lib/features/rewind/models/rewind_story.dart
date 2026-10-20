import 'package:flutter/material.dart';

enum RewindStoryType {
  overview,
  categories,
  streak,
  topExpenses,
  biggestDay,
  moments,
  highlight,
  comparison,
  summary,
  empty,
}

class RewindStory {
  final String id;
  final RewindStoryType type;
  final Duration duration;
  final List<Color> backgroundGradient;

  const RewindStory({
    required this.id,
    required this.type,
    this.duration = const Duration(milliseconds: 5000),
    required this.backgroundGradient,
  });

  static const defaultGradient = [
    Color(0xFF0F172A),
    Color(0xFF020617),
  ];

  static const overviewGradient = [
    Color(0xFF261047),
    Color(0xFF130726),
    Color(0xFF080212),
  ];

  static const categoryGradient = [
    Color(0xFF00384D),
    Color(0xFF011C29),
    Color(0xFF000B12),
  ];

  static const streakGradient = [
    Color(0xFF4A1500),
    Color(0xFF240800),
    Color(0xFF0D0200),
  ];

  static const topExpensesGradient = [
    Color(0xFF380754),
    Color(0xFF1A022B),
    Color(0xFF0A0012),
  ];

  static const biggestDayGradient = [
    Color(0xFF003D29),
    Color(0xFF002117),
    Color(0xFF000D09),
  ];

  static const momentsGradient = [
    Color(0xFF160E36),
    Color(0xFF0C071F),
    Color(0xFF05020D),
  ];

  static const highlightGradient = [
    Color(0xFF4A0033),
    Color(0xFF240019),
    Color(0xFF0D0009),
  ];

  static const comparisonGradient = [
    Color(0xFF0C2352),
    Color(0xFF05112B),
    Color(0xFF020714),
  ];

  static const summaryGradient = [
    Color(0xFF22164A),
    Color(0xFF110B29),
    Color(0xFF070412),
  ];
}
