import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';

/// Base interface for every TV brand implementation.
abstract class TVInterface {
  String? get host;
  String? get mac;
  String? get deviceName;
  String? get modelName;

  bool get isConnected;
  ConnectionState get connectionState;

  Future<void> connect({String appName});
  void disconnect();
  Future<void> ensureConnection();

  Future<void> sendKey(KeyCodes key);

  /// Whether the TV moves an on-screen cursor from relative pointer motion.
  ///
  /// LG webOS exposes a pointer input socket for it; Samsung's control channel
  /// only carries key presses, so the pad is hidden for those sets.
  bool get supportsPointer;

  /// Moves the on-screen cursor by [dx] and [dy] pointer units.
  ///
  /// Only called when [supportsPointer] is true.
  Future<void> pointerMove({required int dx, required int dy});

  /// Clicks at the current cursor position.
  ///
  /// Only called when [supportsPointer] is true.
  Future<void> pointerClick();

  void setOnDisconnectedCallback(void Function(DisconnectionType) callback);
  void setOnConnectionStateChangedCallback(
    void Function(ConnectionState) callback,
  );
}
