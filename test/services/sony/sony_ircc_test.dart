import 'package:flutter_test/flutter_test.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/services/sony/sony_ircc.dart';

void main() {
  group('sonyIrccNameFor', () {
    test('names the buttons a Bravia remote has', () {
      expect(sonyIrccNameFor(KeyCodes.KEY_UP), 'Up');
      expect(sonyIrccNameFor(KeyCodes.KEY_ENTER), 'Confirm');
      expect(sonyIrccNameFor(KeyCodes.KEY_RETURN), 'Return');
      expect(sonyIrccNameFor(KeyCodes.KEY_HOME), 'Home');
      expect(sonyIrccNameFor(KeyCodes.KEY_0), 'Num0');
      expect(sonyIrccNameFor(KeyCodes.KEY_9), 'Num9');
      expect(sonyIrccNameFor(KeyCodes.KEY_VOLUP), 'VolumeUp');
      expect(sonyIrccNameFor(KeyCodes.KEY_MUTE), 'Mute');
      expect(sonyIrccNameFor(KeyCodes.KEY_TOOLS), 'Options');
    });

    test('the power button means power off', () {
      expect(sonyIrccNameFor(KeyCodes.KEY_POWER), 'PowerOff');
    });

    test('returns null for keys a Bravia has no equivalent for', () {
      expect(sonyIrccNameFor(KeyCodes.KEY_RED), isNull);
      expect(sonyIrccNameFor(KeyCodes.KEY_REC), isNull);
    });
  });

  group('sonyIrccCodeFor', () {
    test('falls back to the documented codes', () {
      expect(sonyIrccCodeFor(KeyCodes.KEY_VOLUP), 'AAAAAQAAAAEAAAASAw==');
      expect(sonyIrccCodeFor(KeyCodes.KEY_MUTE), 'AAAAAQAAAAEAAAAUAw==');
      expect(sonyIrccCodeFor(KeyCodes.KEY_HOME), 'AAAAAQAAAAEAAABgAw==');
    });

    test('prefers the code the TV reported', () {
      const fromTv = {'VolumeUp': 'AAAAAQAAAAEAAAAVAw=='};

      expect(
        sonyIrccCodeFor(KeyCodes.KEY_VOLUP, remoteCodes: fromTv),
        'AAAAAQAAAAEAAAAVAw==',
      );
    });

    test('leaves out keys whose code Sony does not document', () {
      // Guessing these would press something else on the TV.
      expect(sonyIrccCodeFor(KeyCodes.KEY_REWIND), isNull);
      expect(sonyIrccCodeFor(KeyCodes.KEY_FF), isNull);
      expect(sonyIrccCodeFor(KeyCodes.KEY_INFO), isNull);
      expect(sonyIrccCodeFor(KeyCodes.KEY_EXT41), isNull);
    });

    test('takes them from the TV when it reports them', () {
      const fromTv = {'Rewind': 'TV-REWIND', 'Info': 'TV-INFO'};

      expect(
        sonyIrccCodeFor(KeyCodes.KEY_REWIND, remoteCodes: fromTv),
        'TV-REWIND',
      );
      expect(
        sonyIrccCodeFor(KeyCodes.KEY_INFO, remoteCodes: fromTv),
        'TV-INFO',
      );
    });

    test('no two buttons share a documented code', () {
      final used = <String, String>{};
      for (final key in KeyCodes.values) {
        final code = sonyIrccCodeFor(key);
        if (code == null) continue;
        expect(
          used[code],
          isNull,
          reason: '$code used by ${used[code]} and ${key.name}',
        );
        used[code] = key.name;
      }
    });
  });
}
