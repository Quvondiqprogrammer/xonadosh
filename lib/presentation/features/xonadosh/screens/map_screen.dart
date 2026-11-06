import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';

class XonadoshMapScreen extends ConsumerStatefulWidget {
  const XonadoshMapScreen({super.key});

  @override
  ConsumerState<XonadoshMapScreen> createState() => _XonadoshMapScreenState();
}

class _XonadoshMapScreenState extends ConsumerState<XonadoshMapScreen> {
  final MapController _mapController = MapController();
  XonadoshListing? _selectedListing;
  XonadoshUniversity? _selectedUni;
  LatLng? _myLocation;
  bool _locating = false;

  static const LatLng _tashkentCenter = LatLng(41.311081, 69.240562);

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.xonadoshLocationDenied)),
          );
          _mapController.move(_tashkentCenter, 13);
        }
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.xonadoshLocationFailed)),
          );
          _mapController.move(_tashkentCenter, 13);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final point = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _myLocation = point);
      _mapController.move(point, 15);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.xonadoshLocationFailed)),
        );
        _mapController.move(_tashkentCenter, 13);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listingsAsync = ref.watch(xonadoshListingsProvider);
    final unisAsync = ref.watch(xonadoshUniversitiesProvider);

    final listings = listingsAsync.valueOrNull ?? [];
    final unis = unisAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: context.l10n.commonBack,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.shell);
            }
          },
        ),
        title: Text(context.l10n.xonadoshMapHomesAndUnis),
        actions: [
          IconButton(
            tooltip: context.l10n.xonadoshUseMyLocation,
            icon: _locating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            onPressed: _goToMyLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _tashkentCenter,
              initialZoom: 12.5,
              minZoom: 6,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'uz.zargo.xonadosh',
              ),
              if (_selectedUni != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        _selectedUni!.latitude,
                        _selectedUni!.longitude,
                      ),
                      radius: 1200,
                      useRadiusInMeter: true,
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderColor: const Color(0xFF10B981),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withAlpha(100),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ...unis.map((u) {
                    final isSelected = _selectedUni?.id == u.id;
                    return Marker(
                      point: LatLng(u.latitude, u.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedUni = u;
                            _selectedListing = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? XonaDoshColors.accentPurple
                                : const Color(0xFF6366F1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  }),
                  ...listings.map((l) {
                    final isSelected = _selectedListing?.id == l.id;
                    final isRent =
                        l.type == 'rent' || l.type == 'roommate_wanted';
                    final markerColor = isRent
                        ? XonaDoshColors.primary
                        : const Color(0xFFF59E0B);

                    return Marker(
                      point: LatLng(l.latitude, l.longitude),
                      width: isSelected ? 86 : 74,
                      height: isSelected ? 36 : 30,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedListing = l;
                            _selectedUni = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: markerColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: markerColor.withAlpha(120),
                                blurRadius: isSelected ? 8 : 4,
                                spreadRadius: isSelected ? 1 : 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                l.type == 'roommate_wanted'
                                    ? Icons.group_rounded
                                    : Icons.home_rounded,
                                color: Colors.white,
                                size: isSelected ? 15 : 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatShortPrice(l.price),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSelected ? 11 : 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(XonaDoshColors.primary, 'Ijara uylar'),
                const SizedBox(width: 8),
                _buildLegend(const Color(0xFF6366F1), 'Universitetlar'),
                const SizedBox(width: 8),
                _buildLegend(const Color(0xFFF59E0B), 'Sotuv'),
              ],
            ),
          ),
          if (_selectedListing != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildListingPreviewCard(
                context,
                _selectedListing!,
                isDark,
              ),
            )
          else if (_selectedUni != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildUniPreviewCard(context, _selectedUni!, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingPreviewCard(
    BuildContext context,
    XonadoshListing item,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final photo = item.photos.isNotEmpty ? item.photos.first : null;

    return Card(
      elevation: 10,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push('${AppRoutes.shell}/listing/${item.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: photo != null
                    ? Image.network(
                        photo,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildFallbackImg(isDark),
                      )
                    : _buildFallbackImg(isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: XonaDoshColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.type == 'roommate_wanted'
                                ? 'Xonadosh kerak'
                                : 'Ijara',
                            style: const TextStyle(
                              color: XonaDoshColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.isNoBroker) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Bez Makler',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (item.utilitiesIncluded) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Kommunal ichida',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              setState(() => _selectedListing = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.price.toStringAsFixed(0)} ${item.currency}/${item.pricePeriod == 'month' ? 'oy' : 'jami'}',
                      style: const TextStyle(
                        color: XonaDoshColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${item.district} • ${item.distanceToUniversityKm ?? 1.2} km OTMgacha',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniPreviewCard(
    BuildContext context,
    XonadoshUniversity uni,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 10,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uni.shortName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        uni.nameUz,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _selectedUni = null),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_subway_outlined,
                  size: 14,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    uni.nearestMetro != null
                        ? 'Metro: ${uni.nearestMetro}'
                        : 'Shahar markazi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      ref.read(xonadoshSelectedUniProvider.notifier).state =
                          uni;
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Yaqinidan izlash',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImg(bool isDark) {
    return Container(
      width: 90,
      height: 90,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      child: const Icon(Icons.apartment_rounded, size: 36, color: Colors.grey),
    );
  }

  String _formatShortPrice(double p) {
    if (p >= 1000000) {
      final mln = p / 1000000.0;
      return '${mln.toStringAsFixed(1).replaceAll('.0', '')} mln';
    }
    final ming = p / 1000.0;
    return '${ming.toStringAsFixed(0)} ming';
  }
}
