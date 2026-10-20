import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../models/rewind_data.dart';
import '../models/rewind_period.dart';
import '../models/rewind_story.dart';
import '../services/rewind_aggregation_service.dart';
import '../widgets/rewind_biggest_day_story.dart';
import '../widgets/rewind_category_story.dart';
import '../widgets/rewind_comparison_story.dart';
import '../widgets/rewind_empty_story.dart';
import '../widgets/rewind_highlight_story.dart';
import '../widgets/rewind_moments_story.dart';
import '../widgets/rewind_overview_story.dart';
import '../widgets/rewind_period_picker_sheet.dart';
import '../widgets/rewind_progress_bar.dart';
import '../widgets/rewind_streak_story.dart';
import '../widgets/rewind_summary_story.dart';
import '../widgets/rewind_top_spending_story.dart';

class RewindScreen extends StatefulWidget {
  final RewindPeriod? initialPeriod;

  const RewindScreen({
    super.key,
    this.initialPeriod,
  });

  @override
  State<RewindScreen> createState() => _RewindScreenState();
}

class _RewindScreenState extends State<RewindScreen>
    with SingleTickerProviderStateMixin {
  late RewindPeriod _currentPeriod;
  RewindData? _rewindData;
  List<RewindStory> _stories = [];

  int _currentIndex = 0;
  late AnimationController _progressController;
  bool _isPaused = false;
  DateTime? _touchDownTime;
  bool _isHolding = false;
  bool _isZoomedIn = false;
  bool _isLoading = true;
  HomeController? _homeController;

  @override
  void initState() {
    super.initState();
    _currentPeriod = widget.initialPeriod ?? RewindPeriod.thisWeek();

    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener(_onProgressStatusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newHome = context.read<HomeController>();
    if (_homeController != newHome) {
      _homeController?.removeListener(_onHomeUpdated);
      _homeController = newHome;
      _homeController?.addListener(_onHomeUpdated);
    }

    final uid = context.read<AuthController>().user?.uid;
    if (uid != null &&
        _homeController != null &&
        _homeController!.transactions.isEmpty &&
        !_homeController!.isLoading) {
      _homeController!.load(uid);
    }

    _loadDataForPeriod(_currentPeriod);
  }

  void _onHomeUpdated() {
    if (!mounted) return;
    _loadDataForPeriod(_currentPeriod);
  }

  void _loadDataForPeriod(RewindPeriod period) {
    if (!mounted) return;
    final home = _homeController ?? context.read<HomeController>();

    // If home is currently loading and hasn't loaded any transactions yet, keep loading spinner
    if (home.isLoading && home.transactions.isEmpty) {
      if (!_isLoading) {
        setState(() {
          _isLoading = true;
        });
      }
      return;
    }

    final allTransactions = home.transactions;
    final currentStreak = home.profile?.currentStreak ?? 0;

    final data = RewindAggregationService.aggregate(
      allTransactions: allTransactions,
      period: period,
      currentStreak: currentStreak,
    );

    final stories = RewindAggregationService.buildStories(data);

    final bool isDifferentPeriod = _currentPeriod != period;
    final bool hadNoStories = _stories.isEmpty;
    final bool transitioningFromEmpty = _stories.isNotEmpty &&
        _stories.first.type == RewindStoryType.empty &&
        stories.first.type != RewindStoryType.empty;

    setState(() {
      _currentPeriod = period;
      _rewindData = data;
      _stories = stories;
      _isLoading = false;
      if (isDifferentPeriod || hadNoStories || transitioningFromEmpty) {
        _currentIndex = 0;
      }
    });

    if (isDifferentPeriod || hadNoStories || transitioningFromEmpty) {
      _startCurrentStory();
    }
  }

  void _startCurrentStory() {
    if (_stories.isEmpty) return;
    _progressController.stop();
    _progressController.duration = _stories[_currentIndex].duration;
    _progressController.reset();
    _progressController.forward();
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_isZoomedIn) return;
      if (_currentIndex < _stories.length - 1) {
        _nextStory();
      }
      // If on the last story (Summary), keep progress at 100% so user can inspect and share
    }
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      _isZoomedIn = false;
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex++;
      });
      _startCurrentStory();
    }
  }

  void _previousStory() {
    _isZoomedIn = false;
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex--;
      });
      _startCurrentStory();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _pause() {
    _isPaused = true;
    _progressController.stop();
    if (mounted) setState(() {});
  }

  void _resume() {
    if (_isZoomedIn) return; // NEVER resume if zoomed into a photo!
    if (_isPaused) {
      _isPaused = false;
      _progressController.forward();
      if (mounted) setState(() {});
    }
  }

  void _openPeriodPicker() {
    _pause();
    RewindPeriodPickerSheet.show(
      context: context,
      currentPeriod: _currentPeriod,
      onPeriodSelected: (newPeriod) {
        _loadDataForPeriod(newPeriod);
        _resume();
      },
    ).then((_) {
      if (_isPaused) _resume();
    });
  }

  @override
  void dispose() {
    _homeController?.removeListener(_onHomeUpdated);
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted || _isLoading || _stories.isEmpty || _rewindData == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
            strokeWidth: 3,
          ),
        ),
      );
    }

    final currentStory = _stories[_currentIndex];
    final currency = context.watch<ProfileController>().currency;
    final userName = context.watch<AuthController>().user?.displayName ??
        context.watch<HomeController>().profile?.name ??
        'User';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTapDown: (details) {
            if (_isZoomedIn) return;
            _touchDownTime = DateTime.now();
            _isHolding = false;
            _pause();
          },
          onLongPressStart: (_) {
            if (_isZoomedIn) return;
            _isHolding = true;
            _pause();
          },
          onLongPressEnd: (_) {
            if (_isZoomedIn) return;
            _isHolding = true;
            _resume();
          },
          onTapUp: (details) {
            if (_isZoomedIn) return;
            final now = DateTime.now();
            final touchDuration = _touchDownTime != null
                ? now.difference(_touchDownTime!).inMilliseconds
                : 0;

            if (!_isHolding && touchDuration < 280) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tapX = details.globalPosition.dx;

              if (tapX < screenWidth * 0.35) {
                _previousStory();
              } else {
                _nextStory();
              }
            } else {
              _resume();
            }
          },
          onTapCancel: () {
            if (_isZoomedIn) return;
            _resume();
          },
          onHorizontalDragEnd: (details) {
            if (_isZoomedIn) return;
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -300) {
              _nextStory();
            } else if (velocity > 300) {
              _previousStory();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentStory.backgroundGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // DYNAMIC AMBIENT GLOW AURA IN BACKGROUND
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _StoryAtmosphericPainter(
                          storyType: currentStory.type,
                        ),
                      ),
                    ),
                  ),

                  // STORY CONTENT (Scrolls naturally under floating transparent header)
                  Positioned.fill(
                    child: _buildStoryContent(
                      story: currentStory,
                      data: _rewindData!,
                      currency: currency,
                      userName: userName,
                    ),
                  ),

                  // TOP NAVIGATION BAR (Progress + Period Selector + Close) - Floating Frosted Glass
                  Positioned(
                    top: 8,
                    left: 14,
                    right: 14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress Bar
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return RewindProgressBar(
                              totalSegments: _stories.length,
                              currentIndex: _currentIndex,
                              currentProgress: _progressController.value,
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Header Controls Row
                        Row(
                          children: [
                            // Period Selector Capsule Button
                            InkWell(
                              onTap: _openPeriodPicker,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentPeriod.getTitle(context),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),

                            // Close Button 'X'
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryContent({
    required RewindStory story,
    required RewindData data,
    required String currency,
    required String userName,
  }) {
    final periodKey = '${data.period.type.name}_${data.period.startDateTime.millisecondsSinceEpoch}';

    switch (story.type) {
      case RewindStoryType.overview:
        return RewindOverviewStory(
          key: ValueKey('overview_${story.id}_${periodKey}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.categories:
        return RewindCategoryStory(
          key: ValueKey('cat_${story.id}_${periodKey}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.streak:
        return RewindStreakStory(
          key: ValueKey('streak_${story.id}_${periodKey}_$_currentIndex'),
          data: data,
        );
      case RewindStoryType.topExpenses:
        return RewindTopSpendingStory(
          key: ValueKey('top_${story.id}_${periodKey}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.biggestDay:
        return RewindBiggestDayStory(
          key: ValueKey('big_${story.id}_${periodKey}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.moments:
        return RewindMomentsStory(
          key: ValueKey('moments_${story.id}_${periodKey}_$_currentIndex'),
          data: data,
          currency: currency,
          onZoomChanged: (isZoomed) {
            setState(() => _isZoomedIn = isZoomed);
            if (isZoomed) {
              _pause();
            } else {
              _resume();
            }
          },
        );
      case RewindStoryType.highlight:
        return RewindHighlightStory(
          key: ValueKey('highlight_${story.id}_${periodKey}_$_currentIndex'),
          data: data,
        );
      case RewindStoryType.comparison:
        return RewindComparisonStory(
          key: ValueKey('comparison_${story.id}_${periodKey}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.summary:
        return RewindSummaryStory(
          key: ValueKey('summary_${story.id}_${periodKey}_$_currentIndex'),
          data: data,
          currency: currency,
          userName: userName,
        );
      case RewindStoryType.empty:
        return RewindEmptyStory(
          key: ValueKey('empty_${story.id}_${periodKey}_$_currentIndex'),
          period: data.period,
          onPickPeriod: _openPeriodPicker,
        );
    }
  }
}

/// Atmospheric ambient lighting painter that paints subtle luminous glow blobs
/// matching each story type behind the content to give Spotify Wrapped vibrancy.
class _StoryAtmosphericPainter extends CustomPainter {
  final RewindStoryType storyType;

  const _StoryAtmosphericPainter({required this.storyType});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Color primaryGlow;
    Color secondaryGlow;
    Offset primaryCenter;
    Offset secondaryCenter;
    double primaryRadius;
    double secondaryRadius;

    switch (storyType) {
      case RewindStoryType.overview:
        primaryGlow = const Color(0xFF8B5CF6).withValues(alpha: 0.22);
        secondaryGlow = const Color(0xFFEC4899).withValues(alpha: 0.16);
        primaryCenter = Offset(w * 0.8, h * 0.22);
        secondaryCenter = Offset(w * 0.15, h * 0.75);
        primaryRadius = w * 0.7;
        secondaryRadius = w * 0.6;
        break;
      case RewindStoryType.categories:
        primaryGlow = const Color(0xFF06B6D4).withValues(alpha: 0.22);
        secondaryGlow = const Color(0xFF3B82F6).withValues(alpha: 0.16);
        primaryCenter = Offset(w * 0.2, h * 0.25);
        secondaryCenter = Offset(w * 0.85, h * 0.70);
        primaryRadius = w * 0.75;
        secondaryRadius = w * 0.55;
        break;
      case RewindStoryType.streak:
        primaryGlow = const Color(0xFFFF5722).withValues(alpha: 0.26);
        secondaryGlow = const Color(0xFFF59E0B).withValues(alpha: 0.18);
        primaryCenter = Offset(w * 0.5, h * 0.35);
        secondaryCenter = Offset(w * 0.5, h * 0.85);
        primaryRadius = w * 0.8;
        secondaryRadius = w * 0.65;
        break;
      case RewindStoryType.topExpenses:
        primaryGlow = const Color(0xFFA855F7).withValues(alpha: 0.24);
        secondaryGlow = const Color(0xFF6366F1).withValues(alpha: 0.16);
        primaryCenter = Offset(w * 0.85, h * 0.3);
        secondaryCenter = Offset(w * 0.1, h * 0.78);
        primaryRadius = w * 0.72;
        secondaryRadius = w * 0.58;
        break;
      case RewindStoryType.biggestDay:
        primaryGlow = const Color(0xFF10B981).withValues(alpha: 0.24);
        secondaryGlow = const Color(0xFF059669).withValues(alpha: 0.18);
        primaryCenter = Offset(w * 0.3, h * 0.32);
        secondaryCenter = Offset(w * 0.8, h * 0.75);
        primaryRadius = w * 0.75;
        secondaryRadius = w * 0.6;
        break;
      case RewindStoryType.moments:
        primaryGlow = const Color(0xFF8B5CF6).withValues(alpha: 0.22);
        secondaryGlow = const Color(0xFF38BDF8).withValues(alpha: 0.16);
        primaryCenter = Offset(w * 0.7, h * 0.3);
        secondaryCenter = Offset(w * 0.2, h * 0.75);
        primaryRadius = w * 0.75;
        secondaryRadius = w * 0.6;
        break;
      case RewindStoryType.highlight:
        primaryGlow = const Color(0xFFD946EF).withValues(alpha: 0.25);
        secondaryGlow = const Color(0xFFF43F5E).withValues(alpha: 0.18);
        primaryCenter = Offset(w * 0.5, h * 0.4);
        secondaryCenter = Offset(w * 0.2, h * 0.82);
        primaryRadius = w * 0.8;
        secondaryRadius = w * 0.6;
        break;
      case RewindStoryType.comparison:
        primaryGlow = const Color(0xFF3B82F6).withValues(alpha: 0.24);
        secondaryGlow = const Color(0xFF06B6D4).withValues(alpha: 0.16);
        primaryCenter = Offset(w * 0.75, h * 0.28);
        secondaryCenter = Offset(w * 0.25, h * 0.72);
        primaryRadius = w * 0.7;
        secondaryRadius = w * 0.6;
        break;
      case RewindStoryType.summary:
        primaryGlow = const Color(0xFF6366F1).withValues(alpha: 0.22);
        secondaryGlow = const Color(0xFFF59E0B).withValues(alpha: 0.14);
        primaryCenter = Offset(w * 0.5, h * 0.2);
        secondaryCenter = Offset(w * 0.5, h * 0.85);
        primaryRadius = w * 0.75;
        secondaryRadius = w * 0.6;
        break;
      case RewindStoryType.empty:
        primaryGlow = const Color(0xFF8B5CF6).withValues(alpha: 0.12);
        secondaryGlow = const Color(0xFF3B82F6).withValues(alpha: 0.08);
        primaryCenter = Offset(w * 0.5, h * 0.5);
        secondaryCenter = Offset(w * 0.5, h * 0.8);
        primaryRadius = w * 0.6;
        secondaryRadius = w * 0.5;
        break;
    }

    // Paint Primary Glow
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryGlow,
          primaryGlow.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: primaryCenter, radius: primaryRadius));
    canvas.drawCircle(primaryCenter, primaryRadius, paint1);

    // Paint Secondary Glow
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          secondaryGlow,
          secondaryGlow.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: secondaryCenter, radius: secondaryRadius));
    canvas.drawCircle(secondaryCenter, secondaryRadius, paint2);
  }

  @override
  bool shouldRepaint(covariant _StoryAtmosphericPainter oldDelegate) {
    return oldDelegate.storyType != storyType;
  }
}

