import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/ui/widgets/remote_controls/components/controller_button.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

class NumPad extends StatelessWidget {
  const NumPad({super.key});

  static const _digits = <_DigitRow>[
    _DigitRow([
      _Digit('1', KeyCodes.KEY_1),
      _Digit('2', KeyCodes.KEY_2),
      _Digit('3', KeyCodes.KEY_3),
    ]),
    _DigitRow([
      _Digit('4', KeyCodes.KEY_4),
      _Digit('5', KeyCodes.KEY_5),
      _Digit('6', KeyCodes.KEY_6),
    ]),
    _DigitRow([
      _Digit('7', KeyCodes.KEY_7),
      _Digit('8', KeyCodes.KEY_8),
      _Digit('9', KeyCodes.KEY_9),
    ]),
    _DigitRow([
      _Digit('TOOLS', KeyCodes.KEY_TOOLS, small: true),
      _Digit('0', KeyCodes.KEY_0),
      _Digit('GUIDE', KeyCodes.KEY_GUIDE, small: true),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _digits
            .map(
              (row) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.digits.map((d) => _NumButton(digit: d)).toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NumButton extends StatelessWidget {
  const _NumButton({required this.digit});
  final _Digit digit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: digit.label,
      button: true,
      child: ControllerButton(
        onPressed: () => context.sendTvKey(digit.key),
        child: Text(
          digit.label,
          style: TextStyle(
            fontSize: digit.small ? 10 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _Digit {
  const _Digit(this.label, this.key, {this.small = false});
  final String label;
  final KeyCodes key;
  final bool small;
}

class _DigitRow {
  const _DigitRow(this.digits);
  final List<_Digit> digits;
}
