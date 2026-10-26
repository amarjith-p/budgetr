// lib/features/transactions/views/location_map_picker_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/components/futuristic_loader.dart';
import '../providers/transaction_provider.dart';

enum MapPickerStyle { satellite, streets, terrain }

class PastLocationSpot {
  final String id;
  final String name;
  final LatLng position;
  final int count;
  final double totalSpent;
  final String? primaryCategory;

  const PastLocationSpot({
    required this.id,
    required this.name,
    required this.position,
    required this.count,
    required this.totalSpent,
    this.primaryCategory,
  });
}

class QuickCategoryConfig {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> osmTags;
  final List<String> categoryKeywords;
  final List<String> nameKeywords;
  final String fallbackQuery;

  const QuickCategoryConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.osmTags,
    required this.categoryKeywords,
    required this.nameKeywords,
    required this.fallbackQuery,
  });
}

class LocationMapPickerPage extends ConsumerStatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;

  const LocationMapPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
  });

  @override
  ConsumerState<LocationMapPickerPage> createState() =>
      _LocationMapPickerPageState();
}

class _LocationMapPickerPageState extends ConsumerState<LocationMapPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng _center = const LatLng(20.5937, 78.9629);
  bool _isLoadingLoc = true;
  bool _isConfirming = false;
  bool _isFetchingCurrentLoc = false;
  bool _isMoving = false;
  List<dynamic> _searchResults = [];
  Timer? _searchDebounce;
  int _searchSessionId = 0;
  Timer? _addressDebounce;
  bool _isSearching = false;
  QuickCategoryConfig? _activeCategory;

  String? _selectedPoiName;
  String _currentAddress = 'Locating...';
  String _subAddress = '';
  bool _isFetchingAddress = true;
  bool _isAddressManuallyEdited = false;

  // Google Maps Style & Past Spot Settings
  MapPickerStyle _mapStyle = MapPickerStyle.satellite;
  bool _showPastMarkers = true;
  Map<String, PastLocationSpot> _pastSpots = {};
  PastLocationSpot? _selectedPastSpot;
  int _addressSessionId = 0;

  static const List<QuickCategoryConfig> _quickCategories = [
    QuickCategoryConfig(
      label: 'Fuel',
      icon: Icons.local_gas_station_rounded,
      color: Color(0xFFFF9800),
      osmTags: ['amenity=fuel'],
      categoryKeywords: [
        'fuel',
        'petrol',
        'gas',
        'diesel',
        'vehicles',
        'vehicle',
        'transport',
        'auto',
        'bunk',
        'cng',
        'ev charging',
      ],
      nameKeywords: [
        'fuel',
        'petrol',
        'shell',
        'hp',
        'hindustan petroleum',
        'indian oil',
        'bharat petroleum',
        'bpcl',
        'ioc',
        'iocl',
        'reliance petroleum',
        'nayara',
        'gas',
        'cng',
        'bunk',
        'essar',
      ],
      fallbackQuery: 'petrol',
    ),
    QuickCategoryConfig(
      label: 'Food',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE53935),
      osmTags: [
        'amenity=restaurant',
        'amenity=fast_food',
        'amenity=food_court',
      ],
      categoryKeywords: [
        'food',
        'dining',
        'food & dining',
        'restaurant',
        'eat',
        'dinner',
        'lunch',
        'breakfast',
        'meal',
        'hotel',
        'kitchen',
        'bistro',
        'cafe',
      ],
      nameKeywords: [
        'restaurant',
        'hotel',
        'kitchen',
        'bistro',
        'dhaba',
        'mess',
        'biryani',
        'burger',
        'pizza',
        'diner',
        'canteen',
        'grill',
        'eatery',
        'cafe',
        'treat',
        'bake',
      ],
      fallbackQuery: 'restaurant',
    ),
    QuickCategoryConfig(
      label: 'Cafe',
      icon: Icons.coffee_rounded,
      color: Color(0xFF8D6E63),
      osmTags: ['amenity=cafe', 'shop=coffee', 'shop=bakery'],
      categoryKeywords: [
        'cafe',
        'coffee',
        'tea',
        'snack',
        'beverage',
        'drink',
        'bakery',
        'bakes',
        'dessert',
      ],
      nameKeywords: [
        'cafe',
        'coffee',
        'tea',
        'starbucks',
        'ccd',
        'chai',
        'roast',
        'brew',
        'barista',
        'bakery',
        'bakes',
        'espresso',
      ],
      fallbackQuery: 'cafe',
    ),
    QuickCategoryConfig(
      label: 'Groceries',
      icon: Icons.shopping_basket_rounded,
      color: Color(0xFF4CAF50),
      osmTags: [
        'shop=supermarket',
        'shop=convenience',
        'shop=grocery',
        'shop=greengrocer',
      ],
      categoryKeywords: [
        'groceries',
        'grocery',
        'supermarket',
        'market',
        'daily',
        'provisions',
        'household',
        'vegetable',
        'fruit',
        'mart',
        'kirana',
      ],
      nameKeywords: [
        'mart',
        'store',
        'kirana',
        'fresh',
        'bazaar',
        'supermarket',
        'grocer',
        'grocery',
        'provision',
        'hypermarket',
        'reliance fresh',
        'more',
        'dmart',
        'nilgiris',
        'supplyco',
      ],
      fallbackQuery: 'supermarket',
    ),
    QuickCategoryConfig(
      label: 'ATM',
      icon: Icons.atm_rounded,
      color: Color(0xFF1E88E5),
      osmTags: ['amenity=atm', 'amenity=bank'],
      categoryKeywords: ['atm', 'bank', 'cash', 'finance', 'money', 'banking'],
      nameKeywords: [
        'atm',
        'bank',
        'sbi',
        'hdfc',
        'icici',
        'axis',
        'canara',
        'pnb',
        'bob',
        'federal bank',
        'south indian bank',
        'union bank',
        'kotak',
        'cash',
      ],
      fallbackQuery: 'atm',
    ),
    QuickCategoryConfig(
      label: 'Pharmacy',
      icon: Icons.local_pharmacy_rounded,
      color: Color(0xFF00BFA5),
      osmTags: [
        'amenity=pharmacy',
        'amenity=hospital',
        'amenity=clinic',
        'healthcare=pharmacy',
      ],
      categoryKeywords: [
        'pharmacy',
        'medical',
        'healthcare',
        'health',
        'medicine',
        'hospital',
        'clinic',
        'chemist',
        'druggist',
      ],
      nameKeywords: [
        'pharmacy',
        'medicals',
        'medical',
        'chemist',
        'apollo',
        'medplus',
        'druggist',
        'pharma',
        'clinic',
        'hospital',
        'aushadhi',
        'wellness',
      ],
      fallbackQuery: 'pharmacy',
    ),
    QuickCategoryConfig(
      label: 'Shopping',
      icon: Icons.storefront_rounded,
      color: Color(0xFFAB47BC),
      osmTags: ['shop=mall', 'shop=department_store', 'shop=clothes'],
      categoryKeywords: [
        'shopping',
        'mall',
        'store',
        'clothes',
        'clothing',
        'fashion',
        'retail',
        'electronics',
      ],
      nameKeywords: [
        'mall',
        'centre',
        'center',
        'trends',
        'zudio',
        'max',
        'pantaloons',
        'lifestyle',
        'shoppers stop',
        'reliance',
        'bazaar',
        'plaza',
      ],
      fallbackQuery: 'shopping mall',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedMapStyle();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _currentAddress = widget.initialLocationName ?? 'Saved Location';
      _selectedPoiName = widget.initialLocationName;
      _isLoadingLoc = false;
      _isFetchingAddress = false;
    } else {
      _initDeviceLocation();
    }
  }

  Future<void> _loadSavedMapStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('map_picker_style');
    if (saved != null && mounted) {
      setState(() {
        _mapStyle = MapPickerStyle.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => MapPickerStyle.satellite,
        );
      });
    }
  }

  int get _maxNativeZoom {
    switch (_mapStyle) {
      case MapPickerStyle.satellite:
        return 18;
      case MapPickerStyle.streets:
        return 19;
      case MapPickerStyle.terrain:
        return 15;
    }
  }

  double get _maxCameraZoom {
    switch (_mapStyle) {
      case MapPickerStyle.satellite:
        return 18.5;
      case MapPickerStyle.streets:
        return 19.5;
      case MapPickerStyle.terrain:
        return 15.5;
    }
  }

  Future<void> _changeMapStyle(MapPickerStyle style) async {
    HapticFeedback.selectionClick();
    setState(() => _mapStyle = style);

    // Auto-clamp current camera zoom so style never opens in blacked-out zoom depth
    double maxZ = 18.5;
    if (style == MapPickerStyle.terrain) maxZ = 15.5;
    if (style == MapPickerStyle.satellite) maxZ = 18.5;
    if (style == MapPickerStyle.streets) maxZ = 19.5;

    if (_mapController.camera.zoom > maxZ) {
      _mapController.move(_mapController.camera.center, maxZ);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_picker_style', style.name);
  }

  Map<String, PastLocationSpot> _computePastSpots(List<dynamic> allTxs) {
    if (allTxs.isEmpty) return _pastSpots;

    const Distance dist = Distance();
    final List<List<dynamic>> clusters = [];

    for (var txData in allTxs) {
      final t = txData.transaction;
      if (t.locationName != null &&
          t.locationName!.trim().isNotEmpty &&
          t.latitude != null &&
          t.longitude != null) {
        final pos = LatLng(t.latitude!, t.longitude!);
        final name = t.locationName!.trim().toLowerCase();

        bool added = false;
        for (var cluster in clusters) {
          final first = cluster.first.transaction;
          if (first.locationName!.trim().toLowerCase() == name) {
            final firstPos = LatLng(first.latitude!, first.longitude!);
            if (dist.as(LengthUnit.Meter, pos, firstPos) < 150) {
              cluster.add(txData);
              added = true;
              break;
            }
          }
        }
        if (!added) {
          clusters.add([txData]);
        }
      }
    }

    final Map<String, PastLocationSpot> spots = {};
    for (int i = 0; i < clusters.length; i++) {
      final list = clusters[i];
      final firstTx = list.first.transaction;
      double totalSpent = 0.0;
      for (var item in list) {
        final tx = item.transaction;
        if (tx.type == 'Expense') {
          totalSpent += tx.amount;
        }
      }

      final spotId =
          'past_spot_${i}_${firstTx.locationName!.trim().toLowerCase()}';
      spots[spotId] = PastLocationSpot(
        id: spotId,
        name: firstTx.locationName!.trim(),
        position: LatLng(firstTx.latitude!, firstTx.longitude!),
        count: list.length,
        totalSpent: totalSpent,
        primaryCategory: list.first.category?.name,
      );
    }

    return spots;
  }

  List<PastLocationSpot> _getNearbyPastSpots(
    LatLng point, {
    double radiusMeters = 30.0,
  }) {
    const Distance dist = Distance();
    final List<MapEntry<PastLocationSpot, double>> matches = [];
    for (var spot in _pastSpots.values) {
      final d = dist.as(LengthUnit.Meter, point, spot.position);
      if (d <= radiusMeters) {
        matches.add(MapEntry(spot, d));
      }
    }
    matches.sort((a, b) => a.value.compareTo(b.value));
    return matches.map((e) => e.key).toList();
  }

  void _onMarkerTap(PastLocationSpot spot) {
    HapticFeedback.mediumImpact();
    final nearby = _getNearbyPastSpots(spot.position, radiusMeters: 30.0);
    if (nearby.length <= 1) {
      _selectPastSpot(spot);
    } else {
      _showPastSpotsDisambiguationSheet(nearby, initialSelected: spot);
    }
  }

  void _handleMapTap(LatLng tapLatLng) {
    if (!_showPastMarkers || _pastSpots.isEmpty) return;
    final nearby = _getNearbyPastSpots(tapLatLng, radiusMeters: 25.0);
    if (nearby.isEmpty) return;

    HapticFeedback.selectionClick();
    if (nearby.length == 1) {
      _selectPastSpot(nearby.first);
    } else {
      _showPastSpotsDisambiguationSheet(nearby, initialSelected: nearby.first);
    }
  }

  void _showPastSpotsDisambiguationSheet(
    List<PastLocationSpot> spots, {
    PastLocationSpot? initialSelected,
  }) {
    HapticFeedback.selectionClick();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.58,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(
                            alpha: 0.15,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.layers_rounded,
                          size: 18,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Locations in this Area',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${spots.length} past pins found here. Choose one:',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    itemCount: spots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final spot = spots[index];
                      final bool isCurrent =
                          _selectedPastSpot?.id == spot.id ||
                          (initialSelected?.id == spot.id);

                      return Material(
                        color: isCurrent
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(ctx);
                            _selectPastSpot(spot);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFF00E5FF)
                                    : theme.dividerColor.withValues(alpha: 0.2),
                                width: isCurrent ? 1.6 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCurrent
                                          ? const Color(0xFF00E5FF)
                                          : Colors.white24,
                                      width: isCurrent ? 2 : 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    size: 16,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        spot.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isCurrent
                                              ? const Color(0xFF00E5FF)
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 6,
                                        children: [
                                          Text(
                                            '${spot.count} ${spot.count == 1 ? 'visit' : 'visits'}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          if (spot.totalSpent > 0) ...[
                                            Text(
                                              '•',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              '₹${CurrencyFormatter.format(spot.totalSpent)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF00E5FF),
                                              ),
                                            ),
                                          ],
                                          if (spot.primaryCategory != null &&
                                              spot
                                                  .primaryCategory!
                                                  .isNotEmpty) ...[
                                            Text(
                                              '•',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              spot.primaryCategory!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF00E5FF),
                                    size: 20,
                                  )
                                else
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                    size: 13,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (spots.isNotEmpty) {
                        _mapController.move(spots.first.position, 17.5);
                        setState(() {
                          _selectedPastSpot = null;
                          _selectedPoiName = null;
                          _isAddressManuallyEdited = false;
                          _subAddress = '';
                          _isFetchingAddress = true;
                        });
                        _debounceAddressFetch();
                      }
                    },
                    icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                    label: const Text(
                      'Pick as a New Location instead',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4285F4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initDeviceLocation() async {
    try {
      final locData = await LocationHelper.fetchCurrentLocation();
      if (locData != null && mounted) {
        setState(() {
          _center = LatLng(locData['latitude'], locData['longitude']);
        });
        await _resolveAddress(_center);
      }
    } catch (_) {
      await _resolveAddress(_center);
    } finally {
      if (mounted) setState(() => _isLoadingLoc = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    HapticFeedback.selectionClick();
    setState(() => _isFetchingCurrentLoc = true);
    try {
      final locData = await LocationHelper.fetchCurrentLocation();
      if (locData != null && mounted) {
        final pos = LatLng(locData['latitude'], locData['longitude']);
        _mapController.move(pos, 16.5);
        _selectedPoiName = null;
        _isAddressManuallyEdited = false;
        _debounceAddressFetch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not fetch location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isFetchingCurrentLoc = false);
    }
  }

  void _zoomIn() {
    HapticFeedback.selectionClick();
    final current = _mapController.camera.zoom;
    final maxZ = _maxCameraZoom;
    if (current >= maxZ) return;
    _mapController.move(
      _mapController.camera.center,
      (current + 1.0).clamp(3.0, maxZ),
    );
  }

  void _zoomOut() {
    HapticFeedback.selectionClick();
    final current = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (current - 1.0).clamp(3.0, _maxCameraZoom),
    );
  }

  bool _doesPastSpotMatchCategory(
    PastLocationSpot spot,
    QuickCategoryConfig cat,
  ) {
    final catName = (spot.primaryCategory ?? '').toLowerCase();
    final spotName = spot.name.toLowerCase();

    for (final kw in cat.categoryKeywords) {
      if (catName.contains(kw) || spotName.contains(kw)) return true;
    }
    for (final kw in cat.nameKeywords) {
      if (spotName.contains(kw)) return true;
    }
    return false;
  }

  void _onQuickCategoryPressed(QuickCategoryConfig cat) {
    HapticFeedback.selectionClick();
    _searchCtrl.text = cat.label;
    _onSearchChanged(cat.label, category: cat);
  }

  void _onSearchChanged(String rawQuery, {QuickCategoryConfig? category}) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    final query = rawQuery.trim();
    if (query.isEmpty) {
      _searchSessionId++;
      setState(() {
        _isSearching = false;
        _activeCategory = null;
        _searchResults = [];
      });
      return;
    }

    final currentSession = ++_searchSessionId;
    final pos = _mapController.camera.center;
    const Distance dist = Distance();

    // Check if query corresponds to a quick category
    QuickCategoryConfig? matchedCat = category;
    if (matchedCat == null) {
      final qLower = query.toLowerCase().trim();
      for (final c in _quickCategories) {
        if (c.label.toLowerCase() == qLower ||
            c.categoryKeywords.any(
              (kw) =>
                  qLower == kw ||
                  qLower.startsWith('$kw ') ||
                  qLower.endsWith(' $kw') ||
                  qLower.contains(' $kw '),
            )) {
          matchedCat = c;
          break;
        }
      }
    }
    final bool isCategorySearch = matchedCat != null;
    _activeCategory = matchedCat;

    // 1. Instant local search from past transaction spots (matches category or name)
    final List<Map<String, dynamic>> localMatches = [];
    for (var s in _pastSpots.values) {
      final bool isMatch = isCategorySearch
          ? _doesPastSpotMatchCategory(s, matchedCat)
          : s.name.toLowerCase().contains(query.toLowerCase());

      if (isMatch) {
        final meters = dist.as(LengthUnit.Meter, pos, s.position);
        final distanceText = meters < 1000
            ? '${meters.round()} m'
            : '${(meters / 1000).toStringAsFixed(1)} km';

        localMatches.add({
          'isLocal': true,
          'lat': s.position.latitude.toString(),
          'lon': s.position.longitude.toString(),
          'name': s.name,
          'display_name':
              '$distanceText • ${s.count} past txn${s.count > 1 ? 's' : ''}${s.totalSpent > 0 ? ' • ₹${CurrencyFormatter.format(s.totalSpent)}' : ''}',
          'distanceMeters': meters,
          'spot': s,
          'category': matchedCat,
        });
      }
    }

    localMatches.sort(
      (a, b) =>
          (a['distanceMeters'] as num).compareTo(b['distanceMeters'] as num),
    );

    if (currentSession == _searchSessionId && mounted) {
      setState(() {
        _isSearching = true;
        _searchResults = localMatches;
      });
    }

    // 2. Debounced online search
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final List<Map<String, dynamic>> remoteResults = [];

      if (isCategorySearch && matchedCat != null) {
        final QuickCategoryConfig catConfig = matchedCat;
        // Query OpenStreetMap Nominatim for all nearby amenities/shops under this category
        try {
          final zoom = _mapController.camera.zoom;
          // Scale search viewbox according to current map zoom
          double delta = (360.0 / math.pow(2, zoom)) * 1.5;
          if (delta < 0.08) delta = 0.08; // at least ~8.8 km radius
          if (delta > 0.35) delta = 0.35; // at most ~38 km radius

          final left = pos.longitude - delta;
          final right = pos.longitude + delta;
          final top = pos.latitude + delta;
          final bottom = pos.latitude - delta;

          // Query OSM tags for this category in parallel
          final List<Future<http.Response>> requests = [];
          for (final tag in catConfig.osmTags.take(3)) {
            final nomUrl = Uri.parse(
              'https://nominatim.openstreetmap.org/search?q=%5B${Uri.encodeComponent(tag)}%5D&viewbox=$left,$top,$right,$bottom&bounded=1&format=jsonv2&limit=25&addressdetails=1&extratags=1&namedetails=1',
            );
            requests.add(
              http
                  .get(nomUrl, headers: {'User-Agent': 'Budgetr_Expense_App'})
                  .timeout(const Duration(seconds: 4)),
            );
          }

          final responses = await Future.wait(requests);
          if (currentSession != _searchSessionId || !mounted) return;

          final Set<String> seenCoords = {};

          for (final nomResp in responses) {
            if (nomResp.statusCode == 200) {
              final List<dynamic> raw = jsonDecode(nomResp.body);
              for (var res in raw) {
                final lat = double.tryParse(res['lat'].toString()) ?? 0.0;
                final lon = double.tryParse(res['lon'].toString()) ?? 0.0;
                if (lat == 0.0 || lon == 0.0) continue;

                // Round to ~10 meters to deduplicate same place returned by multiple tags
                final coordKey =
                    '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
                if (!seenCoords.add(coordKey)) continue;

                String mainName = res['name']?.toString() ?? '';
                if (mainName.isEmpty && res['namedetails'] != null) {
                  final nd = res['namedetails'] as Map<String, dynamic>;
                  mainName =
                      (nd['name'] ?? nd['brand'] ?? nd['official_name'] ?? '')
                          .toString();
                }
                if (mainName.isEmpty && res['extratags'] != null) {
                  final et = res['extratags'] as Map<String, dynamic>;
                  mainName = (et['brand'] ?? et['operator'] ?? '').toString();
                }
                if (mainName.isEmpty && res['address'] != null) {
                  final addr = res['address'] as Map<String, dynamic>;
                  mainName =
                      (addr['amenity'] ??
                              addr['shop'] ??
                              addr['building'] ??
                              '')
                          .toString();
                }
                if (mainName.isEmpty) {
                  final firstLoc =
                      res['display_name']?.split(',').first?.trim() ?? '';
                  mainName = firstLoc.isNotEmpty
                      ? '${catConfig.label} ($firstLoc)'
                      : catConfig.label;
                }

                final meters = dist.as(LengthUnit.Meter, pos, LatLng(lat, lon));
                final distanceText = meters < 1000
                    ? '${meters.round()} m'
                    : '${(meters / 1000).toStringAsFixed(1)} km';

                remoteResults.add({
                  'isLocal': false,
                  'lat': lat.toString(),
                  'lon': lon.toString(),
                  'name': mainName,
                  'display_name':
                      '$distanceText • ${res['display_name'] ?? ''}',
                  'distanceMeters': meters,
                  'category': catConfig,
                });
              }
            }
          }
        } catch (_) {}

        // Fallback to Photon keyword search if Nominatim returned 0 items
        if (remoteResults.isEmpty) {
          try {
            final photonUrl = Uri.parse(
              'https://photon.komoot.io/api/?q=${Uri.encodeComponent(catConfig.fallbackQuery)}&lat=${pos.latitude}&lon=${pos.longitude}&limit=15',
            );
            final resp = await http
                .get(photonUrl, headers: {'User-Agent': 'Budgetr_Expense_App'})
                .timeout(const Duration(seconds: 4));

            if (currentSession != _searchSessionId || !mounted) return;

            if (resp.statusCode == 200) {
              final data = jsonDecode(resp.body);
              final features = data['features'] as List<dynamic>? ?? [];
              for (var f in features) {
                final coords = f['geometry']?['coordinates'] as List<dynamic>?;
                final props = f['properties'] as Map<String, dynamic>? ?? {};
                if (coords != null && coords.length >= 2) {
                  final lon = coords[0].toString();
                  final lat = coords[1].toString();
                  final itemPos = LatLng(double.parse(lat), double.parse(lon));
                  final meters = dist.as(LengthUnit.Meter, pos, itemPos);
                  final distanceText = meters < 1000
                      ? '${meters.round()} m'
                      : '${(meters / 1000).toStringAsFixed(1)} km';

                  final name =
                      props['name']?.toString() ??
                      props['street']?.toString() ??
                      catConfig.label;

                  final details =
                      [
                            props['street'],
                            props['city'] ?? props['town'] ?? props['district'],
                            props['state'],
                          ]
                          .where(
                            (e) =>
                                e != null &&
                                e.toString().isNotEmpty &&
                                e != name,
                          )
                          .join(', ');

                  remoteResults.add({
                    'isLocal': false,
                    'lat': lat,
                    'lon': lon,
                    'name': name,
                    'display_name': details.isNotEmpty
                        ? '$distanceText • $details'
                        : '$distanceText • ${props['country'] ?? ''}',
                    'distanceMeters': meters,
                    'category': catConfig,
                  });
                }
              }
            }
          } catch (_) {}
        }
      } else {
        // Standard text search via Photon
        try {
          final photonUrl = Uri.parse(
            'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&lat=${pos.latitude}&lon=${pos.longitude}&limit=12',
          );
          final resp = await http
              .get(photonUrl, headers: {'User-Agent': 'Budgetr_Expense_App'})
              .timeout(const Duration(seconds: 4));

          if (currentSession != _searchSessionId || !mounted) return;

          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            final features = data['features'] as List<dynamic>? ?? [];
            for (var f in features) {
              final coords = f['geometry']?['coordinates'] as List<dynamic>?;
              final props = f['properties'] as Map<String, dynamic>? ?? {};
              if (coords != null && coords.length >= 2) {
                final lon = coords[0].toString();
                final lat = coords[1].toString();
                final itemPos = LatLng(double.parse(lat), double.parse(lon));
                final meters = dist.as(LengthUnit.Meter, pos, itemPos);
                final distanceText = meters < 1000
                    ? '${meters.round()} m'
                    : '${(meters / 1000).toStringAsFixed(1)} km';

                final name =
                    props['name']?.toString() ??
                    props['street']?.toString() ??
                    'Place';

                final details =
                    [
                          props['street'],
                          props['city'] ?? props['town'] ?? props['district'],
                          props['state'],
                        ]
                        .where(
                          (e) =>
                              e != null && e.toString().isNotEmpty && e != name,
                        )
                        .join(', ');

                remoteResults.add({
                  'isLocal': false,
                  'lat': lat,
                  'lon': lon,
                  'name': name,
                  'display_name': details.isNotEmpty
                      ? '$distanceText • $details'
                      : '$distanceText • ${props['country'] ?? ''}',
                  'distanceMeters': meters,
                });
              }
            }
          }
        } catch (_) {}

        if (currentSession != _searchSessionId || !mounted) return;

        // Fallback to Nominatim text search
        if (remoteResults.isEmpty) {
          try {
            final left = pos.longitude - 0.8;
            final right = pos.longitude + 0.8;
            final top = pos.latitude + 0.8;
            final bottom = pos.latitude - 0.8;

            final nomUrl = Uri.parse(
              'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=jsonv2&addressdetails=1&limit=10&viewbox=$left,$top,$right,$bottom&bounded=0',
            );
            final nomResp = await http
                .get(nomUrl, headers: {'User-Agent': 'Budgetr_Expense_App'})
                .timeout(const Duration(seconds: 4));

            if (currentSession != _searchSessionId || !mounted) return;

            if (nomResp.statusCode == 200) {
              final List<dynamic> raw = jsonDecode(nomResp.body);
              for (var res in raw) {
                String mainName = res['name']?.toString() ?? '';
                if (mainName.isEmpty && res['address'] != null) {
                  final addr = res['address'];
                  mainName =
                      addr['amenity'] ??
                      addr['shop'] ??
                      addr['building'] ??
                      addr['tourism'] ??
                      addr['office'] ??
                      '';
                }
                if (mainName.isEmpty) {
                  mainName =
                      res['display_name']?.split(',').first ?? 'Unknown Place';
                }

                final lat = double.tryParse(res['lat'].toString()) ?? 0.0;
                final lon = double.tryParse(res['lon'].toString()) ?? 0.0;
                final meters = dist.as(LengthUnit.Meter, pos, LatLng(lat, lon));
                final distanceText = meters < 1000
                    ? '${meters.round()} m'
                    : '${(meters / 1000).toStringAsFixed(1)} km';

                remoteResults.add({
                  'isLocal': false,
                  'lat': res['lat'].toString(),
                  'lon': res['lon'].toString(),
                  'name': mainName,
                  'display_name':
                      '$distanceText • ${res['display_name'] ?? ''}',
                  'distanceMeters': meters,
                });
              }
            }
          } catch (_) {}
        }
      }

      if (currentSession != _searchSessionId || !mounted) return;

      // Sort remote results by proximity
      remoteResults.sort(
        (a, b) =>
            (a['distanceMeters'] as num).compareTo(b['distanceMeters'] as num),
      );

      setState(() {
        _isSearching = false;
        _searchResults = [...localMatches, ...remoteResults];
      });
    });
  }

  void _selectSearchResult(dynamic result) {
    FocusScope.of(context).unfocus();
    _searchDebounce?.cancel();
    _searchSessionId++;

    final lat = double.tryParse(result['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(result['lon']?.toString() ?? '') ?? 0.0;
    final pos = LatLng(lat, lon);

    _mapController.move(pos, 17.5);

    final name = result['name']?.toString() ?? 'Selected Location';
    final bool isLocal = result['isLocal'] == true;
    String sub = '';

    if (!isLocal && result['display_name'] != null) {
      final text = result['display_name'].toString();
      final parts = text.split('•');
      final clean = (parts.length > 1 ? parts.last : parts.first).trim();
      if (clean.toLowerCase().startsWith(name.toLowerCase())) {
        sub = clean.substring(name.length).replaceAll(RegExp(r'^[\s,]+'), '');
      } else {
        sub = clean;
      }
    }

    setState(() {
      _isSearching = false;
      _activeCategory = null;
      _selectedPastSpot = isLocal
          ? (result['spot'] as PastLocationSpot?)
          : null;
      _selectedPoiName = name;
      _currentAddress = name;
      _subAddress = sub;
      _isAddressManuallyEdited = false;
      _isFetchingAddress = isLocal;
      _searchResults = [];
      _searchCtrl.clear();
    });

    if (isLocal) {
      _resolveAddress(pos, preserveName: name);
    }
  }

  void _selectPastSpot(PastLocationSpot spot) {
    FocusScope.of(context).unfocus();
    _searchDebounce?.cancel();
    _searchSessionId++;

    _mapController.move(spot.position, 17.5);
    setState(() {
      _isSearching = false;
      _activeCategory = null;
      _selectedPastSpot = spot;
      _selectedPoiName = spot.name;
      _currentAddress = spot.name;
      _subAddress = '';
      _isAddressManuallyEdited = false;
      _isFetchingAddress = true;
      _searchResults = [];
      _searchCtrl.clear();
    });

    _resolveAddress(spot.position, preserveName: spot.name);
  }

  void _debounceAddressFetch() {
    if (_isAddressManuallyEdited) return;
    if (_addressDebounce?.isActive ?? false) _addressDebounce!.cancel();

    setState(() => _isFetchingAddress = true);
    _addressDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (mounted) setState(() => _isMoving = false);
      final pos = _mapController.camera.center;
      await _resolveAddress(pos);
    });
  }

  Future<void> _resolveAddress(LatLng pos, {String? preserveName}) async {
    final sessionId = ++_addressSessionId;

    // If an explicit name is preserved (selected past spot or search POI), lock it
    if (preserveName != null && preserveName.isNotEmpty) {
      String resolvedSecondary = '';
      try {
        final photonUrl = Uri.parse(
          'https://photon.komoot.io/reverse?lat=${pos.latitude}&lon=${pos.longitude}',
        );
        final response = await http
            .get(photonUrl, headers: {'User-Agent': 'Budgetr_Expense_App'})
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final features = data['features'] as List<dynamic>?;
          if (features != null && features.isNotEmpty) {
            final props =
                features.first['properties'] as Map<String, dynamic>? ?? {};
            resolvedSecondary = [
              props['street'],
              props['locality'] ?? props['district'],
              props['city'],
              props['state'],
              props['postcode'],
            ]
                .where((e) =>
                    e != null &&
                    e.toString().isNotEmpty &&
                    e.toString().toLowerCase() != preserveName.toLowerCase())
                .toSet()
                .join(', ');
          }
        }
      } catch (_) {}

      if (mounted && sessionId == _addressSessionId) {
        setState(() {
          _currentAddress = preserveName;
          _subAddress = resolvedSecondary;
          _isFetchingAddress = false;
        });
      }
      return;
    }

    // --- Google Maps-grade High Accuracy Multi-Source Reverse Geocoder ---
    String resolvedVenue = '';
    String resolvedStreet = '';
    String resolvedArea = '';
    String resolvedCity = '';
    String resolvedState = '';
    String resolvedPostcode = '';

    // 1. Parallel dispatch: Native Platform Geocoder + Nominatim (with POI details) + Photon
    final nativeFuture = () async {
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        ).timeout(const Duration(milliseconds: 3200));
        return placemarks.isNotEmpty ? placemarks.first : null;
      } catch (_) {
        return null;
      }
    }();

    final nominatimFuture = () async {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=jsonv2&zoom=18&addressdetails=1&extratags=1&namedetails=1',
        );
        final response = await http
            .get(url, headers: {'User-Agent': 'Budgetr_Expense_App'})
            .timeout(const Duration(milliseconds: 3200));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>?;
        }
      } catch (_) {}
      return null;
    }();

    final photonFuture = () async {
      try {
        final url = Uri.parse(
          'https://photon.komoot.io/reverse?lat=${pos.latitude}&lon=${pos.longitude}',
        );
        final response = await http
            .get(url, headers: {'User-Agent': 'Budgetr_Expense_App'})
            .timeout(const Duration(milliseconds: 3000));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final features = data['features'] as List<dynamic>?;
          if (features != null && features.isNotEmpty) {
            return features.first['properties'] as Map<String, dynamic>?;
          }
        }
      } catch (_) {}
      return null;
    }();

    final results = await Future.wait([nativeFuture, nominatimFuture, photonFuture]);
    if (!mounted || sessionId != _addressSessionId) return;

    final Placemark? nativePlace = results[0] as Placemark?;
    final Map<String, dynamic>? nomData = results[1] as Map<String, dynamic>?;
    final Map<String, dynamic>? photonProps = results[2] as Map<String, dynamic>?;

    // Helper: is a string a valid non-empty venue name (not plus-code, not generic)
    bool isMeaningfulVenue(String? s) {
      if (s == null) return false;
      final clean = s.trim();
      if (clean.isEmpty) return false;
      if (clean.contains('+')) return false; // Plus code
      if (RegExp(r'^[0-9\s,-]+$').hasMatch(clean)) return false; // Pure number / code
      if (clean.toLowerCase().contains('unnamed')) return false;
      if (clean.toLowerCase().contains('null')) return false;
      return true;
    }

    // Step A: Extract Tier-1 Exact Venue Name
    // 1. Nominatim exact POI / merchant / amenity / building
    if (nomData != null) {
      final addr = nomData['address'] as Map<String, dynamic>? ?? {};
      final namedetails = nomData['namedetails'] as Map<String, dynamic>? ?? {};
      final extratags = nomData['extratags'] as Map<String, dynamic>? ?? {};

      final candidatePoi = [
        nomData['name'],
        namedetails['name'],
        namedetails['name:en'],
        namedetails['brand'],
        extratags['brand'],
        extratags['operator'],
        extratags['building:name'],
        addr['amenity'],
        addr['shop'],
        addr['building'],
        addr['tourism'],
        addr['leisure'],
        addr['office'],
        addr['craft'],
        addr['healthcare'],
        addr['historic'],
      ].whereType<String>().map((e) => e.trim()).firstWhere(
            (name) => isMeaningfulVenue(name),
            orElse: () => '',
          );

      if (candidatePoi.isNotEmpty) {
        resolvedVenue = candidatePoi;
      }
    }

    // 2. Native Geocoder (Google Play Services Geocoder on Android)
    if (nativePlace != null) {
      final pName = nativePlace.name?.trim() ?? '';
      final pStreet = nativePlace.thoroughfare?.trim() ?? nativePlace.street?.trim() ?? '';
      final pLocality = nativePlace.locality?.trim() ?? '';
      final pSubLocality = nativePlace.subLocality?.trim() ?? '';

      // If place.name is distinct from street, locality, sublocality and not numeric,
      // Google Maps considers it the specific venue/place!
      if (isMeaningfulVenue(pName) &&
          pName.toLowerCase() != pStreet.toLowerCase() &&
          pName.toLowerCase() != pLocality.toLowerCase() &&
          pName.toLowerCase() != pSubLocality.toLowerCase()) {
        resolvedVenue = pName;
      }

      // Collect street & area context
      if (pStreet.isNotEmpty && resolvedStreet.isEmpty) resolvedStreet = pStreet;
      if (pSubLocality.isNotEmpty && resolvedArea.isEmpty) resolvedArea = pSubLocality;
      if (pLocality.isNotEmpty && resolvedCity.isEmpty) resolvedCity = pLocality;
      if ((nativePlace.administrativeArea ?? '').isNotEmpty && resolvedState.isEmpty) {
        resolvedState = nativePlace.administrativeArea!;
      }
      if ((nativePlace.postalCode ?? '').isNotEmpty && resolvedPostcode.isEmpty) {
        resolvedPostcode = nativePlace.postalCode!;
      }
    }

    // 3. Photon exact POI check (if still no venue)
    if (resolvedVenue.isEmpty && photonProps != null) {
      final osmKey = (photonProps['osm_key'] ?? '').toString().toLowerCase();
      final pName = (photonProps['name'] ?? '').toString().trim();
      const poiKeys = {
        'amenity', 'shop', 'tourism', 'building', 'leisure',
        'office', 'craft', 'historic', 'club', 'healthcare'
      };

      if (poiKeys.contains(osmKey) && isMeaningfulVenue(pName)) {
        resolvedVenue = pName;
      }
    }

    // Step B: Collect Street, Locality & City from Nominatim / Photon if missing
    if (nomData != null) {
      final addr = nomData['address'] as Map<String, dynamic>? ?? {};
      final road = addr['road'] ?? addr['street'] ?? addr['pedestrian'] ?? addr['footway'];
      final houseNumber = addr['house_number'] ?? addr['house_name'];
      final fullRoad = [houseNumber, road].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

      if (resolvedStreet.isEmpty && fullRoad.isNotEmpty) resolvedStreet = fullRoad;
      if (resolvedArea.isEmpty) {
        resolvedArea = addr['suburb'] ?? addr['neighbourhood'] ?? addr['quarter'] ?? addr['residential'] ?? '';
      }
      if (resolvedCity.isEmpty) {
        resolvedCity = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '';
      }
      if (resolvedState.isEmpty) resolvedState = addr['state'] ?? '';
      if (resolvedPostcode.isEmpty) resolvedPostcode = addr['postcode'] ?? '';
    }

    if (photonProps != null) {
      final pStreet = photonProps['street']?.toString() ?? '';
      final pHouse = photonProps['housenumber']?.toString() ?? '';
      final fullRoad = [pHouse, pStreet].where((e) => e.trim().isNotEmpty).join(' ');

      if (resolvedStreet.isEmpty && fullRoad.isNotEmpty) resolvedStreet = fullRoad;
      if (resolvedArea.isEmpty) {
        resolvedArea = photonProps['locality']?.toString() ?? photonProps['district']?.toString() ?? '';
      }
      if (resolvedCity.isEmpty) {
        resolvedCity = photonProps['city']?.toString() ?? '';
      }
      if (resolvedState.isEmpty) resolvedState = photonProps['state']?.toString() ?? '';
      if (resolvedPostcode.isEmpty) resolvedPostcode = photonProps['postcode']?.toString() ?? '';
    }

    // Step C: Determine Google Maps Style Primary Name
    String finalPrimary = '';
    if (resolvedVenue.isNotEmpty) {
      finalPrimary = resolvedVenue;
    } else if (resolvedStreet.isNotEmpty) {
      finalPrimary = resolvedStreet;
    } else if (resolvedArea.isNotEmpty) {
      finalPrimary = resolvedArea;
    } else if (resolvedCity.isNotEmpty) {
      finalPrimary = resolvedCity;
    } else {
      finalPrimary = 'Pinned Location';
    }

    // Step D: Assemble Google Maps Style Secondary Context (Address Line)
    final secondaryParts = <String>[];
    // If primary was a venue name, include the street in the secondary line
    if (resolvedVenue.isNotEmpty &&
        resolvedStreet.isNotEmpty &&
        resolvedStreet.toLowerCase() != finalPrimary.toLowerCase()) {
      secondaryParts.add(resolvedStreet);
    }
    if (resolvedArea.isNotEmpty &&
        resolvedArea.toLowerCase() != finalPrimary.toLowerCase()) {
      secondaryParts.add(resolvedArea);
    }
    if (resolvedCity.isNotEmpty &&
        resolvedCity.toLowerCase() != finalPrimary.toLowerCase()) {
      secondaryParts.add(resolvedCity);
    }
    if (resolvedState.isNotEmpty &&
        resolvedState.toLowerCase() != finalPrimary.toLowerCase()) {
      secondaryParts.add(resolvedState);
    }
    if (resolvedPostcode.isNotEmpty) {
      secondaryParts.add(resolvedPostcode);
    }

    // Clean deduplication
    final Set<String> seenParts = {};
    final cleanSecondary = secondaryParts.where((p) {
      final lower = p.trim().toLowerCase();
      if (lower.isEmpty ||
          lower == finalPrimary.toLowerCase() ||
          seenParts.contains(lower)) {
        return false;
      }
      seenParts.add(lower);
      return true;
    }).join(', ');

    if (mounted && sessionId == _addressSessionId) {
      setState(() {
        _currentAddress = finalPrimary;
        _subAddress = cleanSecondary;
        _isFetchingAddress = false;
      });
    }
  }

  void _editLocationNameManually() {
    HapticFeedback.lightImpact();
    final Map<String, LatLng> pastLocations = {};

    for (var spot in _pastSpots.values) {
      pastLocations[spot.name] = spot.position;
    }

    final TextEditingController editCtrl = TextEditingController(
      text: _currentAddress == 'Locating...' ? '' : _currentAddress,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = editCtrl.text.trim().toLowerCase();
            final List<String> suggestions = pastLocations.keys
                .where((name) => name.toLowerCase().contains(query))
                .take(6)
                .toList();

            final theme = Theme.of(context);

            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 12,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Edit Location Name',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (_subAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _subAddress,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: editCtrl,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (val) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter place or shop name...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: editCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  editCtrl.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            _currentAddress = value.trim();
                            _isAddressManuallyEdited = true;
                          });
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                    if (_selectedPoiName != null &&
                        _selectedPoiName!.isNotEmpty &&
                        _selectedPoiName != editCtrl.text.trim()) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          avatar: const Icon(Icons.undo_rounded, size: 13),
                          label: Text(
                            'Reset to detected: "$_selectedPoiName"',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            editCtrl.text = _selectedPoiName!;
                            setModalState(() {});
                          },
                        ),
                      ),
                    ],
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'SAVED PLACES & MERCHANTS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: suggestions.map((suggestion) {
                          final spot = _pastSpots.values
                              .cast<PastLocationSpot?>()
                              .firstWhere(
                                (s) =>
                                    s?.name.toLowerCase() ==
                                    suggestion.toLowerCase(),
                                orElse: () => null,
                              );
                          final int visitCount = spot?.count ?? 1;

                          return ActionChip(
                            avatar: Icon(
                              Icons.history_rounded,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              '$suggestion ($visitCount)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            backgroundColor: theme
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            side: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              final LatLng savedPos =
                                  pastLocations[suggestion]!;
                              _mapController.move(savedPos, 18.0);
                              setState(() {
                                _selectedPastSpot = spot;
                                _selectedPoiName = suggestion;
                                _currentAddress = suggestion;
                                _isAddressManuallyEdited = true;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (editCtrl.text.trim().isNotEmpty) {
                          setState(() {
                            _currentAddress = editCtrl.text.trim();
                            _isAddressManuallyEdited = true;
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Save Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMapStyleSheet() {
    HapticFeedback.selectionClick();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MAP TYPE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStyleOption(
                style: MapPickerStyle.satellite,
                title: 'Satellite Hybrid',
                subtitle:
                    'Real aerial satellite imagery with roads & business labels',
                icon: Icons.satellite_alt_rounded,
                theme: theme,
                isDark: isDark,
                ctx: ctx,
              ),
              const SizedBox(height: 8),
              _buildStyleOption(
                style: MapPickerStyle.streets,
                title: 'Roadmap View',
                subtitle:
                    'Clear vector street map with shops, landmarks & buildings',
                icon: Icons.map_rounded,
                theme: theme,
                isDark: isDark,
                ctx: ctx,
              ),
              const SizedBox(height: 8),
              _buildStyleOption(
                style: MapPickerStyle.terrain,
                title: 'Terrain View',
                subtitle:
                    'Topographic elevation map with roads & location labels',
                icon: Icons.terrain_rounded,
                theme: theme,
                isDark: isDark,
                ctx: ctx,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyleOption({
    required MapPickerStyle style,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    required BuildContext ctx,
  }) {
    final isSelected = _mapStyle == style;
    final color = isSelected
        ? (isDark ? const Color(0xFF00E5FF) : theme.colorScheme.primary)
        : theme.colorScheme.onSurface;

    return Material(
      color: isSelected
          ? (isDark
                ? const Color(0xFF00E5FF).withOpacity(0.12)
                : theme.colorScheme.primary.withOpacity(0.08))
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? color.withOpacity(0.7)
              : theme.dividerColor.withOpacity(0.3),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          _changeMapStyle(style);
          Navigator.pop(ctx);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.4,
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLocation() async {
    HapticFeedback.selectionClick();
    setState(() => _isConfirming = true);
    final pos = _mapController.camera.center;
    Navigator.pop(context, {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'name': _currentAddress,
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _addressDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Actively watch transactions so Riverpod maintains the stream listener across rebuilds
    final allTxs = ref.watch(allTransactionsProvider).asData?.value ?? [];
    if (allTxs.isNotEmpty || _pastSpots.isEmpty) {
      _pastSpots = _computePastSpots(allTxs);
    }

    // Check if current selected address matches any past spot
    PastLocationSpot? matchedPastSpot = _selectedPastSpot;
    if (matchedPastSpot == null &&
        _selectedPoiName != null &&
        _selectedPoiName!.isNotEmpty) {
      final query = _selectedPoiName!.trim().toLowerCase();
      for (var spot in _pastSpots.values) {
        if (spot.name.toLowerCase() == query) {
          matchedPastSpot = spot;
          break;
        }
      }
    }

    // Google Retina 2x tiles template with English labels
    final String tileUrl;
    final List<String> subdomains = const ['0', '1', '2', '3'];

    switch (_mapStyle) {
      case MapPickerStyle.satellite:
        // Google Satellite Hybrid: 512x512 Retina + Roads + Place POIs
        tileUrl =
            'https://mt{s}.google.com/vt/lyrs=y&scale=2&hl=en&x={x}&y={y}&z={z}';
        break;
      case MapPickerStyle.streets:
        // Google Roadmap: 512x512 Retina + full landmark & shop details
        tileUrl =
            'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=en&x={x}&y={y}&z={z}';
        break;
      case MapPickerStyle.terrain:
        // Google Terrain: 512x512 Retina + Topography + Labels
        tileUrl =
            'https://mt{s}.google.com/vt/lyrs=p&scale=2&hl=en&x={x}&y={y}&z={z}';
        break;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: 'Map Picker',
        subtitle: 'NAVIGATION',
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: _isLoadingLoc
          ? Center(
              child: FuturisticLoader(size: 80.0, label: 'INITIALIZING MAP...'),
            )
          : Stack(
              children: [
                // 1. Google High-Res Retina Map Layer
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15.5,
                    minZoom: 3.0,
                    maxZoom: _maxCameraZoom,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    onTap: (tapPosition, latLng) {
                      _handleMapTap(latLng);
                    },
                    onLongPress: (tapPosition, latLng) {
                      HapticFeedback.selectionClick();
                      _mapController.move(latLng, _mapController.camera.zoom);
                      setState(() {
                        _selectedPastSpot = null;
                        _selectedPoiName = null;
                        _isAddressManuallyEdited = false;
                        _subAddress = '';
                      });
                      _debounceAddressFetch();
                    },
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture) {
                        if (!_isMoving) {
                          setState(() => _isMoving = true);
                        }
                        if (_searchResults.isNotEmpty) {
                          FocusScope.of(context).unfocus();
                          setState(() => _searchResults = []);
                        }
                        setState(() {
                          _selectedPastSpot = null;
                          _selectedPoiName = null;
                          _isAddressManuallyEdited = false;
                          _subAddress = '';
                        });
                        _debounceAddressFetch();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      key: ValueKey('tile_layer_${_mapStyle.name}'),
                      urlTemplate: tileUrl,
                      fallbackUrl:
                          'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=en&x={x}&y={y}&z={z}',
                      subdomains: subdomains,
                      userAgentPackageName: 'com.example.budgetr',
                      maxNativeZoom: _maxNativeZoom,
                      maxZoom: _maxCameraZoom + 1.0,
                      keepBuffer: 3,
                      panBuffer: 1,
                      evictErrorTileStrategy: EvictErrorTileStrategy.none,
                    ),

                    // Past Transactions Marker Layer
                    if (_showPastMarkers && _pastSpots.isNotEmpty)
                      MarkerLayer(
                        markers: () {
                          const Distance dist = Distance();
                          // Precompute clusters (spots within 30m of each other)
                          final Map<String, int> clusterCounts = {};
                          for (var spot in _pastSpots.values) {
                            int count = 0;
                            for (var other in _pastSpots.values) {
                              if (dist.as(
                                    LengthUnit.Meter,
                                    spot.position,
                                    other.position,
                                  ) <=
                                  30.0) {
                                count++;
                              }
                            }
                            clusterCounts[spot.id] = count;
                          }

                          // Sort spots so the selected spot is drawn last (on top)
                          final sortedSpots = _pastSpots.values.toList()
                            ..sort((a, b) {
                              final aSelected =
                                  _selectedPastSpot?.id == a.id ||
                                  (matchedPastSpot?.id == a.id);
                              final bSelected =
                                  _selectedPastSpot?.id == b.id ||
                                  (matchedPastSpot?.id == b.id);
                              if (aSelected && !bSelected) return 1;
                              if (!aSelected && bSelected) return -1;
                              return 0;
                            });

                          return sortedSpots.map((spot) {
                            final isSelected =
                                _selectedPastSpot?.id == spot.id ||
                                (matchedPastSpot?.id == spot.id);
                            final int clusterCount =
                                clusterCounts[spot.id] ?? 1;
                            final bool hasCluster = clusterCount > 1;
                            const pinColor = Color(0xFF00E5FF);

                            return Marker(
                              point: spot.position,
                              width: 42,
                              height: 42,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _onMarkerTap(spot),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: isSelected ? 32 : 30,
                                      height: isSelected ? 32 : 30,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : pinColor,
                                          width: isSelected ? 2.8 : 1.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: pinColor.withValues(
                                              alpha: isSelected ? 0.75 : 0.35,
                                            ),
                                            blurRadius: isSelected ? 12 : 7,
                                            spreadRadius: isSelected ? 2 : 1,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        hasCluster
                                            ? Icons.layers_rounded
                                            : Icons.storefront_rounded,
                                        size: 15,
                                        color: pinColor,
                                      ),
                                    ),
                                    // Individual merchant visits count badge
                                    if (spot.count > 1 && !hasCluster)
                                      Positioned(
                                        right: -1,
                                        top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: pinColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            '${spot.count}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Cluster badge when multiple past pins are in the same area
                                    if (hasCluster)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF9100),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black38,
                                                blurRadius: 3,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.layers_rounded,
                                                size: 8,
                                                color: Colors.black,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '$clusterCount',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList();
                        }(),
                      ),

                    // Discovered Category POI Markers (Google Maps Style)
                    if (_searchResults.isNotEmpty)
                      MarkerLayer(
                        markers: _searchResults
                            .take(25)
                            .map((res) {
                              final lat =
                                  double.tryParse(
                                    res['lat']?.toString() ?? '',
                                  ) ??
                                  0.0;
                              final lon =
                                  double.tryParse(
                                    res['lon']?.toString() ?? '',
                                  ) ??
                                  0.0;
                              if (lat == 0.0 || lon == 0.0) return null;

                              final cat =
                                  (res['category'] as QuickCategoryConfig?) ??
                                  _activeCategory;
                              final pinColor =
                                  cat?.color ?? const Color(0xFF4285F4);
                              final isSelected =
                                  res['name']?.toString() == _selectedPoiName;

                              return Marker(
                                point: LatLng(lat, lon),
                                width: 34,
                                height: 34,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _selectSearchResult(res);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? pinColor
                                            : Colors.white70,
                                        width: isSelected ? 2.5 : 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: pinColor.withOpacity(0.4),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      cat?.icon ?? Icons.location_on_rounded,
                                      size: 16,
                                      color: isSelected
                                          ? pinColor
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .whereType<Marker>()
                            .toList(),
                      ),
                  ],
                ),

                // 2. Google Maps Animated Center Pin (with Lift & Drop effect)
                IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            offset: _isMoving
                                ? const Offset(0, -0.28)
                                : Offset.zero,
                            child: SizedBox(
                              width: 36,
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 42,
                                    color: Color(0xFFEA4335), // Google Maps Red
                                    shadows: [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 9,
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Ground drop shadow
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: _isMoving ? 8 : 12,
                            height: _isMoving ? 3 : 4,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                _isMoving ? 0.2 : 0.45,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Google Maps Style Search & Quick Categories
                Positioned(
                  top: DesignTokens.spacingMd,
                  left: DesignTokens.spacingLg,
                  right: DesignTokens.spacingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Floating Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.5 : 0.12,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search places, shops, or addresses...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.5),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF4285F4), // Google Blue
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSearching)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF4285F4),
                                            ),
                                      ),
                                    ),
                                  ),
                                if (_searchCtrl.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchDebounce?.cancel();
                                      _searchSessionId++;
                                      _searchCtrl.clear();
                                      setState(() {
                                        _isSearching = false;
                                        _activeCategory = null;
                                        _searchResults = [];
                                      });
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                              ],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      // Quick Category Carousel (Google Maps Style)
                      if (_searchResults.isEmpty && !_isSearching) ...[
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _quickCategories.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  avatar: Icon(
                                    cat.icon,
                                    size: 14,
                                    color: cat.color,
                                  ),
                                  label: Text(
                                    cat.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  backgroundColor: theme.colorScheme.surface
                                      .withOpacity(0.92),
                                  elevation: 2,
                                  side: BorderSide(
                                    color: cat.color.withOpacity(0.35),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  onPressed: () => _onQuickCategoryPressed(cat),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Searching Status Banner
                      if (_isSearching && _searchResults.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.5 : 0.15,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _activeCategory?.color ??
                                        const Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _activeCategory != null
                                      ? 'Finding all nearby ${_activeCategory!.label.toLowerCase()} locations...'
                                      : 'Searching places...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Search Results Dropdown (with Proximity Distance Ranking)
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.5 : 0.15,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, index) => Divider(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.35),
                            ),
                            itemBuilder: (context, index) {
                              final res = _searchResults[index];
                              final bool isLocal = res['isLocal'] == true;
                              final cat =
                                  res['category'] as QuickCategoryConfig?;
                              final pinColor = isLocal
                                  ? const Color(0xFF00E5FF)
                                  : (cat?.color ?? const Color(0xFF4285F4));
                              final pinIcon = isLocal
                                  ? Icons.history_rounded
                                  : (cat?.icon ?? Icons.location_on_rounded);

                              return ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: pinColor.withOpacity(0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    pinIcon,
                                    size: 16,
                                    color: pinColor,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        res['name'] ?? 'Unknown Place',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isLocal) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF00E5FF,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'PAST SPOT',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF00E5FF),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  res['display_name'] ?? '',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectSearchResult(res),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // 4. Floating Action Column (Map Type, Past Pins, Zoom +/- & My Location)
                Positioned(
                  bottom:
                      DesignTokens.spacingLg +
                      MediaQuery.of(context).padding.bottom +
                      84,
                  right: DesignTokens.spacingLg,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Layer Switcher
                      _buildFloatingButton(
                        icon: Icons.layers_rounded,
                        tooltip: 'Map Type',
                        theme: theme,
                        onPressed: _showMapStyleSheet,
                      ),
                      const SizedBox(height: 10),

                      // Toggle Past Pins
                      _buildFloatingButton(
                        icon: _showPastMarkers
                            ? Icons.pin_drop_rounded
                            : Icons.pin_drop_outlined,
                        tooltip: 'Toggle Past Pins',
                        theme: theme,
                        active: _showPastMarkers,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _showPastMarkers = !_showPastMarkers);
                        },
                      ),
                      const SizedBox(height: 10),

                      // Zoom Controls (Google Maps Desktop/Web style)
                      _buildFloatingButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Zoom In',
                        theme: theme,
                        onPressed: _zoomIn,
                      ),
                      const SizedBox(height: 6),
                      _buildFloatingButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Zoom Out',
                        theme: theme,
                        onPressed: _zoomOut,
                      ),
                      const SizedBox(height: 10),

                      // My Location FAB
                      _buildFloatingButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Current Location',
                        theme: theme,
                        isLoading: _isFetchingCurrentLoc,
                        onPressed: _isFetchingCurrentLoc
                            ? null
                            : _goToCurrentLocation,
                      ),
                    ],
                  ),
                ),

                // 5. Consolidated Google Maps Address & Confirm Card
                Positioned(
                  bottom:
                      DesignTokens.spacingLg +
                      MediaQuery.of(context).padding.bottom,
                  left: DesignTokens.spacingLg,
                  right: DesignTokens.spacingLg,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: _isAddressManuallyEdited
                          ? Border.all(
                              color: const Color(0xFF4285F4),
                              width: 1.5,
                            )
                          : Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.15),
                              width: 1,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.45 : 0.12,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            // Place Icon / Loading indicator
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _isFetchingAddress
                                    ? theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5)
                                    : (matchedPastSpot != null
                                          ? const Color(
                                              0xFF00E5FF,
                                            ).withValues(alpha: 0.14)
                                          : const Color(
                                              0xFFEA4335,
                                            ).withValues(alpha: 0.12)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: _isFetchingAddress
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF4285F4),
                                        ),
                                      )
                                    : Icon(
                                        matchedPastSpot != null
                                            ? Icons.storefront_rounded
                                            : Icons.place_rounded,
                                        size: 20,
                                        color: matchedPastSpot != null
                                            ? const Color(0xFF00E5FF)
                                            : const Color(0xFFEA4335),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Place Name & Sub-address (tap to edit)
                            Expanded(
                              child: GestureDetector(
                                onTap: _editLocationNameManually,
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _isFetchingAddress
                                                ? 'Locating place...'
                                                : _currentAddress,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  theme.colorScheme.onSurface,
                                              letterSpacing: -0.3,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 13,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                        ),
                                      ],
                                    ),
                                    if (_subAddress.isNotEmpty &&
                                        !_isFetchingAddress) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _subAddress,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.75),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Action / Confirm Button (compact tick icon)
                            Material(
                              color: _isFetchingAddress
                                  ? theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5)
                                  : const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: _isFetchingAddress
                                    ? null
                                    : _confirmLocation,
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 38,
                                  height: 38,
                                  child: Center(
                                    child: _isConfirming
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 21,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Productive Badges Row (Spend & Insights)
                        if (!_isFetchingAddress) ...[
                          const SizedBox(height: 8),
                          if (matchedPastSpot != null)
                            Row(
                              children: [
                                // Total Spent Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00E5FF,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF00E5FF,
                                      ).withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 11,
                                        color: Color(0xFF00E5FF),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '₹${CurrencyFormatter.format(matchedPastSpot.totalSpent)}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF00E5FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Visits Count Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.repeat_rounded,
                                        size: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${matchedPastSpot.count} ${matchedPastSpot.count == 1 ? 'visit' : 'visits'}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Category Badge (if available)
                                if (matchedPastSpot.primaryCategory != null &&
                                    matchedPastSpot
                                        .primaryCategory!
                                        .isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      matchedPastSpot.primaryCategory!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          else
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF4285F4,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.add_location_alt_rounded,
                                        size: 10,
                                        color: Color(0xFF4285F4),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'New Location',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF4285F4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap name to customize',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required ThemeData theme,
    required VoidCallback? onPressed,
    bool active = false,
    bool isLoading = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = isDark
        ? const Color(0xFF00E5FF)
        : theme.colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 42,
        width: 42,
        child: Material(
          color: active
              ? primaryAccent.withOpacity(isDark ? 0.2 : 0.12)
              : theme.colorScheme.surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: active
                  ? primaryAccent.withOpacity(0.5)
                  : theme.dividerColor.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryAccent,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 19,
                      color: active
                          ? primaryAccent
                          : theme.colorScheme.onSurface,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
