import 'package:remote/constants/key_codes.dart';

/// Button names in Sony's `X_SendIRCC` protocol, as `getRemoteControllerInfo`
/// reports them, keyed by the shared [KeyCodes] the remote UI emits.
///
/// The name is looked up in the code table the TV itself returns on connect;
/// [sonyIrccCodeFor] holds the values from Sony's documentation as a fallback
/// for a set that does not answer that call. Keys with no Bravia equivalent
/// map to `null` and are ignored.
String? sonyIrccNameFor(KeyCodes key) => switch (key) {
  KeyCodes.KEY_UP => 'Up',
  KeyCodes.KEY_DOWN => 'Down',
  KeyCodes.KEY_LEFT => 'Left',
  KeyCodes.KEY_RIGHT => 'Right',
  KeyCodes.KEY_ENTER => 'Confirm',
  KeyCodes.KEY_RETURN => 'Return',
  KeyCodes.KEY_HOME => 'Home',
  KeyCodes.KEY_INFO => 'Info',
  KeyCodes.KEY_TOOLS => 'Options',
  KeyCodes.KEY_SOURCE => 'Input',
  KeyCodes.KEY_EXT41 => 'Exit',
  KeyCodes.KEY_MUTE => 'Mute',
  KeyCodes.KEY_VOLUP => 'VolumeUp',
  KeyCodes.KEY_VOLDOWN => 'VolumeDown',
  KeyCodes.KEY_CHUP => 'ChannelUp',
  KeyCodes.KEY_CHDOWN => 'ChannelDown',
  KeyCodes.KEY_PLAY => 'Play',
  KeyCodes.KEY_PAUSE => 'Pause',
  KeyCodes.KEY_STOP => 'Stop',
  KeyCodes.KEY_REWIND => 'Rewind',
  KeyCodes.KEY_FF => 'Forward',
  KeyCodes.KEY_0 => 'Num0',
  KeyCodes.KEY_1 => 'Num1',
  KeyCodes.KEY_2 => 'Num2',
  KeyCodes.KEY_3 => 'Num3',
  KeyCodes.KEY_4 => 'Num4',
  KeyCodes.KEY_5 => 'Num5',
  KeyCodes.KEY_6 => 'Num6',
  KeyCodes.KEY_7 => 'Num7',
  KeyCodes.KEY_8 => 'Num8',
  KeyCodes.KEY_9 => 'Num9',
  // The remote's power button means "off"; a Bravia that is off answers to
  // Wake-on-LAN instead, like the other brands.
  KeyCodes.KEY_POWER => 'PowerOff',
  _ => null,
};

/// IRCC codes from Sony's own table for the buttons a Bravia is known to
/// accept. Only the values that appear in that table are here on purpose:
/// `Info`, `Exit`, `Rewind` and `Forward` are not among them, so those come
/// from the TV's `getRemoteControllerInfo` response or not at all.
const Map<String, String> sonyIrccFallback = {
  'PowerOff': 'AAAAAQAAAAEAAAAvAw==',
  'Input': 'AAAAAQAAAAEAAAAlAw==',
  'Display': 'AAAAAQAAAAEAAAA+Aw==',
  'VolumeUp': 'AAAAAQAAAAEAAAASAw==',
  'VolumeDown': 'AAAAAQAAAAEAAAATAw==',
  'Mute': 'AAAAAQAAAAEAAAAUAw==',
  'ChannelUp': 'AAAAAQAAAAEAAAAQAw==',
  'ChannelDown': 'AAAAAQAAAAEAAAARAw==',
  'Up': 'AAAAAQAAAAEAAAB0Aw==',
  'Down': 'AAAAAQAAAAEAAAB1Aw==',
  'Left': 'AAAAAQAAAAEAAAB2Aw==',
  'Right': 'AAAAAQAAAAEAAAB3Aw==',
  'Confirm': 'AAAAAQAAAAEAAABlAw==',
  'Home': 'AAAAAQAAAAEAAABgAw==',
  'Return': 'AAAAAgAAAJcAAAAjAw==',
  'Options': 'AAAAAgAAAJcAAAA2Aw==',
  'Play': 'AAAAAgAAAJcAAAAaAw==',
  'Pause': 'AAAAAgAAAJcAAAAZAw==',
  'Stop': 'AAAAAgAAAJcAAAAYAw==',
  'Next': 'AAAAAgAAAJcAAAA8Aw==',
  'Prev': 'AAAAAgAAAJcAAAA7Aw==',
  'Num0': 'AAAAAQAAAAEAAAAJAw==',
  'Num1': 'AAAAAQAAAAEAAAAAAw==',
  'Num2': 'AAAAAQAAAAEAAAABAw==',
  'Num3': 'AAAAAQAAAAEAAAACAw==',
  'Num4': 'AAAAAQAAAAEAAAADAw==',
  'Num5': 'AAAAAQAAAAEAAAAEAw==',
  'Num6': 'AAAAAQAAAAEAAAAFAw==',
  'Num7': 'AAAAAQAAAAEAAAAGAw==',
  'Num8': 'AAAAAQAAAAEAAAAHAw==',
  'Num9': 'AAAAAQAAAAEAAAAIAw==',
};

/// The code for [key], preferring the table the TV reported in
/// [remoteCodes] over the documented fallback.
String? sonyIrccCodeFor(
  KeyCodes key, {
  Map<String, String> remoteCodes = const {},
}) {
  final name = sonyIrccNameFor(key);
  if (name == null) return null;
  return remoteCodes[name] ?? sonyIrccFallback[name];
}
