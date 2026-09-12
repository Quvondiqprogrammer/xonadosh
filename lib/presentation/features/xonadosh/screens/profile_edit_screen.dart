import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';

/// Alohida to'liq ekranli Xonadoshlik Anketasi
/// Ma'lumotlar yo'qolmasligi uchun PopScope va qoralama (draft) kesh tizimi bilan himoyalangan.
class XonadoshProfileEditScreen extends ConsumerStatefulWidget {
  const XonadoshProfileEditScreen({super.key, this.initialProfile});

  final XonadoshProfile? initialProfile;

  @override
  ConsumerState<XonadoshProfileEditScreen> createState() =>
      _XonadoshProfileEditScreenState();
}

class _XonadoshProfileEditScreenState
    extends ConsumerState<XonadoshProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _tgCtrl;
  late TextEditingController _facultyCtrl;
  late TextEditingController _aboutCtrl;
  late TextEditingController _lookingCtrl;

  String _gender = 'male';
  int _courseYear = 1;
  int _age = 20;
  double _budgetMin = 500000;
  double _budgetMax = 1500000;
  String _targetDistrict = 'Yunusobod';

  // Habits
  String _sleep = 'flexible';
  String _cleanliness = 'moderate';
  String _study = 'silent';
  String _cooking = 'rotates';
  String _smoking = 'no';
  final String _pets = 'no';
  final String _guests = 'sometimes';

  XonadoshUniversity? _selectedUni;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _isEditingExisting = false;

  static const String _draftKey = 'xonadosh_anketa_draft_v2';

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;

    _nameCtrl = TextEditingController(text: p?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: p?.phoneNumber ?? '');
    _tgCtrl = TextEditingController(text: p?.telegramHandle ?? '');
    _facultyCtrl = TextEditingController(text: p?.faculty ?? '');
    _aboutCtrl = TextEditingController(text: p?.aboutMe ?? '');
    _lookingCtrl = TextEditingController(text: p?.lookingForText ?? '');

    if (p != null) {
      _populateFromProfile(p);
      _isEditingExisting = true;
    } else {
      // Shaxsiy profil / Sessiyadan avto to'ldirish
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreExistingProfileOrDraft();
      });
    }

    _nameCtrl.addListener(_markChanged);
    _phoneCtrl.addListener(_markChanged);
    _tgCtrl.addListener(_markChanged);
    _facultyCtrl.addListener(_markChanged);
    _aboutCtrl.addListener(_markChanged);
    _lookingCtrl.addListener(_markChanged);
  }

  void _populateFromProfile(XonadoshProfile p) {
    _nameCtrl.text = p.fullName;
    _phoneCtrl.text = p.phoneNumber;
    _tgCtrl.text = p.telegramHandle ?? '';
    _facultyCtrl.text = p.faculty ?? '';
    _aboutCtrl.text = p.aboutMe;
    _lookingCtrl.text = p.lookingForText;
    _gender = p.gender;
    _courseYear = p.courseYear;
    _age = p.age;
    _budgetMin = p.budgetMin;
    _budgetMax = p.budgetMax;
    _targetDistrict = p.targetDistrict.isNotEmpty ? p.targetDistrict : 'Yunusobod';
    _sleep = p.sleepSchedule;
    _cleanliness = p.cleanliness;
    _study = p.studyHabit;
    _cooking = p.cookingHabit;
    _smoking = p.smokingHabit;
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    _autoSaveDraft();
  }

  Future<void> _restoreExistingProfileOrDraft() async {
    try {
      // 1. Check if user already has an active profile
      final repo = ref.read(xonadoshRepositoryProvider);
      final existing = ref.read(xonadoshMyProfileProvider).valueOrNull ??
          await repo.getMyProfile(ref.read(sessionManagerProvider).userId);

      if (existing != null && existing.fullName.isNotEmpty) {
        if (mounted) {
          setState(() {
            _populateFromProfile(existing);
            _isEditingExisting = true;
          });
        }
        return;
      }

      // 2. Otherwise restore draft if any
      final prefs = await SharedPreferences.getInstance();
      final draftStr = prefs.getString(_draftKey);
      if (draftStr != null && draftStr.isNotEmpty) {
        final Map<String, dynamic> draft = jsonDecode(draftStr);
        if (mounted) {
          setState(() {
            if (_nameCtrl.text.isEmpty && draft['full_name'] != null) {
              _nameCtrl.text = draft['full_name'];
            }
            if (_phoneCtrl.text.isEmpty && draft['phone_number'] != null) {
              _phoneCtrl.text = draft['phone_number'];
            }
            if (_tgCtrl.text.isEmpty && draft['telegram_handle'] != null) {
              _tgCtrl.text = draft['telegram_handle'];
            }
            if (_facultyCtrl.text.isEmpty && draft['faculty'] != null) {
              _facultyCtrl.text = draft['faculty'];
            }
            if (_aboutCtrl.text.isEmpty && draft['about_me'] != null) {
              _aboutCtrl.text = draft['about_me'];
            }
            if (_lookingCtrl.text.isEmpty && draft['looking_for_text'] != null) {
              _lookingCtrl.text = draft['looking_for_text'];
            }
            _gender = draft['gender'] ?? _gender;
            _age = draft['age'] ?? _age;
            _courseYear = draft['course_year'] ?? _courseYear;
            _budgetMin = (draft['budget_min'] as num?)?.toDouble() ?? _budgetMin;
            _budgetMax = (draft['budget_max'] as num?)?.toDouble() ?? _budgetMax;
            _sleep = draft['sleep_schedule'] ?? _sleep;
            _cleanliness = draft['cleanliness'] ?? _cleanliness;
            _study = draft['study_habit'] ?? _study;
            _cooking = draft['cooking_habit'] ?? _cooking;
            _smoking = draft['smoking_habit'] ?? _smoking;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _autoSaveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'full_name': _nameCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'telegram_handle': _tgCtrl.text.trim(),
        'gender': _gender,
        'age': _age,
        'university_id': _selectedUni?.id,
        'faculty': _facultyCtrl.text.trim(),
        'course_year': _courseYear,
        'budget_min': _budgetMin,
        'budget_max': _budgetMax,
        'target_district': _targetDistrict,
        'sleep_schedule': _sleep,
        'cleanliness': _cleanliness,
        'study_habit': _study,
        'cooking_habit': _cooking,
        'smoking_habit': _smoking,
        'about_me': _aboutCtrl.text.trim(),
        'looking_for_text': _lookingCtrl.text.trim(),
      };
      await prefs.setString(_draftKey, jsonEncode(draft));
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _tgCtrl.dispose();
    _facultyCtrl.dispose();
    _aboutCtrl.dispose();
    _lookingCtrl.dispose();
    super.dispose();
  }

  double _calculateCompleteness() {
    int total = 10;
    int filled = 0;

    if (_nameCtrl.text.trim().isNotEmpty) filled++;
    if (_phoneCtrl.text.trim().isNotEmpty) filled++;
    if (_tgCtrl.text.trim().isNotEmpty) filled++;
    if (_selectedUni != null) filled++;
    if (_facultyCtrl.text.trim().isNotEmpty) filled++;
    if (_budgetMax > 0) filled++;
    if (_aboutCtrl.text.trim().length >= 10) filled++;
    if (_lookingCtrl.text.trim().length >= 10) filled++;
    if (_sleep.isNotEmpty) filled++;
    if (_cleanliness.isNotEmpty) filled++;

    return filled / total;
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showError('Ism-familiyangizni kiriting');
        return false;
      }
      final phone = _phoneCtrl.text.trim();
      if (phone.isEmpty) {
        _showError('Telefon raqamingizni kiriting');
        return false;
      }
      if (phone.length < 7) {
        _showError("Telefon raqam to'liq kiritilmagan");
        return false;
      }
      return true;
    }
    if (step == 1) {
      if (_budgetMax < _budgetMin) {
        _showError("Maksimal byudjet minimal byudjetdan kam bo'lishi mumkin emas");
        return false;
      }
      return true;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _nextStep() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < 3) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _save();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _save() async {
    if (!_validateStep(0) || !_validateStep(1)) return;

    setState(() => _isLoading = true);

    final data = {
      'full_name': _nameCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      'telegram_handle': _tgCtrl.text.trim().replaceAll('@', ''),
      'gender': _gender,
      'age': _age,
      'university_id': _selectedUni?.id,
      'university_name': _selectedUni?.nameUz,
      'faculty': _facultyCtrl.text.trim(),
      'course_year': _courseYear,
      'budget_min': _budgetMin,
      'budget_max': _budgetMax,
      'target_district': _targetDistrict,
      'sleep_schedule': _sleep,
      'cleanliness': _cleanliness,
      'study_habit': _study,
      'cooking_habit': _cooking,
      'smoking_habit': _smoking,
      'pets_habit': _pets,
      'guests_habit': _guests,
      'about_me': _aboutCtrl.text.trim(),
      'status': 'looking',
    };

    final res = await ref.read(xonadoshRepositoryProvider).saveProfile(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['ok'] == true) {
      _hasUnsavedChanges = false;
      await _clearDraft();
      ref.invalidate(xonadoshMatchingRoommatesProvider);
      ref.invalidate(xonadoshMyProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isEditingExisting
                        ? '✅ Xonadoshlik anketangiz muvaffaqiyatli yangilandi!'
                        : '✅ Xonadoshlik anketangiz muvaffaqiyatli saqlandi!',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: XonaDoshColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      _showError(res['error']?.toString() ?? "Server xatoligi. Qaytadan urinib ko'ring.");
    }
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(context.l10n.xonadoshDeleteProfileTitle),
          ],
        ),
        content: Text(
          "Anketangiz o‘chirilsa, profilingiz nomzodlar ro‘yxatidan olinadi va boshqa talabalarga ko‘rinmaydi. Rozimisiz?",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.xonadoshDeleteProfileBtn),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    final repo = ref.read(xonadoshRepositoryProvider);
    await repo.deleteMyProfile();
    ref.invalidate(xonadoshMyProfileProvider);
    ref.invalidate(xonadoshMatchingRoommatesProvider);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(context.l10n.xonadoshProfileDeleted),
          ],
        ),
        backgroundColor: const Color(0xFF64748B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text(context.l10n.xonadoshWantToExitTitle),
          ],
        ),
        content: Text(
          "Kiritilgan ma'lumotlar qoralama holida saqlanadi. Anketani to'ldirishni keyinroq davom ettirishingiz mumkin.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.xonadoshStayBtn),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.xonadoshExitBtn),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _openUniversityPicker(List<XonadoshUniversity> unis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _UniversityPickerSheet(
        unis: unis,
        selectedId: _selectedUni?.id,
        onSelected: (u) {
          setState(() {
            _selectedUni = u;
            _hasUnsavedChanges = true;
          });
          _autoSaveDraft();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unisAsync = ref.watch(xonadoshUniversitiesProvider);
    final unis = unisAsync.valueOrNull ?? [];

    // Auto-match university if not yet selected
    if (_selectedUni == null && widget.initialProfile?.universityId != null && unis.isNotEmpty) {
      _selectedUni = unis.where((u) => u.id == widget.initialProfile!.universityId).firstOrNull;
    }

    final completeness = _calculateCompleteness();

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final ok = await _onWillPop();
        if (ok) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: context.l10n.commonBack,
            onPressed: () async {
              final navigator = Navigator.of(context);
              final ok = await _onWillPop();
              if (ok) {
                navigator.pop();
              }
            },
          ),
          title: Text(
            _isEditingExisting ? context.l10n.xonadoshSurveyEditTitle : context.l10n.xonadoshSurveyTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_isEditingExisting)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                tooltip: context.l10n.xonadoshDeleteProfileTitle,
                onPressed: _isLoading ? null : _deleteProfile,
              ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: XonaDoshColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: XonaDoshColors.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: XonaDoshColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    '${(completeness * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: XonaDoshColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Column(
              children: [
                // Step Indicator Pills
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      _buildStepTab(0, context.l10n.xonadoshSurveyStepPersonal, Icons.person_rounded),
                      const SizedBox(width: 6),
                      _buildStepTab(1, context.l10n.xonadoshSurveyStepUni, Icons.school_rounded),
                      const SizedBox(width: 6),
                      _buildStepTab(2, context.l10n.xonadoshSurveyStepHabits, Icons.nightlife_rounded),
                      const SizedBox(width: 6),
                      _buildStepTab(3, context.l10n.xonadoshSurveyStepReqs, Icons.checklist_rounded),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  backgroundColor: Colors.grey.withAlpha(30),
                  valueColor: const AlwaysStoppedAnimation<Color>(XonaDoshColors.primary),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (idx) => setState(() => _currentStep = idx),
            children: [
              _buildStep1Personal(isDark),
              _buildStep2UniversityAndBudget(isDark, unis),
              _buildStep3Habits(isDark),
              _buildStep4LookingAndSummary(isDark, completeness),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withAlpha(15),
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _prevStep,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(context.l10n.commonBack),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: XonaDoshColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _currentStep == 3
                                      ? (_isEditingExisting
                                          ? context.l10n.xonadoshSaveChanges
                                          : context.l10n.xonadoshSaveAndFind)
                                      : context.l10n.commonNext,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentStep == 3
                                    ? (_isEditingExisting ? Icons.save_rounded : Icons.check_circle_outline_rounded)
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTab(int index, String title, IconData icon) {
    final isActive = _currentStep == index;
    final isDone = _currentStep > index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? XonaDoshColors.primary.withAlpha(35)
                : isDone
                    ? XonaDoshColors.primary.withAlpha(20)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? XonaDoshColors.primary
                  : isDone
                      ? XonaDoshColors.primary.withAlpha(70)
                      : Colors.grey.withAlpha(40),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDone ? Icons.check_rounded : icon,
                size: 14,
                color: isActive
                    ? XonaDoshColors.primary
                    : isDone
                        ? XonaDoshColors.primary
                        : Colors.grey,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive || isDone ? FontWeight.w800 : FontWeight.w600,
                    color: isActive
                        ? XonaDoshColors.primary
                        : isDone
                            ? XonaDoshColors.primary
                            : Colors.grey,
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

  // ==========================================
  // STEP 1: Shaxsiy ma'lumotlar & Aloqa
  // ==========================================
  Widget _buildStep1Personal(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: context.l10n.xonadoshPersonalData,
            subtitle: context.l10n.xonadoshPersonalDataHint,
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 18),

          // Ism-familiya
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: context.l10n.xonadoshFullNameRequired,
              hintText: 'Masalan: Sardor Aliyev',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),

          // Jins & Yosh row
          Row(
            children: [
              // Jinsi
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jinsi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text(context.l10n.xonadoshGuy),
                            selected: _gender == 'male',
                            onSelected: (_) => setState(() => _gender = 'male'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(context.l10n.xonadoshGirl),
                            selected: _gender == 'female',
                            onSelected: (_) => setState(() => _gender = 'female'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Yoshi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yoshi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                          onPressed: _age > 16 ? () => setState(() => _age--) : null,
                        ),
                        Text('$_age', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          onPressed: _age < 60 ? () => setState(() => _age++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildSectionHeader(
            title: context.l10n.xonadoshContactMethods,
            subtitle: 'Mos xonadoshlar siz bilan to‘g‘ridan-to‘g‘ri bog‘lanishi uchun',
            icon: Icons.contact_phone_rounded,
          ),
          const SizedBox(height: 16),

          // Telefon
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: context.l10n.xonadoshPhoneRequired,
              hintText: '+998 90 123 45 67',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),

          // Telegram username
          TextFormField(
            controller: _tgCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.xonadoshTelegram,
              hintText: '@username',
              prefixIcon: const Icon(Icons.send_rounded, color: Color(0xFF0088CC)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: OTM, Kurs & Byudjet
  // ==========================================
  Widget _buildStep2UniversityAndBudget(bool isDark, List<XonadoshUniversity> unis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: context.l10n.xonadoshUniPlace,
            subtitle: 'Bir xil yoki yaqin universitet talabalari bilan birga yashash osonroq',
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 16),

          // Universitet tanlash kartasi
          InkWell(
            onTap: () => _openUniversityPicker(unis),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedUni != null ? XonaDoshColors.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: XonaDoshColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: XonaDoshColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedUni?.nameUz ?? context.l10n.xonadoshSelectUniversity,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _selectedUni != null ? null : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedUni != null)
                          Text(
                            '${_selectedUni!.district} • ${_selectedUni!.shortName}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            context.l10n.xonadoshSelectUniversity,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Fakultet
          TextFormField(
            controller: _facultyCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.xonadoshFaculty,
              hintText: 'Masalan: Dasturiy injiniring',
              prefixIcon: const Icon(Icons.menu_book_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),

          // Kurs tanlash
          Text(context.l10n.xonadoshCourseLevel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var yr = 1; yr <= 4; yr++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$yr-kurs'),
                      selected: _courseYear == yr,
                      onSelected: (_) => setState(() => _courseYear = yr),
                    ),
                  ),
                ChoiceChip(
                  label: Text(context.l10n.xonadoshMasterDegree),
                  selected: _courseYear == 5,
                  onSelected: (_) => setState(() => _courseYear = 5),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(context.l10n.xonadoshGraduateWorker),
                  selected: _courseYear == 6,
                  onSelected: (_) => setState(() => _courseYear = 6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            title: context.l10n.xonadoshMonthlyBudget,
            subtitle: context.l10n.xonadoshBudgetHint,
            icon: Icons.payments_rounded,
          ),
          const SizedBox(height: 16),

          // Byudjet ko'rsatkichi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withAlpha(40)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.xonadoshMinBudget, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            '${_formatMoney(_budgetMin)} ${context.l10n.currencyUzsSuffix}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: XonaDoshColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 18),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(context.l10n.xonadoshMaxBudget, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            '${_formatMoney(_budgetMax)} ${context.l10n.currencyUzsSuffix}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: XonaDoshColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RangeSlider(
                  values: RangeValues(_budgetMin, _budgetMax),
                  min: 300000,
                  max: 4000000,
                  divisions: 37,
                  activeColor: XonaDoshColors.primary,
                  onChanged: (vals) {
                    setState(() {
                      _budgetMin = vals.start;
                      _budgetMax = vals.end;
                    });
                    _markChanged();
                  },
                ),
                // Tezkor byudjet chiplari
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBudgetPresetChip('500k - 1M', 500000, 1000000),
                    _buildBudgetPresetChip('1M - 1.5M', 1000000, 1500000),
                    _buildBudgetPresetChip('1.5M - 2.5M', 1500000, 2500000),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPresetChip(String label, double min, double max) {
    final isSelected = _budgetMin == min && _budgetMax == max;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _budgetMin = min;
          _budgetMax = max;
        });
        _markChanged();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? XonaDoshColors.primary : Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 3: Odatlar & Hayot tarzi (Moslik)
  // ==========================================
  Widget _buildStep3Habits(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: context.l10n.xonadoshLifestyle,
            subtitle: 'Mos keluvchi xonadoshlarni aniqlash uchun',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 16),

          // Uyqu tartibi
          _buildHabitOptionGroup(
            title: context.l10n.xonadoshSleepSchedule,
            icon: Icons.bedtime_rounded,
            currentValue: _sleep,
            options: [
              ('early_bird', context.l10n.xonadoshSleepEarlyHours),
              ('night_owl', context.l10n.xonadoshSleepNightHours),
              ('flexible', context.l10n.xonadoshHabitFlexible),
            ],
            onChanged: (v) => setState(() => _sleep = v),
          ),
          const SizedBox(height: 16),

          // Tozalik & Tartib
          _buildHabitOptionGroup(
            title: context.l10n.xonadoshCleanliness,
            icon: Icons.cleaning_services_rounded,
            currentValue: _cleanliness,
            options: [
              ('strict', context.l10n.xonadoshHabitStrictClean),
              ('moderate', context.l10n.xonadoshHabitAverageClean),
              ('relaxed', context.l10n.xonadoshHabitRelaxedClean),
            ],
            onChanged: (v) => setState(() => _cleanliness = v),
          ),
          const SizedBox(height: 16),

          // Dars qilish
          _buildHabitOptionGroup(
            title: context.l10n.xonadoshStudyEnvironment,
            icon: Icons.menu_book_rounded,
            currentValue: _study,
            options: [
              ('silent', context.l10n.xonadoshHabitSilentStudy),
              ('music', context.l10n.xonadoshHabitMusicStudy),
              ('group', context.l10n.xonadoshHabitGroupStudy),
            ],
            onChanged: (v) => setState(() => _study = v),
          ),
          const SizedBox(height: 16),

          // Ovqat pishirish
          _buildHabitOptionGroup(
            title: context.l10n.xonadoshCooking,
            icon: Icons.soup_kitchen_rounded,
            currentValue: _cooking,
            options: [
              ('rotates', context.l10n.xonadoshHabitCookRotates),
              ('cooks_self', context.l10n.xonadoshHabitCookSelf),
              ('eats_out', context.l10n.xonadoshHabitEatOut),
            ],
            onChanged: (v) => setState(() => _cooking = v),
          ),
          const SizedBox(height: 16),

          // Chekish
          _buildHabitOptionGroup(
            title: context.l10n.xonadoshSmoking,
            icon: Icons.smoke_free_rounded,
            currentValue: _smoking,
            options: [
              ('no', context.l10n.xonadoshHabitIDontSmoke),
              ('balcony', context.l10n.xonadoshHabitBalconySmoke),
              ('yes', context.l10n.xonadoshHabitSmoker),
            ],
            onChanged: (v) => setState(() => _smoking = v),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitOptionGroup({
    required String title,
    required IconData icon,
    required String currentValue,
    required List<(String, String)> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: XonaDoshColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = currentValue == opt.$1;
            return ChoiceChip(
              label: Text(opt.$2),
              selected: isSelected,
              selectedColor: XonaDoshColors.primary.withAlpha(35),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected ? XonaDoshColors.primary : null,
              ),
              onSelected: (sel) {
                if (sel) {
                  HapticFeedback.selectionClick();
                  onChanged(opt.$1);
                  _markChanged();
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: Talablar & Saqlash
  // ==========================================
  Widget _buildStep4LookingAndSummary(bool isDark, double completeness) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: context.l10n.xonadoshLookingFor,
            subtitle: context.l10n.xonadoshAboutSelf,
            icon: Icons.rate_review_rounded,
          ),
          const SizedBox(height: 16),

          // O'zi haqida
          TextFormField(
            controller: _aboutCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.xonadoshAboutSelf,
              hintText: 'Qiziqishlaringiz, xarakteringiz, bo‘sh vaqtingiz haqida...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),

          // Qidirilayotgan xonadosh
          TextFormField(
            controller: _lookingCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.xonadoshLookingFor,
              hintText: 'Masalan: Tartibli, TATUda o‘qiydigan, IT sohasidagi yigitlar bo‘lsa yaxshi...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 24),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: XonaDoshColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.xonadoshSurveyStatus,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      context.l10n.xonadoshSurveyReadyPercent((completeness * 100).toInt()),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: XonaDoshColors.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isEditingExisting
                      ? context.l10n.xonadoshSurveySavedHint
                      : context.l10n.xonadoshSurveyNewHint,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (_isEditingExisting) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _deleteProfile,
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
              label: Text(
                context.l10n.xonadoshDeleteSearchStop,
                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
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
            color: XonaDoshColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: XonaDoshColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}

/// Searchable University Picker Bottom Sheet
class _UniversityPickerSheet extends StatefulWidget {
  const _UniversityPickerSheet({
    required this.unis,
    this.selectedId,
    required this.onSelected,
  });

  final List<XonadoshUniversity> unis;
  final int? selectedId;
  final ValueChanged<XonadoshUniversity> onSelected;

  @override
  State<_UniversityPickerSheet> createState() => _UniversityPickerSheetState();
}

class _UniversityPickerSheetState extends State<_UniversityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.unis.where((u) {
      final q = _query.toLowerCase();
      return u.nameUz.toLowerCase().contains(q) ||
          u.shortName.toLowerCase().contains(q) ||
          u.district.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.xonadoshSelectUniversity,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'OTM nomi, qisqartmasi yoki tumani bo‘yicha...',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final u = filtered[i];
                final isSelected = widget.selectedId == u.id;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? XonaDoshColors.primary
                          : XonaDoshColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 18,
                      color: isSelected ? Colors.white : XonaDoshColors.primary,
                    ),
                  ),
                  title: Text(
                    u.nameUz,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${u.district} • ${u.shortName}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: XonaDoshColors.primary)
                      : null,
                  onTap: () => widget.onSelected(u),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
