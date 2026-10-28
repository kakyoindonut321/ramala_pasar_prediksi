import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/template.dart';

/// Koordinat market (null jika admin tidak memasang lokasi).
final marketLocationProvider = FutureProvider.autoDispose
    .family<LatLng?, String>((ref, id) async {
      final r = await Supabase.instance.client
          .from('markets')
          .select('latitude,longitude')
          .eq('id', id)
          .single();
      final la = (r['latitude'] as num?)?.toDouble();
      final lo = (r['longitude'] as num?)?.toDouble();
      return la == null || lo == null ? null : LatLng(la, lo);
    }, retry: (_, __) => null);

class MarketLocationPage extends StatelessWidget {
  const MarketLocationPage({
    super.key,
    required this.title,
    required this.point,
  });
  final String title;
  final LatLng point;

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Lokasi Market',
    body: Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ramala',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 48,
                  height: 48,
                  alignment: Alignment.topCenter, // ujung pin tepat di titik
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: AppSpace.lg,
          left: AppSpace.lg,
          right: AppSpace.lg,
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.heading,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(AppSpace.xs),
                Text(
                  '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
