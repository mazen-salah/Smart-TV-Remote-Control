import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart TV Remote'**
  String get appTitle;

  /// No description provided for @selectDevice.
  ///
  /// In en, this message translates to:
  /// **'Select Device'**
  String get selectDevice;

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get addManually;

  /// No description provided for @addTvManually.
  ///
  /// In en, this message translates to:
  /// **'Add TV manually'**
  String get addTvManually;

  /// No description provided for @tvIpAddress.
  ///
  /// In en, this message translates to:
  /// **'TV IP address'**
  String get tvIpAddress;

  /// No description provided for @nameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get nameOptional;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning network…'**
  String get scanning;

  /// No description provided for @devicesFound.
  ///
  /// In en, this message translates to:
  /// **'Devices found'**
  String get devicesFound;

  /// No description provided for @foundCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count} device(s)'**
  String foundCount(int count);

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// No description provided for @noDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure your TV is powered on\nand on the same Wi-Fi network'**
  String get noDevicesHint;

  /// No description provided for @discoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Discovery failed'**
  String get discoveryFailed;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @noWifi.
  ///
  /// In en, this message translates to:
  /// **'No Wi-Fi connection'**
  String get noWifi;

  /// No description provided for @noWifiHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to a Wi-Fi network so the app can talk to your TV.'**
  String get noWifiHint;

  /// No description provided for @wifiReconnected.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi reconnected'**
  String get wifiReconnected;

  /// No description provided for @wifiDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi disconnected — check your connection'**
  String get wifiDisconnected;

  /// No description provided for @remote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @numericKeypad.
  ///
  /// In en, this message translates to:
  /// **'Numeric keypad'**
  String get numericKeypad;

  /// No description provided for @power.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @idle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idle;

  /// No description provided for @disconnectedReason.
  ///
  /// In en, this message translates to:
  /// **'Disconnected: {reason}'**
  String disconnectedReason(String reason);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @smart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get smart;

  /// No description provided for @input.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get input;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get up;

  /// No description provided for @down.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get down;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @volumeUp.
  ///
  /// In en, this message translates to:
  /// **'Volume up'**
  String get volumeUp;

  /// No description provided for @volumeDown.
  ///
  /// In en, this message translates to:
  /// **'Volume down'**
  String get volumeDown;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @channelUp.
  ///
  /// In en, this message translates to:
  /// **'Channel up'**
  String get channelUp;

  /// No description provided for @channelDown.
  ///
  /// In en, this message translates to:
  /// **'Channel down'**
  String get channelDown;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @rewind.
  ///
  /// In en, this message translates to:
  /// **'Rewind'**
  String get rewind;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @fastForward.
  ///
  /// In en, this message translates to:
  /// **'Fast forward'**
  String get fastForward;

  /// No description provided for @redButton.
  ///
  /// In en, this message translates to:
  /// **'Red button'**
  String get redButton;

  /// No description provided for @greenButton.
  ///
  /// In en, this message translates to:
  /// **'Green button'**
  String get greenButton;

  /// No description provided for @yellowButton.
  ///
  /// In en, this message translates to:
  /// **'Yellow button'**
  String get yellowButton;

  /// No description provided for @blueButton.
  ///
  /// In en, this message translates to:
  /// **'Blue button'**
  String get blueButton;

  /// No description provided for @invalidIpv4.
  ///
  /// In en, this message translates to:
  /// **'Invalid IPv4 address'**
  String get invalidIpv4;

  /// No description provided for @enterIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter an IP address'**
  String get enterIpAddress;

  /// No description provided for @lookingForTvs.
  ///
  /// In en, this message translates to:
  /// **'Looking for TVs…'**
  String get lookingForTvs;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @brandSamsung.
  ///
  /// In en, this message translates to:
  /// **'Samsung'**
  String get brandSamsung;

  /// No description provided for @brandLg.
  ///
  /// In en, this message translates to:
  /// **'LG'**
  String get brandLg;

  /// No description provided for @ipLabel.
  ///
  /// In en, this message translates to:
  /// **'IP: {host}'**
  String ipLabel(String host);

  /// No description provided for @macLabel.
  ///
  /// In en, this message translates to:
  /// **'MAC: {mac}'**
  String macLabel(String mac);

  /// No description provided for @smartHub.
  ///
  /// In en, this message translates to:
  /// **'Smart hub'**
  String get smartHub;

  /// No description provided for @inputSource.
  ///
  /// In en, this message translates to:
  /// **'Input source'**
  String get inputSource;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknown;

  /// No description provided for @manualIpHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.42'**
  String get manualIpHint;

  /// No description provided for @manualNameHint.
  ///
  /// In en, this message translates to:
  /// **'Living-room TV'**
  String get manualNameHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
