import 'package:remote/constants/key_codes.dart';

/// Roku ECP key names for `POST /keypress/<name>`, keyed by the shared
/// [KeyCodes] the remote UI emits. Keys with no Roku equivalent map to `null`
/// and are ignored by the Roku implementation.
///
/// Roku has no separate pause: `Play` toggles, so both play and pause arrive
/// as `Play`, and there is no stop, no colour keys and no numeric prefix —
/// digits are typed as `Lit_<digit>`.
String? rokuKeyFor(KeyCodes key) => switch (key) {
  KeyCodes.KEY_UP => 'Up',
  KeyCodes.KEY_DOWN => 'Down',
  KeyCodes.KEY_LEFT => 'Left',
  KeyCodes.KEY_RIGHT => 'Right',
  KeyCodes.KEY_ENTER => 'Select',
  KeyCodes.KEY_RETURN => 'Back',
  KeyCodes.KEY_HOME => 'Home',
  KeyCodes.KEY_INFO => 'Info',
  KeyCodes.KEY_MENU => 'Info',
  KeyCodes.KEY_MUTE => 'VolumeMute',
  KeyCodes.KEY_VOLUP => 'VolumeUp',
  KeyCodes.KEY_VOLDOWN => 'VolumeDown',
  KeyCodes.KEY_CHUP => 'ChannelUp',
  KeyCodes.KEY_CHDOWN => 'ChannelDown',
  KeyCodes.KEY_PLAY => 'Play',
  // `Play` toggles on Roku, which is the closest thing to a pause button.
  KeyCodes.KEY_PAUSE => 'Play',
  KeyCodes.KEY_REWIND => 'Rev',
  KeyCodes.KEY_FF => 'Fwd',
  KeyCodes.KEY_0 => 'Lit_0',
  KeyCodes.KEY_1 => 'Lit_1',
  KeyCodes.KEY_2 => 'Lit_2',
  KeyCodes.KEY_3 => 'Lit_3',
  KeyCodes.KEY_4 => 'Lit_4',
  KeyCodes.KEY_5 => 'Lit_5',
  KeyCodes.KEY_6 => 'Lit_6',
  KeyCodes.KEY_7 => 'Lit_7',
  KeyCodes.KEY_8 => 'Lit_8',
  KeyCodes.KEY_9 => 'Lit_9',
  _ => null,
};
