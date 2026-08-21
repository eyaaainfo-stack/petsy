// Test bassit ("smoke test") l'app Petsy - ychekek belli el app
// t3amar bla crash (EasyLocalization + MyApp), MCH el counter app
// el default (elli kan mawjoud houni 9bal, testa esm 3adad "0"/"1"
// elli ma3andouch 3ala9a b'Petsy).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:frontend/app.dart';

void main() {
  testWidgets('Petsy app launches without crashing', (WidgetTester tester) async {
    // 🔵 EasyLocalization lezmha init 9bal ma tetsta3mel (nafs mant9
    // main.dart) - bla ha, kol '.tr()' fel app tar7am exception.
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('fr'),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // el app 3amaret bla crash - fama MaterialApp wa7ed wa9ef bnajjah
    // (el écran el loula houwa LanguageView, mel routing fel app.dart).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}