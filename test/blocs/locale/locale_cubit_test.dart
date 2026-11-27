import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote/blocs/locale/locale_cubit.dart';
import 'package:remote/core/services/locale_storage.dart';

class _MockLocaleStorage extends Mock implements LocaleStorage {}

void main() {
  late _MockLocaleStorage storage;

  setUp(() {
    storage = _MockLocaleStorage();
    when(() => storage.load()).thenReturn(null);
    when(() => storage.save(any())).thenAnswer((_) async {});
  });

  group('LocaleCubit', () {
    test('starts from the stored language', () {
      when(() => storage.load()).thenReturn(const Locale('ru'));

      expect(LocaleCubit(storage).state, const Locale('ru'));
    });

    blocTest<LocaleCubit, Locale?>(
      'select: emits the language and persists it',
      build: () => LocaleCubit(storage),
      act: (cubit) => cubit.select(const Locale('ru')),
      expect: () => [const Locale('ru')],
      verify: (_) => verify(() => storage.save(const Locale('ru'))).called(1),
    );

    blocTest<LocaleCubit, Locale?>(
      'select(null): goes back to the device language',
      build: () {
        when(() => storage.load()).thenReturn(const Locale('ru'));
        return LocaleCubit(storage);
      },
      act: (cubit) => cubit.select(null),
      expect: () => [null],
      verify: (_) => verify(() => storage.save(null)).called(1),
    );

    blocTest<LocaleCubit, Locale?>(
      'select: ignores a language that is already active',
      build: () {
        when(() => storage.load()).thenReturn(const Locale('ru'));
        return LocaleCubit(storage);
      },
      act: (cubit) => cubit.select(const Locale('ru')),
      expect: () => <Locale?>[],
      verify: (_) => verifyNever(() => storage.save(any())),
    );
  });
}
