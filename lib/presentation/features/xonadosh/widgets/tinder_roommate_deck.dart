import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:xonadosh/presentation/common/contact_actions.dart';
import 'package:xonadosh/presentation/features/xonadosh/widgets/match_reasons.dart';
import 'package:xonadosh/presentation/features/xonadosh/widgets/roommate_photo_resolver.dart';

/// Tinder-Style Roommate Card Deck with natural swipe gestures and 4-action bar
class TinderRoommateDeck extends StatefulWidget {
  const TinderRoommateDeck({
    super.key,
    required this.candidates,
    required this.myProfile,
    required this.isDark,
    required this.onOpenDetail,
    this.onStartChat,
    this.onResetFilters,
  });

  final List<XonadoshProfile> candidates;
  final XonadoshProfile? myProfile;
  final bool isDark;
  final void Function(XonadoshProfile item) onOpenDetail;
  final void Function(XonadoshProfile item)? onStartChat;
  final VoidCallback? onResetFilters;

  @override
  State<TinderRoommateDeck> createState() => _TinderRoommateDeckState();
}

class _TinderRoommateDeckState extends State<TinderRoommateDeck>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isSwipingOut = false;

  late final AnimationController _animCtrl;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animCtrl.addListener(() {
      if (_slideAnimation != null) {
        setState(() => _dragOffset = _slideAnimation!.value);
      }
    });
    _animCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final didSwipe = _isSwipingOut;
        _isSwipingOut = false;
        _slideAnimation = null;
        _animCtrl.reset();
        setState(() {
          _dragOffset = Offset.zero;
          if (didSwipe) {
            _currentIndex++;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _swipe(bool isRight) {
    if (_animCtrl.isAnimating || _currentIndex >= widget.candidates.length) {
      return;
    }
    _isSwipingOut = true;
    HapticFeedback.mediumImpact();

    final endX = isRight ? 550.0 : -550.0;
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, _dragOffset.dy * 0.5),
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutQuad));
    _animCtrl.forward(from: 0.0);

    if (isRight) {
      _showMatchSnackBar(widget.candidates[_currentIndex]);
    }
  }

  void _rewind() {
    if (_animCtrl.isAnimating) return;
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex--;
        _dragOffset = Offset.zero;
      });
    }
  }

  void _showMatchSnackBar(XonadoshProfile candidate) {
    final score = candidate.compatibilityScore ?? 85;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${candidate.fullName} bilan $score% moslik saqlandi!',
                style: const TextStyle(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Aloqa',
          textColor: const Color(0xFF2DD4BF),
          onPressed: () {
            ContactActions.showContactSheet(
              context,
              phone: candidate.phoneNumber,
              telegramHandle: candidate.telegramHandle,
            );
          },
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_currentIndex >= widget.candidates.length) {
      return _buildDeckEmptyState();
    }

    final topItem = widget.candidates[_currentIndex];
    final nextItem = (_currentIndex + 1 < widget.candidates.length)
        ? widget.candidates[_currentIndex + 1]
        : null;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final cardWidth = math.min(screenWidth - 32, 420.0);
    final cardHeight = math.min(screenHeight * 0.58, 490.0).clamp(420.0, 510.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cardWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tinder Card Stack Container
            SizedBox(
              height: cardHeight,
              width: cardWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Background peek card (next candidate)
                  if (nextItem != null)
                    Positioned.fill(
                      child: Transform.scale(
                        scale: 0.94,
                        child: Transform.translate(
                          offset: const Offset(0, 12),
                          child: Opacity(
                            opacity: 0.85,
                            child: _buildCardContent(
                              item: nextItem,
                              isForeground: false,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 2. Foreground active swipeable card
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        if (!_animCtrl.isAnimating) {
                          widget.onOpenDetail(topItem);
                        }
                      },
                      onPanStart: (_) {},
                      onPanUpdate: (details) {
                        if (!_animCtrl.isAnimating) {
                          setState(() {
                            _dragOffset += details.delta;
                          });
                        }
                      },
                      onPanEnd: (details) {
                        if (_animCtrl.isAnimating) return;
                        final velocity = details.velocity.pixelsPerSecond.dx;
                        if (_dragOffset.dx > 85 || velocity > 380) {
                          _swipe(true);
                        } else if (_dragOffset.dx < -85 || velocity < -380) {
                          _swipe(false);
                        } else {
                          // Spring back to center
                          _isSwipingOut = false;
                          _slideAnimation =
                              Tween<Offset>(
                                begin: _dragOffset,
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animCtrl,
                                  curve: Curves.easeOutBack,
                                ),
                              );
                          _animCtrl.forward(from: 0.0);
                        }
                      },
                      child: Transform.translate(
                        offset: _dragOffset,
                        child: Transform.rotate(
                          angle: _dragOffset.dx * 0.0006,
                          child: Stack(
                            children: [
                              _buildCardContent(
                                item: topItem,
                                isForeground: true,
                              ),
                              // Swipe Stamp Indicators
                              if (_dragOffset.dx > 25)
                                _buildStamp(
                                  label: 'MOS KELDI',
                                  color: const Color(0xFF10B981),
                                  icon: Icons.favorite_rounded,
                                  opacity: math.min(1.0, _dragOffset.dx / 110),
                                  isLeft: false,
                                ),
                              if (_dragOffset.dx < -25)
                                _buildStamp(
                                  label: 'KEYINGISI',
                                  color: const Color(0xFFEF4444),
                                  icon: Icons.close_rounded,
                                  opacity: math.min(1.0, -_dragOffset.dx / 110),
                                  isLeft: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tinder 4-Action Ergonomic Bar
            _buildTinderActionBar(topItem),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent({
    required XonadoshProfile item,
    required bool isForeground,
  }) {
    final photoUrl = resolveProfilePhoto(item);
    final score = item.compatibilityScore ?? 85;
    final l10n = context.l10n;
    final badges = visibleVisualMatchBadges(
      candidate: item,
      me: widget.myProfile,
      l10n: l10n,
      limit: 3,
    );

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. High-Resolution Full Portrait Photo
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  buildStudentPhotoPlaceholder(
                    fullName: item.fullName,
                    isDark: widget.isDark,
                    size: 90,
                  ),
            ),

            // 2. Top Scrim for badges
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 110,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top-Left: Glowing Match Badge + University Chip
            Positioned(
              top: 14,
              left: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$score%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.universityShort != null &&
                      item.universityShort!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.universityShort} • ${item.courseYear}-kurs',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Top-Right: Info Icon Sheet Launcher
            Positioned(
              top: 14,
              right: 14,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onOpenDetail(item),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // 3. Bottom Gradient Scrim for Name and Lifestyle Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.92),
                      Colors.black.withValues(alpha: 0.72),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name & Age
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            item.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.age > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${item.age}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Uni & Faculty
                    Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _formatUni(item),
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // District & Budget
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            item.targetDistrict.isNotEmpty
                                ? item.targetDistrict
                                : "Toshkent",
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(
                          '  •  ',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatBudget(item),
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // "Why this match" / Nega mos?
                    Text(
                      l10n.xonadoshWhyMatch,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // 2-Word Visual Badges with Semantic Icons
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: badges.map((b) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: b.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: b.color.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(b.icon, size: 12, color: b.color),
                              const SizedBox(width: 4),
                              Text(
                                b.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStamp({
    required String label,
    required Color color,
    required IconData icon,
    required double opacity,
    required bool isLeft,
  }) {
    return Positioned(
      top: 40,
      left: isLeft ? null : 24,
      right: isLeft ? 24 : null,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: isLeft ? 0.2 : -0.2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 3),
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.45),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatUni(XonadoshProfile item) {
    final uni = item.universityName ?? item.universityShort ?? '';
    if (uni.isNotEmpty) {
      final faculty = item.faculty != null && item.faculty!.isNotEmpty
          ? ' • ${item.faculty}'
          : '';
      return '$uni$faculty';
    }
    return 'Talaba';
  }

  String _formatBudget(XonadoshProfile item) {
    if (item.budgetMin > 0 && item.budgetMax > 0) {
      return '${(item.budgetMin / 1000).toStringAsFixed(0)}k – ${(item.budgetMax / 1000).toStringAsFixed(0)}k so‘m';
    } else if (item.budgetMax > 0) {
      return '${(item.budgetMax / 1000).toStringAsFixed(0)}k so‘mgacha';
    } else if (item.budgetMin > 0) {
      return '${(item.budgetMin / 1000).toStringAsFixed(0)}k dan';
    }
    return 'Kelishiladi';
  }

  Widget _buildTinderActionBar(XonadoshProfile item) {
    final hasTelegram =
        item.telegramHandle != null && item.telegramHandle!.trim().isNotEmpty;
    final canRewind = _currentIndex > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Rewind Button (always present, disabled at index 0)
        IconButton.filledTonal(
          onPressed: canRewind ? _rewind : null,
          icon: const Icon(Icons.replay_rounded, size: 20),
          tooltip: 'Ortga qaytarish',
          style: IconButton.styleFrom(
            backgroundColor: canRewind
                ? const Color(0xFFF59E0B).withValues(alpha: 0.14)
                : Colors.grey.withValues(alpha: 0.08),
            foregroundColor: canRewind
                ? const Color(0xFFD97706)
                : Colors.grey.withValues(alpha: 0.4),
            minimumSize: const Size(46, 46),
            shape: const CircleBorder(),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Dislike / Pass Button
        IconButton.filledTonal(
          onPressed: () => _swipe(false),
          icon: const Icon(Icons.close_rounded, size: 26),
          tooltip: 'Keyingisi',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
            foregroundColor: const Color(0xFFEF4444),
            minimumSize: const Size(54, 54),
            shape: const CircleBorder(),
          ),
        ),

        const SizedBox(width: 12),

        // 3. Info / Detail Sheet Button
        IconButton.filledTonal(
          onPressed: () => widget.onOpenDetail(item),
          icon: const Icon(Icons.info_outline_rounded, size: 22),
          tooltip: 'Batafsil anketa',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
            foregroundColor: const Color(0xFF6366F1),
            minimumSize: const Size(48, 48),
            shape: const CircleBorder(),
          ),
        ),

        const SizedBox(width: 12),

        // 4. Telegram Button (always present, opens TG or contact sheet)
        IconButton.filledTonal(
          onPressed: () {
            if (hasTelegram) {
              ContactActions.openTelegram(context, item.telegramHandle);
            } else {
              ContactActions.showContactSheet(
                context,
                phone: item.phoneNumber,
                telegramHandle: null,
              );
            }
          },
          icon: const Icon(Icons.send_rounded, size: 19),
          tooltip: hasTelegram ? 'Telegram' : 'Aloqa',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
            foregroundColor: const Color(0xFF0284C7),
            minimumSize: const Size(44, 44),
            shape: const CircleBorder(),
          ),
        ),

        const SizedBox(width: 8),

        // 5. Direct Phone Call Button
        IconButton.filledTonal(
          onPressed: () {
            ContactActions.callPhone(context, item.phoneNumber);
          },
          icon: const Icon(Icons.call_rounded, size: 20),
          tooltip: 'Qo‘ng‘iroq',
          style: IconButton.styleFrom(
            backgroundColor: XonaDoshColors.primary.withValues(alpha: 0.12),
            foregroundColor: XonaDoshColors.primaryDark,
            minimumSize: const Size(44, 44),
            shape: const CircleBorder(),
          ),
        ),

        const SizedBox(width: 8),

        // 6. Primary In-App Chat / Match Button (Large Teal)
        IconButton.filled(
          onPressed: () {
            _swipe(true);
            if (widget.onStartChat != null) {
              widget.onStartChat!(item);
            } else {
              ContactActions.callPhone(context, item.phoneNumber);
            }
          },
          icon: const Icon(Icons.chat_bubble_rounded, size: 24),
          tooltip: 'Muloqot boshlash',
          style: IconButton.styleFrom(
            backgroundColor: XonaDoshColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(56, 56),
            elevation: 4,
            shadowColor: XonaDoshColors.primary.withValues(alpha: 0.4),
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            const Text(
              'Barcha nomzodlarni ko‘rdingiz!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Yangi talabalar qo‘shilganda bu yerda aks etadi yoki anketalarni qaytadan ko‘rishingiz mumkin.',
              style: TextStyle(
                fontSize: 13,
                color: widget.isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _currentIndex = 0;
                      _dragOffset = Offset.zero;
                    });
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Qaytadan ko‘rish'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (widget.onResetFilters != null) ...[
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: widget.onResetFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Filtrni tozalash'),
                    style: FilledButton.styleFrom(
                      backgroundColor: XonaDoshColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
