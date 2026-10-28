import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ramala/template.dart';

const _zones = [
  ('WIB', 'Asia/Jakarta'),
  ('WITA', 'Asia/Makassar'),
  ('WIT', 'Asia/Jayapura'),
  ('London', 'Europe/London'),
  ('New York', 'America/New_York'),
  ('Tokyo', 'Asia/Tokyo'),
  ('Abu Dhabi', 'Asia/Dubai'),
];

/// Waktu tutup market di beberapa zona. Ringkas (4 zona) atau semua (7).
class CloseTimes extends StatefulWidget {
  const CloseTimes(this.closeAt, {super.key});
  final DateTime closeAt;
  @override
  State<CloseTimes> createState() => _CloseTimesState();
}

class _CloseTimesState extends State<CloseTimes> {
  bool _all = false;

  String _title(String name, tz.TZDateTime t) {
    final o = t.timeZoneOffset;
    return '$name · UTC${o.isNegative ? '-' : '+'}${o.inHours.abs()}';
  }

  @override
  Widget build(BuildContext context) {
    final shown = _all ? _zones : _zones.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Waktu tutup di zona lain',
          action: _all ? 'Ringkas' : 'Semua',
          onAction: () => setState(() => _all = !_all),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const Divider(),
                Builder(
                  builder: (_) {
                    final t = tz.TZDateTime.from(
                      widget.closeAt.toUtc(),
                      tz.getLocation(shown[i].$2),
                    );
                    return AppListTile(
                      icon: Icons.public,
                      title: _title(shown[i].$1, t),
                      subtitle: DateFormat('EEE, d MMM y HH:mm').format(t),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
