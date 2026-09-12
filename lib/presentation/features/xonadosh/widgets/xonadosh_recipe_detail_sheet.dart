import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';

class XonadoshRecipeDetailSheet extends StatelessWidget {
  const XonadoshRecipeDetailSheet({
    super.key,
    required this.recipe,
    this.onAddToPlan,
  });

  final XonadoshRecipe recipe;
  final VoidCallback? onAddToPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header image / badge
            Stack(
              children: [
                if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      recipe.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildPlaceholderBanner(isDark),
                    ),
                  )
                else
                  _buildPlaceholderBanner(isDark),
                Positioned(
                  top: 12,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _categoryLabel(context, recipe.category),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      tooltip: context.l10n.commonClose,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.nameUz,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Stats Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: '${recipe.prepTimeMin} ${context.l10n.xonadoshEstimatedTimeMinutes}',
                        color: const Color(0xFF3B82F6),
                      ),
                      _StatChip(
                        icon: Icons.group_outlined,
                        label: context.l10n.xonadoshServingsRange,
                        color: XonaDoshColors.accentPurple,
                      ),
                      _StatChip(
                        icon: Icons.local_fire_department_rounded,
                        label: '${recipe.caloriesKcal} kkal',
                        color: const Color(0xFFFF6B6B),
                      ),
                      _StatChip(
                        icon: Icons.savings_outlined,
                        label: recipe.costLevel == 'budget'
                            ? context.l10n.xonadoshBudgetFriendly
                            : (recipe.costLevel == 'medium'
                                ? context.l10n.xonadoshMediumBudget
                                : context.l10n.xonadoshFestive),
                        color: XonaDoshColors.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Ingredients section
                  Text(
                    context.l10n.xonadoshIngredientsPerPerson,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: recipe.ingredients.map((ing) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: XonaDoshColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ing.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                ),
                              ),
                              Text(
                                '${ing.qtyPerPerson} ${ing.unit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Preparation instructions
                  Text(
                    context.l10n.xonadoshPrepOrder,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withAlpha(150) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      recipe.instructionsUz,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (onAddToPlan != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onAddToPlan!();
                        },
                        icon: const Icon(Icons.add_task_rounded),
                        label: Text(context.l10n.xonadoshAddToWeeklyMenu),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: XonaDoshColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(BuildContext context, String cat) {
    final l10n = context.l10n;
    return switch (cat) {
      'Milliy taom' => l10n.xonadoshCatNational,
      'Talaba taomi' => l10n.xonadoshCatStudent,
      'Tezkor taom' => l10n.xonadoshCatQuick,
      'Suyuq taom' => l10n.xonadoshCatSoup,
      'Qovurma' => l10n.xonadoshCatFry,
      'Nonushta' => l10n.xonadoshBreakfast,
      _ => cat,
    };
  }

  Widget _buildPlaceholderBanner(bool isDark) {
    return Container(
      height: 140,
      width: double.infinity,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      child: const Icon(Icons.restaurant_menu_rounded, size: 56, color: XonaDoshColors.primary),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
