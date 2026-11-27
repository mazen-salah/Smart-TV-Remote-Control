import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/blocs/locale/locale_cubit.dart';
import 'package:remote/core/services/locale_storage.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/language_menu_button.dart';

class _MockLocaleStorage extends Mock implements LocaleStorage {}

void main() {
  late _MockLocaleStorage storage;
  late LocaleCubit cubit;

  setUp(() {
    storage = _MockLocaleStorage();
    when(() => storage.load()).thenReturn(null);
    when(() => storage.save(any())).thenAnswer((_) async {});
    cubit = LocaleCubit(storage);
  });

  tearDown(() => cubit.close());

  Future<void> pumpButton(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<LocaleCubit>.value(
        value: cubit,
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: LanguageMenuButton())),
        ),
      ),
    );
  }

  testWidgets('menu is labelled in the active language', (tester) async {
    await pumpButton(tester);

    expect(find.byTooltip('Язык'), findsOneWidget);
  });

  testWidgets('picking Russian switches and persists the language', (
    tester,
  ) async {
    await pumpButton(tester);

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(cubit.state, const Locale('ru'));
    verify(() => storage.save(const Locale('ru'))).called(1);
  });

  testWidgets('"System default" clears the override', (tester) async {
    when(() => storage.load()).thenReturn(const Locale('ru'));
    await cubit.close();
    cubit = LocaleCubit(storage);
    await pumpButton(tester);

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Как в системе'));
    await tester.pumpAndSettle();

    expect(cubit.state, isNull);
    verify(() => storage.save(null)).called(1);
  });
}
