import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

/// Holds Android's `WifiManager.MulticastLock` while a discovery sweep runs.
///
/// Android filters multicast packets unless an app holds this lock, so SSDP
/// replies never arrive without it. Backed by a tiny method channel in
/// `MainActivity.kt`; a no-op on every other platform.
class MulticastLock {
  static const MethodChannel _channel = MethodChannel(
    'com.summationworks.smarttvremote/multicast',
  );

  Future<void> acquire() => _invoke('acquire');
  Future<void> release() => _invoke('release');

  Future<void> _invoke(String method) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException catch (e) {
      log('MulticastLock.$method failed: ${e.message}');
    } on MissingPluginException {
      log('MulticastLock: channel not registered');
    }
  }
}
