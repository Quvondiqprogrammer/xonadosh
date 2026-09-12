import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';
import 'xonadosh_create_recipe_sheet.dart';
import 'xonadosh_recipe_detail_sheet.dart';

class XonadoshRecipePickerSheet extends ConsumerStatefulWidget {
  final String dayOfWeek;
  final String mealTime;
  final String currentRecipeName;

  const XonadoshRecipePickerSheet({
    super.key,
    required this.dayOfWeek,
    required this.mealTime,
    required this.currentRecipeName,
  });

  @override
  ConsumerState<XonadoshRecipePickerSheet> createState() =>
      _XonadoshRecipePickerSheetState();
}

class _XonadoshRecipePickerSheetState
    extends ConsumerState<XonadoshRecipePickerSheet> {
  String _searchQuery = '';
  String _selectedCategory = 'Barchasi';

  static const _categories = [
    'Barchasi',
    'Milliy taom',
    'Talaba taomi',
    'Tezkor taom',
    'Suyuq taom',
    'Qovurma',
  ];

  String _formatDayName(String day) {
    final l10n = context.l10n;
    return switch (day.toLowerCase()) {
      'dushanba' => l10n.xonadoshDayMonday,
      'seshanba' => l10n.xonadoshDayTuesday,
      'chorshanba' => l10n.xonadoshDayWednesday,
      'payshanba' => l10n.xonadoshDayThursday,
      'juma' => l10n.xonadoshDayFriday,
      'shanba' => l10n.xonadoshDaySaturday,
      'yakshanba' => l10n.xonadoshDaySunday,
      _ => day,
    };
  }

  String _formatMealTime(String time) {
    final l10n = context.l10n;
    return switch (time.toLowerCase()) {
      'breakfast' => l10n.xonadoshBreakfast,
      'lunch' => l10n.xonadoshLunch,
      'dinner' => l10n.xonadoshDinner,
      _ => time,
    };
  }

  String _categoryLabel(String cat) {
    final l10n = context.l10n;
    return switch (cat) {
      'Barchasi' => l10n.commonAll,
      'Milliy taom' => l10n.xonadoshCatNational,
      'Talaba taomi' => l10n.xonadoshCatStudent,
      'Tezkor taom' => l10n.xonadoshCatQuick,
      'Suyuq taom' => l10n.xonadoshCatSoup,
      'Qovurma' => l10n.xonadoshCatFry,
      'Nonushta' => l10n.xonadoshBreakfast,
      _ => cat,
    };
  }

  Future<void> _selectRecipe(XonadoshRecipe recipe) async {
    final repo = ref.read(xonadoshRepositoryProvider);
    final ok = await repo.setMealPlan({
      'day_of_week': widget.dayOfWeek,
      'meal_time': widget.mealTime,
      'recipe_id': recipe.id,
      'recipe_name': recipe.nameUz,
      'cook_name': 'Xonadosh',
    });

    if (ok) {
      ref.invalidate(xonadoshRecipesAndMealPlanProvider);
      ref.invalidate(xonadoshGroceryCalculationProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.xonadoshMealPickedSnack(
                _formatDayName(widget.dayOfWeek),
                recipe.nameUz,
              ),
            ),
            backgroundColor: XonaDoshColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dataAsync = ref.watch(xonadoshRecipesAndMealPlanProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Header with Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: context.l10n.commonBack,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.xonadoshPickMealTitle(_formatDayName(widget.dayOfWeek)),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            context.l10n.xonadoshPickMealSubtitle(_formatMealTime(widget.mealTime)),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Create custom recipe action button
                    IconButton.filledTonal(
                      tooltip: context.l10n.xonadoshAddCustomMeal,
                      icon: const Icon(Icons.add_rounded, color: XonaDoshColors.primary),
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final created = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => XonadoshCreateRecipeSheet(
                            initialDay: widget.dayOfWeek,
                            initialMealTime: widget.mealTime,
                          ),
                        );
                        if (created == true && mounted) {
                          nav.pop(true);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: context.l10n.xonadoshSearchRecipeHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Category Filter Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSel = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(_categoryLabel(cat)),
                      selected: isSel,
                      selectedColor: XonaDoshColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setState(() => _selectedCategory = cat);
                      },
                    );
                  },
                ),
              ),

              const Divider(height: 20),

              // Recipes List
              Expanded(
                child: dataAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: XonaDoshColors.primary),
                  ),
                  error: (err, _) => Center(child: Text(context.l10n.xonadoshErrGeneric('$err'))),
                  data: (data) {
                    final filtered = data.recipes.where((r) {
                      final matchQuery = _searchQuery.isEmpty ||
                          r.nameUz.toLowerCase().contains(_searchQuery) ||
                          r.ingredients.any((i) => i.nameUz.toLowerCase().contains(_searchQuery));
                      final matchCat = _selectedCategory == 'Barchasi' ||
                          r.category.toLowerCase().contains(_selectedCategory.toLowerCase());
                      return matchQuery && matchCat;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.ramen_dining_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(context.l10n.xonadoshNoRecipeFound),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => XonadoshCreateRecipeSheet(
                                    initialDay: widget.dayOfWeek,
                                    initialMealTime: widget.mealTime,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: Text(context.l10n.xonadoshAddNewRecipeBtn),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final recipe = filtered[idx];
                        final isCurrentlySelected = recipe.nameUz.toLowerCase() == widget.currentRecipeName.toLowerCase();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCurrentlySelected
                                  ? XonaDoshColors.primary
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: isCurrentlySelected ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => XonadoshRecipeDetailSheet(recipe: recipe),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Recipe Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                                        ? Image.network(
                                            recipe.imageUrl!,
                                            width: 74,
                                            height: 74,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              width: 74,
                                              height: 74,
                                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                              child: const Icon(Icons.restaurant, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            width: 74,
                                            height: 74,
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                            child: const Icon(Icons.restaurant, color: Colors.grey),
                                          ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Recipe Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recipe.nameUz,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 2,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.timer_outlined, size: 13, color: Color(0xFFF59E0B)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${recipe.prepTimeMin} daq',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.group_outlined, size: 13, color: Color(0xFF3B82F6)),
                                                const SizedBox(width: 3),
                                                const Text(
                                                  '4-6 kishi',
                                                  style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.w700),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: XonaDoshColors.primary.withAlpha(20),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                recipe.costLevel == 'budget'
                                                    ? context.l10n.xonadoshBudgetFriendly
                                                    : context.l10n.xonadoshMediumBudget,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: XonaDoshColors.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          context.l10n.xonadoshIngredientCountLine(
                                            recipe.ingredients.length,
                                            recipe.ingredients.take(3).map((e) => e.nameUz).join(', '),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Select Action Button
                                  ElevatedButton(
                                    onPressed: () => _selectRecipe(recipe),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCurrentlySelected ? XonaDoshColors.primaryDark : XonaDoshColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(
                                      isCurrentlySelected ? context.l10n.xonadoshSelected : context.l10n.commonSelect,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
