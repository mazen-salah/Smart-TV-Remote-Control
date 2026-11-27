import 'package:flutter/material.dart';
import 'package:remote/core/models/tv_app.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/controller_button.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

/// One-tap shortcuts for the apps people actually switch to.
///
/// The label is the product name, so it is not translated; the id behind it
/// is resolved per brand in the implementation classes.
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l.apps,
      child: Row(
        children: [
          for (final app in TvApp.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _AppButton(app: app),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppButton extends StatelessWidget {
  const _AppButton({required this.app});

  final TvApp app;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: app.label,
      button: true,
      child: ControllerButton(
        borderRadius: 14,
        onPressed: () => context.openTvApp(app),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Text(
            app.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
