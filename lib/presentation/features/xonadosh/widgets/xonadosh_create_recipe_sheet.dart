import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';

class XonadoshCreateRecipeSheet extends ConsumerStatefulWidget {
  final String? initialDay;
  final String? initialMealTime;

  const XonadoshCreateRecipeSheet({
    super.key,
    this.initialDay,
    this.initialMealTime,
  });

  @override
  ConsumerState<XonadoshCreateRecipeSheet> createState() =>
      _XonadoshCreateRecipeSheetState();
}

class _IngredientRow {
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  String unit = 'kg';

  _IngredientRow({String name = '', String amount = '', this.unit = 'kg'}) {
    nameController.text = name;
    amountController.text = amount;
  }

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class _XonadoshCreateRecipeSheetState
    extends ConsumerState<XonadoshCreateRecipeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '30');
  final _caloriesController = TextEditingController(text: '450');
  final _instructionsController = TextEditingController();

  String _category = 'Talaba taomi';
  String _costLevel = 'budget';
  bool _isLoading = false;

  final List<_IngredientRow> _ingredients = [
    _IngredientRow(name: 'Kartoshka', amount: '0.3', unit: 'kg'),
    _IngredientRow(name: 'Tuxum', amount: '2', unit: 'dona'),
    _IngredientRow(name: 'O‘simlik yog‘i', amount: '0.05', unit: 'litr'),
  ];

  final List<String> _categories = [
    'Talaba taomi',
    'Milliy taom',
    'Tezkor taom',
    'Suyuq taom',
    'Qovurma',
    'Nonushta',
  ];

  final List<String> _units = ['kg', 'g', 'litr', 'dona', 'pachka', 'bog‘'];

  String _categoryLabel(String cat) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _prepTimeController.dispose();
    _caloriesController.dispose();
    _instructionsController.dispose();
    for (final row in _ingredients) {
      row.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(_IngredientRow());
    });
  }

  void _removeIngredient(int index) {
    if (_ingredients.length > 1) {
      setState(() {
        _ingredients.removeAt(index).dispose();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final prepTime = int.tryParse(_prepTimeController.text.trim()) ?? 30;
    final calories = int.tryParse(_caloriesController.text.trim()) ?? 450;
    final instructions = _instructionsController.text.trim();

    final ingredientsList = <Map<String, dynamic>>[];
    for (final row in _ingredients) {
      final iName = row.nameController.text.trim();
      final iAmt = double.tryParse(row.amountController.text.trim()) ?? 0.1;
      if (iName.isNotEmpty) {
        ingredientsList.add({
          'key': iName.toLowerCase().replaceAll(' ', '_'),
          'name_uz': iName,
          'amount_per_person': iAmt,
          'unit': row.unit,
        });
      }
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(xonadoshRepositoryProvider);
      final res = await repo.createRecipe({
        'name_uz': name,
        'category': _category,
        'prep_time_min': prepTime,
        'cost_level': _costLevel,
        'calories_kcal': calories,
        'instructions_uz': instructions.isNotEmpty
            ? instructions
            : context.l10n.xonadoshDefaultInstructions,
        'ingredients': ingredientsList,
      });

      if (res['ok'] == true) {
        final recipeId = res['recipe_id'] as int?;

        // If day and meal time were provided, set into meal plan
        if (widget.initialDay != null && widget.initialMealTime != null) {
          await repo.setMealPlan({
            'day_of_week': widget.initialDay,
            'meal_time': widget.initialMealTime,
            'recipe_id': recipeId,
            'recipe_name': name,
            'cook_name': 'Men',
          });
        }

        ref.invalidate(xonadoshRecipesAndMealPlanProvider);
        ref.invalidate(xonadoshGroceryCalculationProvider);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ "$name" taomi muvaffaqiyatli saqlandi!'),
              backgroundColor: XonaDoshColors.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['error']?.toString() ?? context.l10n.commonErrorOccurred),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.xonadoshErrGeneric('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header with Back Button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.xonadoshAddMealTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            context.l10n.xonadoshAddMealSubtitle,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Meal Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.xonadoshMealNameReq,
                    hintText: context.l10n.xonadoshRecipeNameHint,
                    prefixIcon: const Icon(Icons.restaurant_menu_rounded, color: XonaDoshColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return context.l10n.xonadoshEnterMealName;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category & Cost Tier Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: InputDecoration(
                          labelText: context.l10n.xonadoshCategoryLabel,
                          prefixIcon: const Icon(Icons.category_rounded, color: XonaDoshColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              _categoryLabel(c),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _costLevel,
                        decoration: InputDecoration(
                          labelText: context.l10n.xonadoshPriceLevelLabel,
                          prefixIcon: const Icon(Icons.monetization_on_rounded, color: XonaDoshColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'budget',
                            child: Text(context.l10n.xonadoshBudgetFriendly, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text(context.l10n.xonadoshMediumBudget, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _costLevel = val);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Prep Time & Calories Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prepTimeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.l10n.xonadoshPrepTimeMinutes,
                          prefixIcon: const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.l10n.xonadoshCaloriesKcal,
                          prefixIcon: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B6B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Ingredients Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.xonadoshIngredientsPerPerson,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                      label: Text(context.l10n.xonadoshAddBtn),
                      style: TextButton.styleFrom(
                        foregroundColor: XonaDoshColors.primary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Ingredients Dynamic Rows
                ...List.generate(_ingredients.length, (idx) {
                  final row = _ingredients[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: row.nameController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: context.l10n.xonadoshIngredientName,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: row.amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: context.l10n.xonadoshIngredientAmount,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: row.unit,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: _units.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(
                                  u,
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => row.unit = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          onPressed: () => _removeIngredient(idx),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Instructions
                TextFormField(
                  controller: _instructionsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.l10n.xonadoshCookingStepsLabel,
                    hintText: context.l10n.xonadoshCookingStepsHint,
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.menu_book_rounded, color: XonaDoshColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _isLoading ? context.l10n.xonadoshSaving : context.l10n.xonadoshSaveAndAddMenu,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: XonaDoshColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
