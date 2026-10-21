import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ramala/core/error/app_error.dart';
import 'package:ramala/template.dart';

class _LocErr implements Exception {
  const _LocErr(this.msg);
  final String msg;
}

class _Near {
  const _Near(
    this.id,
    this.title,
    this.category,
    this.pos,
    this.priceYes,
    this.meters,
  );
  final String id, title, category;
  final LatLng pos;
  final double priceYes, meters;
}

Future<Position> _locate() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const _LocErr('Aktifkan layanan lokasi (GPS) di perangkat.');
  }
  var p = await Geolocator.checkPermission();
  if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
  if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
    throw const _LocErr(
      'Izin lokasi ditolak. Aktifkan di pengaturan aplikasi.',
    );
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );
}

final _nearbyProvider =
    FutureProvider.autoDispose<({LatLng me, List<_Near> items})>((ref) async {
      final p = await _locate();
      final me = LatLng(p.latitude, p.longitude);
      final rows = await Supabase.instance.client
          .from('markets')
          .select('id,title,category,latitude,longitude,price_yes')
          .eq('status', 'open')
          .not('latitude', 'is', null);
      final items = rows.map((r) {
        final pos = LatLng(
          (r['latitude'] as num).toDouble(),
          (r['longitude'] as num).toDouble(),
        );
        return _Near(
          r['id'] as String,
          r['title'] as String,
          r['category'] as String,
          pos,
          (r['price_yes'] as num).toDouble(),
          Geolocator.distanceBetween(
            me.latitude,
            me.longitude,
            pos.latitude,
            pos.longitude,
          ),
        );
      }).toList()..sort((a, b) => a.meters.compareTo(b.meters));
      return (me: me, items: items);
    }, retry: (_, __) => null);

String _dist(double m) =>
    m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

class NearbyPage extends ConsumerWidget {
  const NearbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_nearbyProvider);
    return AppScaffold(
      title: 'Market Terdekat',
      onRefresh: () async {
        ref.invalidate(_nearbyProvider);
        try {
          await ref.read(_nearbyProvider.future);
        } catch (_) {}
      },
      children: [
        async.when(
          loading: () => const AppSkeleton(height: 300),
          error: (e, _) => ErrorState(
            message: e is _LocErr ? e.msg : AppError.message(e),
            onRetry: () => ref.invalidate(_nearbyProvider),
          ),
          data: (d) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 280,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: FlutterMap(
                    options: MapOptions(initialCenter: d.me, initialZoom: 12),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ramala', // samakan dengan applicationId
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: d.me,
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.my_location,
                              color: AppColors.arcane,
                              size: 28,
                            ),
                          ),
                          for (final i in d.items)
                            Marker(
                              point: i.pos,
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => context.push('/market/${i.id}'),
                                child: Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(AppSpace.xs),
              Text('© OpenStreetMap contributors', style: AppText.caption),
              const Gap(AppSpace.lg),
              const SectionHeader('Diurutkan dari yang terdekat'),
              if (d.items.isEmpty)
                const EmptyState(
                  title: 'Belum ada market berlokasi',
                  message: 'Admin dapat mengisi latitude dan longitude saat membuat market.',
                  icon: Icons.location_off,
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < d.items.length; i++) ...[
                        if (i > 0) const Divider(),
                        AppListTile(
                          icon: Icons.place_outlined,
                          title: d.items[i].title,
                          subtitle:
                              '${d.items[i].category} · ${_dist(d.items[i].meters)} · YES ${Fmt.pct(d.items[i].priceYes)}',
                          onTap: () => context.push('/market/${d.items[i].id}'),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
