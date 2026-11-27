// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Пульт для Smart TV';

  @override
  String get selectDevice => 'Выбор устройства';

  @override
  String get addManually => 'Добавить вручную';

  @override
  String get addTvManually => 'Добавить телевизор вручную';

  @override
  String get tvIpAddress => 'IP-адрес телевизора';

  @override
  String get nameOptional => 'Название (необязательно)';

  @override
  String get cancel => 'Отмена';

  @override
  String get add => 'Добавить';

  @override
  String get scanning => 'Сканирование сети…';

  @override
  String get devicesFound => 'Найденные устройства';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $count устройства',
      many: 'Найдено $count устройств',
      few: 'Найдено $count устройства',
      one: 'Найдено $count устройство',
      zero: 'Устройства не найдены',
    );
    return '$_temp0';
  }

  @override
  String get noDevicesFound => 'Устройства не найдены';

  @override
  String get noDevicesHint =>
      'Убедитесь, что телевизор включён\nи подключён к той же сети Wi-Fi';

  @override
  String get discoveryFailed => 'Не удалось найти устройства';

  @override
  String get scanAgain => 'Сканировать снова';

  @override
  String get noWifi => 'Нет подключения к Wi-Fi';

  @override
  String get noWifiHint =>
      'Подключитесь к сети Wi-Fi, чтобы приложение могло связаться с телевизором.';

  @override
  String get wifiReconnected => 'Wi-Fi подключён снова';

  @override
  String get wifiDisconnected => 'Wi-Fi отключён — проверьте соединение';

  @override
  String get remote => 'Пульт';

  @override
  String get reconnect => 'Переподключиться';

  @override
  String get numericKeypad => 'Цифровая клавиатура';

  @override
  String get touchpad => 'Тачпад';

  @override
  String get touchpadHint => 'Свайп — курсор,\nкасание — выбор';

  @override
  String get power => 'Питание';

  @override
  String get connecting => 'Подключение…';

  @override
  String get reconnecting => 'Переподключение…';

  @override
  String get connected => 'Подключено';

  @override
  String get connectionError => 'Ошибка подключения';

  @override
  String get disconnected => 'Отключено';

  @override
  String get idle => 'Не подключено';

  @override
  String disconnectedReason(String reason) {
    return 'Отключено: $reason';
  }

  @override
  String get ok => 'OK';

  @override
  String get back => 'Назад';

  @override
  String get exit => 'Выход';

  @override
  String get smart => 'Smart';

  @override
  String get input => 'Источник';

  @override
  String get up => 'Вверх';

  @override
  String get down => 'Вниз';

  @override
  String get left => 'Влево';

  @override
  String get right => 'Вправо';

  @override
  String get volumeUp => 'Громче';

  @override
  String get volumeDown => 'Тише';

  @override
  String get mute => 'Без звука';

  @override
  String get channelUp => 'Следующий канал';

  @override
  String get channelDown => 'Предыдущий канал';

  @override
  String get menu => 'Меню';

  @override
  String get more => 'Ещё';

  @override
  String get rewind => 'Перемотка назад';

  @override
  String get record => 'Запись';

  @override
  String get play => 'Воспроизвести';

  @override
  String get stop => 'Стоп';

  @override
  String get pause => 'Пауза';

  @override
  String get fastForward => 'Перемотка вперёд';

  @override
  String get redButton => 'Красная кнопка';

  @override
  String get greenButton => 'Зелёная кнопка';

  @override
  String get yellowButton => 'Жёлтая кнопка';

  @override
  String get blueButton => 'Синяя кнопка';

  @override
  String get invalidIpv4 => 'Неверный IPv4-адрес';

  @override
  String get enterIpAddress => 'Введите IP-адрес';

  @override
  String get lookingForTvs => 'Ищем телевизоры…';

  @override
  String get brand => 'Марка';

  @override
  String get brandSamsung => 'Samsung';

  @override
  String get brandLg => 'LG';

  @override
  String ipLabel(String host) {
    return 'IP: $host';
  }

  @override
  String macLabel(String mac) {
    return 'MAC: $mac';
  }

  @override
  String get smartHub => 'Smart Hub';

  @override
  String get inputSource => 'Источник сигнала';

  @override
  String get unknown => 'неизвестно';

  @override
  String get manualIpHint => '192.168.1.42';

  @override
  String get manualNameHint => 'Телевизор в гостиной';

  @override
  String get forgetTv => 'Забыть этот телевизор';

  @override
  String forgetTvConfirm(String name) {
    return 'Удалить $name и его сопряжение? Придётся снова разрешить приложение на телевизоре.';
  }

  @override
  String get forget => 'Забыть';

  @override
  String connectionFailed(String reason) {
    return 'Не удалось подключиться: $reason';
  }

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageSpanish => 'Испанский';

  @override
  String get languageArabic => 'Арабский';
}
