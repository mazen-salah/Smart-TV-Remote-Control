# Smart TV Remote — форк с русской поддержкой

> Форк [mazen-salah/Smart-TV-Remote-Control](https://github.com/mazen-salah/Smart-TV-Remote-Control) (Flutter,
> MIT). Апстрим главнее по коду приложения: наши изменения — локализация и документация,
> чтобы их можно было отправить PR'ом.

## Что добавлено поверх апстрима

- `lib/l10n/app_ru.arb` — полный русский перевод (79 строк, плюрализация счётчика устройств).
- `lib/l10n/app_localizations*.dart` — сгенерированы `flutter gen-l10n`, коммитятся.
- Переключатель языка в шапке экрана выбора устройства: `LocaleCubit` + `LocaleStorage`
  (`shared_preferences`), «Как в системе» сбрасывает выбор. Тесты:
  `test/blocs/locale/`, `test/ui/language_menu_button_test.dart`.
- Название приложения на Android: `res/values-ru/strings.xml` (`@string/app_name` в манифесте).
- Название и текст разрешения на локальную сеть на iOS: `ios/Runner/{en,ru}.lproj/InfoPlist.strings`,
  подключены вариант-группой в `project.pbxproj`; связность проверяет `tool/check_ios_localization.py`.
- Документация: `README.ru.md`, `docs/ru/setup.md` (гайд по настройке), `docs/ru/privacy.md`.

## Команды

Flutter локально: `export PATH="$HOME/sdk/flutter/bin:$PATH"` (3.47.9 stable).

| Что | Команда |
|---|---|
| Зависимости | `flutter pub get` |
| Строки из ARB | `flutter gen-l10n` |
| Формат | `dart format .` (CI проверяет `--set-exit-if-changed`) |
| Анализ | `flutter analyze` (very_good_analysis, infos тоже валят CI) |
| Тесты | `flutter test --coverage`, отчёт покрытия — `python3 tool/coverage_summary.py` |
| Проверка UI без телефона | `flutter build web` → `python3 -m http.server` в `build/web` |
| Проверка Android-сборки | `flutter build apk --debug` (см. окружение ниже) |

Порядок после правок: `flutter gen-l10n` → `dart format .` → `flutter analyze` → `flutter test`.

Android-сборка: в системе нет `java` и Android SDK из `apt` (sudo в контейнере запрещён),
поэтому JDK 17 (Temurin) и SDK установлены в `~/sdk`. Перед `flutter build apk` нужны переменные:

```bash
export JAVA_HOME="$HOME/sdk/jdk/jdk-17.0.21.1+2"
export ANDROID_HOME="$HOME/sdk/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

В SDK стоят `platform-tools`, `platforms;android-36`, `build-tools;36.0.0`, NDK r28c скачался
сам при первой сборке. Подпись — debug-ключ: `android/key.properties` здесь нет и не должно быть.
Проверить, что ресурсы попали в APK, можно без телефона:
`"$ANDROID_HOME/build-tools/36.0.0/aapt2" dump badging build/app/outputs/flutter-apk/app-debug.apk`.

`coverage/lcov.info` коммитится в репозиторий: после `flutter test --coverage` он меняется,
и это нормально включать в коммит с тестами (так делал апстрим).

## Правила локализации

- Ключи добавляются сначала в `app_en.arb` (шаблон), потом во все остальные локали;
  набор ключей должен совпадать (проверяется скриптом ниже).
- Плейсхолдеры (`{count}`, `{host}`) в переводе не переименовывать.
- Надписи на кнопках пульта (`MENU`, `MORE`, `SMART`, `INPUT`, `EXIT`, `TOOLS`, `GUIDE`)
  не переводятся: это лица кнопок штатного пульта.
- `lib/l10n/**` исключён из анализа линтером — руками не правим.

```bash
python3 - <<'PY'
import json
en = {k for k in json.load(open('lib/l10n/app_en.arb')) if not k.startswith('@')}
for loc in ('ru', 'es', 'ar'):
    d = {k for k in json.load(open(f'lib/l10n/app_{loc}.arb')) if not k.startswith('@')}
    print(loc, 'missing:', sorted(en - d), 'extra:', sorted(d - en))
PY
```

## Git

- `origin` — `DNikulshin/Smart-TV-Remote-Control` (форк), `upstream` — апстрим (`mazen-salah`).
- PR в апстрим идёт из ветки `i18n/ru`, а не из `main`: ветка — это `main` без `AGENTS.md`
  (правила форка апстриму не нужны) плюс сами коммиты. PR #44 — вся русская локализация.
  После слияния/правок сначала обновлять `i18n/ru`, потом переносить изменения в `main`
  (`git cherry-pick`), чтобы файлы форка не утекли в PR.
- Workflow CI в апстриме на PR из форка висит в `action_required`, пока мейнтейнер не
  разрешит запуск. Поэтому перед PR полезно прогнать локально то же, что делает CI:
  формат, анализ, тесты с покрытием и `flutter build apk --debug`.

## iOS: локализация названия

`Info.plist` правится только в одном языке, поэтому название и текст разрешения на локальную сеть
переведены через `ios/Runner/{en,ru}.lproj/InfoPlist.strings`; в проекте они подключены
вариант-группой `InfoPlist.strings` (`PBXVariantGroup`), в `knownRegions` добавлен `ru`.
Xcode на этой машине нет, CI собирает только Android, поэтому связность проверяется скриптом:

```bash
python3 tool/check_ios_localization.py          # ожидает en и ru
```

Он парсит `project.pbxproj` как OpenStep-plist, проверяет, что все ссылки разрешаются,
файлы `.lproj` существуют и содержат `CFBundleDisplayName` и `NSLocalNetworkUsageDescription`,
а build-файл лежит в фазе Resources таргета Runner. Новый язык — `--languages en,ru,de`
и такая же ветка в `values-<lang>/strings.xml` для Android.
