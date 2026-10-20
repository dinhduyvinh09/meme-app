import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/features/home/widgets/streak_card.dart';
import 'package:meme_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('StreakCard renders mascot, streak count and handles tap',
      (tester) async {
    bool startTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: StreakCard(
            streak: 7,
            lastActiveDate: null, // pending today
            onStartTap: () {
              startTapped = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify streak count rendered
    expect(find.textContaining('7+'), findsOneWidget);

    // Verify mascot asset image exists
    final imageFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName.contains('mascot'),
    );
    expect(imageFinder, findsWidgets);

    // Verify action button tap triggers callback
    final actionButton = find.text('Thắp lửa');
    expect(actionButton, findsOneWidget);

    await tester.tap(actionButton);
    expect(startTapped, isTrue);
  });

  testWidgets(
      'StreakCard renders completed state with Details button in English',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: StreakCard(
            streak: 14,
            lastActiveDate: DateTime.now(), // completed today
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('14+'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
  });
}
