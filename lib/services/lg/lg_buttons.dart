import 'package:remote/constants/key_codes.dart';

/// Button names understood by the webOS pointer input socket
/// (`ssap://com.webos.service.networkinput/getPointerInputSocket`), keyed by
/// the shared [KeyCodes] the remote UI emits. Keys with no LG equivalent map
/// to `null` and are ignored by the LG implementation.
String? lgButtonFor(KeyCodes key) => switch (key) {
      KeyCodes.KEY_UP => 'UP',
      KeyCodes.KEY_DOWN => 'DOWN',
      KeyCodes.KEY_LEFT => 'LEFT',
      KeyCodes.KEY_RIGHT => 'RIGHT',
      KeyCodes.KEY_ENTER => 'ENTER',
      KeyCodes.KEY_RETURN => 'BACK',
      KeyCodes.KEY_EXT41 => 'EXIT',
      KeyCodes.KEY_HOME => 'HOME',
      KeyCodes.KEY_MENU => 'MENU',
      KeyCodes.KEY_INFO => 'INFO',
      KeyCodes.KEY_RED => 'RED',
      KeyCodes.KEY_GREEN => 'GREEN',
      KeyCodes.KEY_YELLOW => 'YELLOW',
      KeyCodes.KEY_CYAN => 'BLUE',
      KeyCodes.KEY_MUTE => 'MUTE',
      KeyCodes.KEY_VOLUP => 'VOLUMEUP',
      KeyCodes.KEY_VOLDOWN => 'VOLUMEDOWN',
      KeyCodes.KEY_CHUP => 'CHANNELUP',
      KeyCodes.KEY_CHDOWN => 'CHANNELDOWN',
      KeyCodes.KEY_0 => '0',
      KeyCodes.KEY_1 => '1',
      KeyCodes.KEY_2 => '2',
      KeyCodes.KEY_3 => '3',
      KeyCodes.KEY_4 => '4',
      KeyCodes.KEY_5 => '5',
      KeyCodes.KEY_6 => '6',
      KeyCodes.KEY_7 => '7',
      KeyCodes.KEY_8 => '8',
      KeyCodes.KEY_9 => '9',
      _ => null,
    };

/// `ssap://media.controls/<command>` for transport keys, or `null`.
String? lgMediaCommandFor(KeyCodes key) => switch (key) {
      KeyCodes.KEY_PLAY => 'play',
      KeyCodes.KEY_PAUSE => 'pause',
      KeyCodes.KEY_STOP => 'stop',
      KeyCodes.KEY_REWIND => 'rewind',
      KeyCodes.KEY_FF => 'fastForward',
      _ => null,
    };
