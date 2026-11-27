import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/core/models/tv_app.dart';

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

  /// Brings [app] to the foreground.
  ///
  /// The id is brand-specific and resolved in the implementation; a brand
  /// without a known id for the app logs and does nothing.
  Future<void> launchApp(TvApp app);

  void setOnDisconnectedCallback(void Function(DisconnectionType) callback);
  void setOnConnectionStateChangedCallback(
    void Function(ConnectionState) callback,
  );
}
