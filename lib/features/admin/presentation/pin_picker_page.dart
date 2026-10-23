import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ramala/template.dart';

/// Halaman pilih lokasi: ketuk peta untuk menaruh pin. Mengembalikan LatLng lewat Navigator.pop.
class PinPickerPage extends StatefulWidget {
  const PinPickerPage({super.key, this.initial});
  final LatLng? initial;
  @override
  State<PinPickerPage> createState() => _PinPickerPageState();
}

class _PinPickerPageState extends State<PinPickerPage> {
  late LatLng? _pin = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pilih lokasi',
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter:
                    widget.initial ?? const LatLng(-7.7956, 110.3695),
                initialZoom: widget.initial != null ? 15 : 11,
                onTap: (_, p) => setState(() => _pin = p),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ramala',
                ),
                if (_pin != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pin!,
                        width: 40,
                        height: 40,
                        alignment:
                            Alignment.topCenter, // ujung pin tepat di titik
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.no,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: AppButton(
              label: _pin == null
                  ? 'Ketuk peta untuk menaruh pin'
                  : 'Pakai lokasi ini',
              expanded: true,
              onPressed: _pin == null
                  ? null
                  : () => Navigator.pop(context, _pin),
            ),
          ),
        ],
      ),
    );
  }
}
