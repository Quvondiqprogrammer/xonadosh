import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'package:xonadosh/presentation/router/app_routes.dart';
import '../data/xonadosh_locations.dart';

/// Professional, Multi-Region Full-Screen Xonadosh Listing Creation Screen
class XonadoshCreateListingScreen extends ConsumerStatefulWidget {
  const XonadoshCreateListingScreen({super.key});

  @override
  ConsumerState<XonadoshCreateListingScreen> createState() =>
      _XonadoshCreateListingScreenState();
}

class _XonadoshCreateListingScreenState
    extends ConsumerState<XonadoshCreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _addressController = TextEditingController();
  final _customDistrictController = TextEditingController();
  final _roomsController = TextEditingController(text: '2');
  final _floorController = TextEditingController(text: '3');
  final _totalFloorsController = TextEditingController(text: '5');
  final _areaController = TextEditingController(text: '65');
  final _photoUrlController = TextEditingController();

  String _type = 'rent';
  String _targetGender = 'any';
  String _currency = 'UZS';
  String _pricePeriod = 'month';

  XonadoshRegion _selectedRegion = XonadoshLocationData.regions.first;
  String _selectedDistrict = 'Yunusobod';
  bool _isCustomDistrict = false;

  XonadoshUniversity? _selectedUni;
  bool _isLoading = false;
  bool _uploadingPhoto = false;
  double? _latitude;
  double? _longitude;

  final List<String> _selectedAmenities = [
    'Wi-Fi',
    'Kir yuvish mashinasi',
    'Muzlatgich',
    'Issiq suv',
  ];

  final List<({String name, IconData icon})> _availableAmenities = [
    (name: 'Wi-Fi', icon: Icons.wifi_rounded),
    (name: 'Kir yuvish mashinasi', icon: Icons.local_laundry_service_rounded),
    (name: 'Muzlatgich', icon: Icons.kitchen_rounded),
    (name: 'Konditsioner', icon: Icons.ac_unit_rounded),
    (name: 'Gaz plita', icon: Icons.outdoor_grill_rounded),
    (name: 'Mebel', icon: Icons.chair_rounded),
    (name: 'Issiq suv', icon: Icons.water_drop_rounded),
    (name: 'Televizor', icon: Icons.tv_rounded),
    (name: 'Balkon', icon: Icons.balcony_rounded),
    (name: 'Domofon', icon: Icons.doorbell_rounded),
    (name: 'Avtoturargoh', icon: Icons.local_parking_rounded),
    (name: 'Avtonom isitish (Kotyol)', icon: Icons.fireplace_rounded),
    (name: 'Mikroto‘lqinli pech', icon: Icons.microwave_rounded),
    (name: 'Lift', icon: Icons.elevator_rounded),
    (name: 'Qo‘riqlash / Kamera', icon: Icons.security_rounded),
    (name: 'Basseyn', icon: Icons.pool_rounded),
  ];

  final List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    _photos.add(XonadoshLocationData.presetPhotos.first['url']!);
    _updateDefaultTitle();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _addressController.dispose();
    _customDistrictController.dispose();
    _roomsController.dispose();
    _floorController.dispose();
    _totalFloorsController.dispose();
    _areaController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _updateDefaultTitle() {
    if (_titleController.text.trim().isNotEmpty) return;
    switch (_type) {
      case 'rent':
        _titleController.text = '${_selectedDistrict}da ${_roomsController.text} xonali kvartira ijaraga beriladi';
        break;
      case 'roommate_wanted':
        _titleController.text = '${_selectedDistrict}da kvartiraga xonadosh (sherik) kerak';
        break;
      case 'sell':
        _titleController.text = '${_selectedDistrict}da ${_roomsController.text} xonali uy sotiladi';
        break;
      case 'buy':
        _titleController.text = '${_selectedDistrict}da ijara uchun shinam kvartira izlayapman';
        break;
    }
  }

  void _onRegionChanged(XonadoshRegion region) {
    setState(() {
      _selectedRegion = region;
      _isCustomDistrict = false;
      _selectedDistrict = region.districts.first;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.xonadoshFillRequiredFieldsSnack),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final finalDistrict = _isCustomDistrict
        ? _customDistrictController.text.trim()
        : _selectedDistrict;

    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'type': _type,
      'price': double.tryParse(_priceController.text.replaceAll(' ', '')) ?? 1000000,
      'currency': _currency,
      'price_period': _pricePeriod,
      'city': _selectedRegion.name,
      'district': finalDistrict,
      'address': _addressController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'telegram_handle': _telegramController.text.trim().replaceAll('@', ''),
      'nearest_university_id': _selectedUni?.id,
      'rooms_count': int.tryParse(_roomsController.text) ?? 2,
      'floor': int.tryParse(_floorController.text) ?? 1,
      'total_floors': int.tryParse(_totalFloorsController.text) ?? 4,
      'area_sqm': double.tryParse(_areaController.text) ?? 50.0,
      'target_gender': _targetGender,
      'amenities': _selectedAmenities,
      'photos': _photos.isNotEmpty ? _photos : [XonadoshLocationData.presetPhotos.first['url']!],
      'latitude': _latitude ?? _selectedUni?.latitude ?? 41.311081,
      'longitude': _longitude ?? _selectedUni?.longitude ?? 69.240562,
    };

    final repo = ref.read(xonadoshRepositoryProvider);
    final res = await repo.createListing(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['ok'] == true) {
      ref.invalidate(xonadoshListingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(context.l10n.xonadoshListingCreatedSuccess)),
            ],
          ),
          backgroundColor: XonaDoshColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go(AppRoutes.shell);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error']?.toString() ?? context.l10n.commonErrorOccurred),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _addCustomPhotoUrl() {
    final url = _photoUrlController.text.trim();
    if (url.isNotEmpty && !_photos.contains(url)) {
      setState(() {
        _photos.add(url);
        _photoUrlController.clear();
      });
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    if (_uploadingPhoto) return;
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _uploadingPhoto = true);
      final bytes = await file.readAsBytes();
      final name = file.name.isNotEmpty
          ? file.name
          : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final repo = ref.read(xonadoshRepositoryProvider);
      final url = await repo.uploadPhoto(bytes: bytes, filename: name);

      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        setState(() {
          if (!_photos.contains(url)) _photos.add(url);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.xonadoshPhotoUploadFailed)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.xonadoshPhotoUploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _useMyLocation() async {
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
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.xonadoshUseMyLocation}: '
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.xonadoshLocationFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unisAsync = ref.watch(xonadoshUniversitiesProvider);
    final unis = unisAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.l10n.xonadoshCreateListingTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: XonaDoshColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: XonaDoshColors.primary.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public_rounded, size: 14, color: XonaDoshColors.primary),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    context.l10n.xonadoshGlobalUzbekistan,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: XonaDoshColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 1. E'LON TURI (CATEGORY / TYPE)
              // ==========================================
              _buildSectionHeader(
                title: context.l10n.xonadoshStep1Title,
                subtitle: context.l10n.xonadoshStep1Subtitle,
                icon: Icons.category_rounded,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeChip('rent', context.l10n.xonadoshTypeRentHome, Icons.home_rounded),
                  const SizedBox(width: 8),
                  _buildTypeChip('roommate_wanted', context.l10n.xonadoshTypeRoommate, Icons.people_rounded),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChip('sell', context.l10n.xonadoshTypeForSale, Icons.sell_rounded),
                  const SizedBox(width: 8),
                  _buildTypeChip('buy', context.l10n.xonadoshTypeLookingRent, Icons.search_rounded),
                ],
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 2. JOYLASHUV VA MANZIL (REGIONS & DISTRICTS)
              // ==========================================
              _buildSectionHeader(
                title: context.l10n.xonadoshStep2Title,
                subtitle: context.l10n.xonadoshStep2Subtitle,
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 12),

              // Viloyat / Mamlakat tanlash
              DropdownButtonFormField<XonadoshRegion>(
                initialValue: _selectedRegion,
                decoration: InputDecoration(
                  labelText: context.l10n.xonadoshSelectRegionReq,
                  prefixIcon: const Icon(Icons.map_rounded, color: XonaDoshColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                isExpanded: true,
                items: XonadoshLocationData.regions.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(
                      '${r.flag} ${r.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (r) {
                  if (r != null) _onRegionChanged(r);
                },
              ),
              const SizedBox(height: 14),

              // Tuman / Shahar tanlash yoki Erkin kiritish
              if (!_isCustomDistrict) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedDistrict,
                  decoration: InputDecoration(
                    labelText: context.l10n.xonadoshSelectDistrictReq,
                    prefixIcon: const Icon(Icons.location_city_rounded, color: XonaDoshColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  isExpanded: true,
                  items: [
                    ..._selectedRegion.districts.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(d, style: const TextStyle(fontSize: 14)),
                      );
                    }),
                    DropdownMenuItem(
                      value: '__custom__',
                      child: Text(
                        context.l10n.xonadoshOtherDistrictWrite,
                        style: const TextStyle(color: XonaDoshColors.accentPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  onChanged: (d) {
                    if (d == '__custom__') {
                      setState(() => _isCustomDistrict = true);
                    } else if (d != null) {
                      setState(() => _selectedDistrict = d);
                    }
                  },
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customDistrictController,
                        decoration: InputDecoration(
                          labelText: context.l10n.xonadoshEnterDistrictName,
                          hintText: context.l10n.xonadoshDistrictExampleHint,
                          prefixIcon: const Icon(Icons.edit_location_alt_rounded, color: XonaDoshColors.accentPurple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => _isCustomDistrict && (v == null || v.trim().isEmpty)
                            ? context.l10n.xonadoshEnterDistrictName
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _isCustomDistrict = false),
                      tooltip: context.l10n.xonadoshBackToListSelection,
                      icon: const Icon(Icons.list_rounded),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              // Aniq manzil / Mo'ljal
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: context.l10n.xonadoshAddressReq,
                  hintText: context.l10n.xonadoshAddressHint,
                  prefixIcon: const Icon(Icons.pin_drop_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? context.l10n.xonadoshEnterAddress : null,
              ),
              const SizedBox(height: 14),

              // Yaqin OTM (Ixtiyoriy)
              if (unis.isNotEmpty) ...[
                DropdownButtonFormField<XonadoshUniversity>(
                  initialValue: _selectedUni,
                  decoration: InputDecoration(
                    labelText: context.l10n.xonadoshUniOptionalLabel,
                    prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: null, child: Text(context.l10n.xonadoshUniNotLinked)),
                    ...unis.map((u) => DropdownMenuItem(
                          value: u,
                          child: Text('${u.shortName} (${u.district})'),
                        )),
                  ],
                  onChanged: (u) => setState(() => _selectedUni = u),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 10),

              // ==========================================
              // 3. SARLAVHA, NARX VA VALYUTA
              // ==========================================
              _buildSectionHeader(
                title: context.l10n.xonadoshStep3Title,
                subtitle: context.l10n.xonadoshStep3Subtitle,
                icon: Icons.payments_rounded,
              ),
              const SizedBox(height: 12),

              // Sarlavha
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.l10n.xonadoshListingTitleReq,
                  hintText: context.l10n.xonadoshListingTitleHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? context.l10n.xonadoshEnterTitle : null,
              ),
              const SizedBox(height: 14),

              // Narx va Valyuta tanlagich
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.l10n.xonadoshPriceRequired,
                        hintText: '1 200 000',
                        prefixIcon: const Icon(Icons.price_change_outlined),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? context.l10n.xonadoshEnterPrice : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.xonadoshCurrency,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: XonadoshLocationData.availableCurrencies.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            '$c (${XonadoshLocationData.currencySymbols[c]})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (c) {
                        if (c != null) setState(() => _currency = c);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // To'lov davri
              DropdownButtonFormField<String>(
                initialValue: _pricePeriod,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n.xonadoshPaymentPeriod,
                  prefixIcon: const Icon(Icons.calendar_month_rounded),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: XonadoshLocationData.pricePeriods.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(
                      XonadoshLocationData.pricePeriodLabels[p] ?? p,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (p) {
                  if (p != null) setState(() => _pricePeriod = p);
                },
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 4. XONALAR, QAVAT VA AUDITORIYA
              // ==========================================
              _buildSectionHeader(
                title: context.l10n.xonadoshStep4Title,
                subtitle: context.l10n.xonadoshStep4Subtitle,
                icon: Icons.apartment_rounded,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roomsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.l10n.xonadoshRoomsCount,
                        hintText: '2',
                        prefixIcon: const Icon(Icons.meeting_room_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _areaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.l10n.xonadoshAreaSqM,
                        hintText: '65',
                        prefixIcon: const Icon(Icons.square_foot_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.l10n.xonadoshFloor,
                        hintText: '3',
                        prefixIcon: const Icon(Icons.layers_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _totalFloorsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.l10n.xonadoshTotalFloors,
                        hintText: '9',
                        prefixIcon: const Icon(Icons.apartment_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Kim uchun
              Text(context.l10n.xonadoshTargetAudience, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAudienceChip('any', context.l10n.xonadoshAudienceAll),
                  _buildAudienceChip('boys', context.l10n.xonadoshAudienceBoys),
                  _buildAudienceChip('girls', context.l10n.xonadoshAudienceGirls),
                  _buildAudienceChip('family', context.l10n.xonadoshAudienceFamily),
                ],
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 5. SURATLAR (PHOTOS & PRESETS)
              // ==========================================
              _buildSectionHeader(
                title: context.l10n.xonadoshStep5Title,
                subtitle: context.l10n.xonadoshStep5Subtitle,
                icon: Icons.photo_library_rounded,
              ),
              const SizedBox(height: 12),

              // Presets Carousel
              SizedBox(
                height: 105,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: XonadoshLocationData.presetPhotos.length,
                  itemBuilder: (context, idx) {
                    final item = XonadoshLocationData.presetPhotos[idx];
                    final isSelected = _photos.contains(item['url']);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _photos.remove(item['url']);
                          } else {
                            _photos.add(item['url']!);
                          }
                        });
                      },
                      child: Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? XonaDoshColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item['url']!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Icon(Icons.apartment_rounded, color: Colors.white54),
                                ),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Colors.black87],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: CircleAvatar(
                                    radius: 11,
                                    backgroundColor: XonaDoshColors.primary,
                                    child: Icon(Icons.check, size: 14, color: Colors.white),
                                  ),
                                ),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                right: 6,
                                child: Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Galereya / kamera (web + mobil)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingPhoto
                          ? null
                          : () => _pickAndUploadPhoto(ImageSource.gallery),
                      icon: _uploadingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                        _uploadingPhoto
                            ? context.l10n.xonadoshUploadingPhoto
                            : context.l10n.xonadoshPickFromGallery,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingPhoto
                          ? null
                          : () => _pickAndUploadPhoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(context.l10n.xonadoshTakePhoto),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _useMyLocation,
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(
                    _latitude != null
                        ? '${context.l10n.xonadoshUseMyLocation} ✓'
                        : context.l10n.xonadoshUseMyLocation,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Rasm URL kiritish
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _photoUrlController,
                      decoration: InputDecoration(
                        labelText: context.l10n.xonadoshPhotoUrlOptional,
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.link_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addCustomPhotoUrl,
                    tooltip: context.l10n.xonadoshAdd,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: XonaDoshColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 6. QULAYLIKLAR & JIXOZLAR (AMENITIES)
              // ==========================================
              _buildSectionHeader(
                title: context.l10n.xonadoshStep6Title,
                subtitle: context.l10n.xonadoshStep6Subtitle,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAmenities.map((item) {
                  final isSelected = _selectedAmenities.contains(item.name);
                  return FilterChip(
                    avatar: Icon(
                      item.icon,
                      size: 16,
                      color: isSelected ? XonaDoshColors.primary : Colors.grey,
                    ),
                    label: Text(item.name),
                    selected: isSelected,
                    selectedColor: XonaDoshColors.primary.withAlpha(25),
                    checkmarkColor: XonaDoshColors.primary,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(item.name);
                        } else {
                          _selectedAmenities.remove(item.name);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 7. ALOQA MA'LUMOTLARI VA TAVSIF
              // ==========================================
              _buildSectionHeader(
                title: context.l10n.xonadoshStep7Title,
                subtitle: context.l10n.xonadoshStep7Subtitle,
                icon: Icons.contact_phone_rounded,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: context.l10n.xonadoshPhoneRequired,
                        hintText: '+998 90 123 45 67',
                        prefixIcon: const Icon(Icons.phone_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? context.l10n.xonadoshEnterPhone : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _telegramController,
                      decoration: InputDecoration(
                        labelText: context.l10n.xonadoshTelegram,
                        hintText: '@username',
                        prefixIcon: const Icon(Icons.send_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.l10n.xonadoshDetailedDesc,
                  hintText: context.l10n.xonadoshDetailedDescHint,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 28),

              // ==========================================
              // JOYLASH TUGMASI
              // ==========================================
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: XonaDoshColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_home_rounded, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              context.l10n.xonadoshPublishListing,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: XonaDoshColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: XonaDoshColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _type = type;
            _updateDefaultTitle();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? XonaDoshColors.primary : Colors.grey.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? XonaDoshColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceChip(String genderKey, String label) {
    final isSelected = _targetGender == genderKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: XonaDoshColors.primary.withAlpha(25),
      onSelected: (_) {
        setState(() => _targetGender = genderKey);
      },
    );
  }
}
