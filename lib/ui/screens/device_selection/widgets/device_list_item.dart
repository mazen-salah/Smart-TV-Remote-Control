import 'package:flutter/material.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/l10n/app_localizations.dart';

class DeviceListItem extends StatelessWidget {
  const DeviceListItem({
    required this.device,
    required this.onTap,
    super.key,
  });

  final TVDevice device;
  final VoidCallback onTap;

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
        title: Text(
          device.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
