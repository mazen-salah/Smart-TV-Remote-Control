import 'package:flutter_test/flutter_test.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/services/lg/lg_buttons.dart';

void main() {
  group('lgButtonFor', () {
    test('maps navigation keys to pointer-socket button names', () {
      expect(lgButtonFor(KeyCodes.KEY_UP), 'UP');
      expect(lgButtonFor(KeyCodes.KEY_ENTER), 'ENTER');
      expect(lgButtonFor(KeyCodes.KEY_RETURN), 'BACK');
      expect(lgButtonFor(KeyCodes.KEY_EXT41), 'EXIT');
    });

    test('maps colour keys, including Samsung cyan to LG blue', () {
      expect(lgButtonFor(KeyCodes.KEY_CYAN), 'BLUE');
      expect(lgButtonFor(KeyCodes.KEY_RED), 'RED');
    });

    test('maps every digit', () {
      const digits = [
        KeyCodes.KEY_0,
        KeyCodes.KEY_1,
        KeyCodes.KEY_2,
        KeyCodes.KEY_3,
        KeyCodes.KEY_4,
        KeyCodes.KEY_5,
        KeyCodes.KEY_6,
        KeyCodes.KEY_7,
        KeyCodes.KEY_8,
        KeyCodes.KEY_9,
      ];
      for (var i = 0; i < digits.length; i++) {
        expect(lgButtonFor(digits[i]), '$i');
      }
    });

    test('returns null for keys webOS has no button for', () {
      expect(lgButtonFor(KeyCodes.KEY_SOURCE), isNull);
      expect(lgButtonFor(KeyCodes.KEY_TOOLS), isNull);
      expect(lgButtonFor(KeyCodes.KEY_PLAY), isNull);
    });
  });

  group('lgMediaCommandFor', () {
    test('maps transport keys to media.controls commands', () {
      expect(lgMediaCommandFor(KeyCodes.KEY_PLAY), 'play');
      expect(lgMediaCommandFor(KeyCodes.KEY_FF), 'fastForward');
      expect(lgMediaCommandFor(KeyCodes.KEY_UP), isNull);
    });
  });
}
