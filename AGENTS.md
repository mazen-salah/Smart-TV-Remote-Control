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

Порядок после правок: `flutter gen-l10n` → `dart format .` → `flutter analyze` → `flutter test`.

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

- `origin` — `DNikulshin/Smart-TV-Remote-Control` (форк), `upstream` — апстрим.
- iPhone/iOS-локализация названия не сделана (нужны правки Xcode-проекта, а не только `Info.plist`).
