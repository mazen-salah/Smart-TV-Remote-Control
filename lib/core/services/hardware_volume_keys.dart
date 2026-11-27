import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

/// Which way the phone's volume rocker was pressed.
enum VolumeKeyDirection { up, down }

/// Routes the phone's hardware volume keys to the TV.
///
/// Android owns the volume keys for the playing media session, so the app can
/// only take them over through one (see `MainActivity.kt`): while capture is
/// on, pressing volume up/down never changes the phone's own volume, it calls
/// the callback given to [start] instead. Capture is meant to be live only while the remote is on
/// screen and connected; anything else would hijack the phone's keys.
///
/// Backed by a tiny method channel in `MainActivity.kt`; a no-op that reports
/// "not supported" on every other platform (iOS has no equivalent that App
/// Store rules allow — see issue #13).
class HardwareVolumeKeys {
  HardwareVolumeKeys({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? _defaultChannel,
      _isAndroid = isAndroid ?? Platform.isAndroid;

  static const MethodChannel _defaultChannel = MethodChannel(
    'com.summationworks.smarttvremote/volume_keys',
  );

  final MethodChannel _channel;
  final bool _isAndroid;

  void Function(VolumeKeyDirection direction)? _onKey;

  /// Whether capture is currently running.
  bool get isCapturing => _onKey != null;

  /// Starts capturing. Returns false when the platform cannot capture, so the
  /// caller can say so instead of silently doing nothing.
  Future<bool> start(void Function(VolumeKeyDirection direction) onKey) async {
    if (!_isAndroid) return false;
    if (isCapturing) {
      _onKey = onKey;
      return true;
    }
    _onKey = onKey;
    _channel.setMethodCallHandler(_handlePlatformCall);
    try {
      await _channel.invokeMethod<void>('start');
      return true;
    } on MissingPluginException {
      log('HardwareVolumeKeys: channel not registered');
      await stop();
      return false;
    } on PlatformException catch (e) {
      log('HardwareVolumeKeys.start failed: ${e.message}');
      await stop();
      return false;
    }
  }

  /// Stops capturing and hands the keys back to the phone. Safe to call when
  /// capture never started.
  Future<void> stop() async {
    final wasCapturing = isCapturing;
    _onKey = null;
    if (!_isAndroid || !wasCapturing) return;
    _channel.setMethodCallHandler(null);
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      log('HardwareVolumeKeys: channel not registered');
    } on PlatformException catch (e) {
      log('HardwareVolumeKeys.stop failed: ${e.message}');
    }
  }

  Future<void> _handlePlatformCall(MethodCall call) async {
    if (call.method != 'onVolumeKey') return;
    final onKey = _onKey;
    if (onKey == null) return;
    switch (call.arguments) {
      case 'up':
        onKey(VolumeKeyDirection.up);
      case 'down':
        onKey(VolumeKeyDirection.down);
      default:
        log('HardwareVolumeKeys: unknown direction ${call.arguments}');
    }
  }
}
