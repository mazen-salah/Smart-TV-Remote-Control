import 'package:flutter/material.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/l10n/app_localizations.dart';

class DeviceListItem extends StatelessWidget {
  const DeviceListItem({
    required this.device,
    required this.onTap,
    this.onLongPress,
    this.busy = false,
    super.key,
  });

  final TVDevice device;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Shows a spinner instead of the chevron while this TV is connecting.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mac = device.mac;
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[700]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.tv, color: Colors.blue, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                device.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Which protocol a tap will use, resolved the same way the
            // repository resolves it.
            _BrandChip(brand: TvBrand.fromDevice(device)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.ipLabel(device.host ?? '—'),
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            if (mac != null && mac.isNotEmpty)
              Text(
                l.macLabel(mac),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
          ],
        ),
        trailing: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

/// Small label with the brand the app will talk to this set with.
class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.brand});

  final TvBrand brand;

  @override
  Widget build(BuildContext context) {
    // No Semantics wrapper: the text below is already the label a screen
    // reader reads, and wrapping it announces the brand twice.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[600]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        brand.manufacturer,
        style: TextStyle(color: Colors.grey[300], fontSize: 11),
      ),
    );
  }
}
