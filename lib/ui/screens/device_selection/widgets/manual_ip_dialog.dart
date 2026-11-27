import 'package:flutter/material.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/l10n/app_localizations.dart';

typedef ManualIpResult = ({
  String host,
  String? name,
  TvBrand brand,
  String? preSharedKey,
});

class ManualIpDialog extends StatefulWidget {
  const ManualIpDialog({super.key});

  static Future<ManualIpResult?> show(BuildContext context) {
    return showDialog<ManualIpResult>(
      context: context,
      builder: (_) => const ManualIpDialog(),
    );
  }

  @override
  State<ManualIpDialog> createState() => _ManualIpDialogState();
}

class _ManualIpDialogState extends State<ManualIpDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _nameController = TextEditingController();
  final _pskController = TextEditingController();
  TvBrand _brand = TvBrand.samsung;

  @override
  void dispose() {
    _ipController.dispose();
    _nameController.dispose();
    _pskController.dispose();
    super.dispose();
  }

  String? _validateIp(String? value) {
    final l = AppLocalizations.of(context);
    final v = (value ?? '').trim();
    if (v.isEmpty) return l.enterIpAddress;
    final parts = v.split('.');
    if (parts.length != 4) return l.invalidIpv4;
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return l.invalidIpv4;
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final host = _ipController.text.trim();
    final name = _nameController.text.trim();
    // Only a Bravia needs a pre-shared key; the other brands pair themselves.
    final psk = _brand == TvBrand.sony ? _pskController.text.trim() : '';
    Navigator.of(context).pop((
      host: host,
      name: name.isEmpty ? null : name,
      brand: _brand,
      preSharedKey: psk.isEmpty ? null : psk,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.addTvManually),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TvBrand>(
              segments: [
                ButtonSegment(
                  value: TvBrand.samsung,
                  label: Text(l.brandSamsung),
                ),
                ButtonSegment(value: TvBrand.lg, label: Text(l.brandLg)),
                ButtonSegment(value: TvBrand.roku, label: Text(l.brandRoku)),
                ButtonSegment(value: TvBrand.sony, label: Text(l.brandSony)),
              ],
              selected: {_brand},
              onSelectionChanged: (selection) =>
                  setState(() => _brand = selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l.tvIpAddress,
                hintText: l.manualIpHint,
              ),
              validator: _validateIp,
            ),
            if (_brand == TvBrand.sony) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _pskController,
                decoration: InputDecoration(
                  labelText: l.preSharedKey,
                  hintText: l.preSharedKeyHint,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l.nameOptional,
                hintText: l.manualNameHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.add)),
      ],
    );
  }
}
