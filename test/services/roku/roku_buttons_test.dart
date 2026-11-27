import 'package:flutter_test/flutter_test.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/services/roku/roku_buttons.dart';

void main() {
  group('rokuKeyFor', () {
    test('maps the navigation and transport keys ECP knows', () {
      expect(rokuKeyFor(KeyCodes.KEY_UP), 'Up');
      expect(rokuKeyFor(KeyCodes.KEY_DOWN), 'Down');
      expect(rokuKeyFor(KeyCodes.KEY_LEFT), 'Left');
      expect(rokuKeyFor(KeyCodes.KEY_RIGHT), 'Right');
      expect(rokuKeyFor(KeyCodes.KEY_ENTER), 'Select');
      expect(rokuKeyFor(KeyCodes.KEY_RETURN), 'Back');
      expect(rokuKeyFor(KeyCodes.KEY_HOME), 'Home');
      expect(rokuKeyFor(KeyCodes.KEY_PLAY), 'Play');
      expect(rokuKeyFor(KeyCodes.KEY_REWIND), 'Rev');
      expect(rokuKeyFor(KeyCodes.KEY_FF), 'Fwd');
    });

    test('maps volume and channel keys, which Roku TVs accept', () {
      expect(rokuKeyFor(KeyCodes.KEY_VOLUP), 'VolumeUp');
      expect(rokuKeyFor(KeyCodes.KEY_VOLDOWN), 'VolumeDown');
      expect(rokuKeyFor(KeyCodes.KEY_MUTE), 'VolumeMute');
      expect(rokuKeyFor(KeyCodes.KEY_CHUP), 'ChannelUp');
      expect(rokuKeyFor(KeyCodes.KEY_CHDOWN), 'ChannelDown');
    });

    test('types digits, since Roku has no numeric prefix', () {
      for (final digit in [
        KeyCodes.KEY_0,
        KeyCodes.KEY_1,
        KeyCodes.KEY_5,
        KeyCodes.KEY_9,
      ]) {
        final name = rokuKeyFor(digit);
        expect(name, startsWith('Lit_'), reason: digit.name);
        expect(name, endsWith(digit.name.substring(4)));
      }
    });

    test('pause toggles playback, because Roku has no pause key', () {
      expect(rokuKeyFor(KeyCodes.KEY_PAUSE), 'Play');
    });

    test('returns null for keys the remote has no Roku equivalent for', () {
      for (final key in [
        KeyCodes.KEY_RED,
        KeyCodes.KEY_GREEN,
        KeyCodes.KEY_YELLOW,
        KeyCodes.KEY_CYAN,
        KeyCodes.KEY_STOP,
        KeyCodes.KEY_REC,
        KeyCodes.KEY_TOOLS,
        KeyCodes.KEY_SOURCE,
        KeyCodes.KEY_POWER,
      ]) {
        expect(rokuKeyFor(key), isNull, reason: key.name);
      }
    });

    test('only the documented aliases share an ECP name', () {
      // Play is both play and pause, and Info is both the info and menu key:
      // Roku has one key for each pair.
      const aliases = {'Play', 'Info'};
      final mapped = <String, KeyCodes>{};
      final shared = <String>{};
      for (final key in KeyCodes.values) {
        final name = rokuKeyFor(key);
        if (name == null) continue;
        if (mapped.containsKey(name)) {
          shared.add(name);
          continue;
        }
        mapped[name] = key;
      }

      expect(shared, aliases);
    });
  });
}
