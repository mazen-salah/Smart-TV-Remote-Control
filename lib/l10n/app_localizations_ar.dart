// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ريموت التلفزيون الذكي';

  @override
  String get selectDevice => 'اختر الجهاز';

  @override
  String get addManually => 'إضافة يدوية';

  @override
  String get addTvManually => 'إضافة تلفزيون يدويًا';

  @override
  String get tvIpAddress => 'عنوان IP للتلفزيون';

  @override
  String get nameOptional => 'الاسم (اختياري)';

  @override
  String get cancel => 'إلغاء';

  @override
  String get add => 'إضافة';

  @override
  String get scanning => 'جارٍ فحص الشبكة…';

  @override
  String get devicesFound => 'الأجهزة المكتشفة';

  @override
  String foundCount(int count) {
    return 'تم العثور على $count جهاز';
  }

  @override
  String get noDevicesFound => 'لم يتم العثور على أجهزة';

  @override
  String get noDevicesHint =>
      'تأكد من تشغيل التلفزيون\nووجوده على نفس شبكة Wi-Fi';

  @override
  String get discoveryFailed => 'فشل اكتشاف الأجهزة';

  @override
  String get scanAgain => 'أعد الفحص';

  @override
  String get noWifi => 'لا يوجد اتصال Wi-Fi';

  @override
  String get noWifiHint =>
      'اتصل بشبكة Wi-Fi حتى يتمكن التطبيق من التحدث مع تلفزيونك.';

  @override
  String get wifiReconnected => 'تمت إعادة الاتصال بـ Wi-Fi';

  @override
  String get wifiDisconnected => 'تم قطع Wi-Fi — تحقق من اتصالك';

  @override
  String get remote => 'الريموت';

  @override
  String get reconnect => 'إعادة الاتصال';

  @override
  String get numericKeypad => 'لوحة الأرقام';

  @override
  String get power => 'تشغيل';

  @override
  String get connecting => 'جارٍ الاتصال…';

  @override
  String get reconnecting => 'جارٍ إعادة الاتصال…';

  @override
  String get connected => 'متصل';

  @override
  String get connectionError => 'خطأ في الاتصال';

  @override
  String get disconnected => 'غير متصل';

  @override
  String get idle => 'خامل';

  @override
  String disconnectedReason(String reason) {
    return 'غير متصل: $reason';
  }

  @override
  String get ok => 'موافق';

  @override
  String get back => 'عودة';

  @override
  String get exit => 'خروج';

  @override
  String get smart => 'Smart';

  @override
  String get input => 'المدخل';

  @override
  String get up => 'أعلى';

  @override
  String get down => 'أسفل';

  @override
  String get left => 'يسار';

  @override
  String get right => 'يمين';

  @override
  String get volumeUp => 'رفع الصوت';

  @override
  String get volumeDown => 'خفض الصوت';

  @override
  String get mute => 'كتم';

  @override
  String get channelUp => 'القناة التالية';

  @override
  String get channelDown => 'القناة السابقة';

  @override
  String get menu => 'القائمة';

  @override
  String get more => 'المزيد';

  @override
  String get rewind => 'إرجاع';

  @override
  String get record => 'تسجيل';

  @override
  String get play => 'تشغيل';

  @override
  String get stop => 'إيقاف';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get fastForward => 'تقديم';

  @override
  String get redButton => 'الزر الأحمر';

  @override
  String get greenButton => 'الزر الأخضر';

  @override
  String get yellowButton => 'الزر الأصفر';

  @override
  String get blueButton => 'الزر الأزرق';

  @override
  String get invalidIpv4 => 'عنوان IPv4 غير صالح';

  @override
  String get enterIpAddress => 'أدخل عنوان IP';

  @override
  String get lookingForTvs => 'جارٍ البحث عن التلفزيونات…';

  @override
  String get brand => 'العلامة التجارية';

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
  String get inputSource => 'مصدر الإدخال';

  @override
  String get unknown => 'غير معروف';

  @override
  String get manualIpHint => '192.168.1.42';

  @override
  String get manualNameHint => 'تلفزيون غرفة المعيشة';
}
