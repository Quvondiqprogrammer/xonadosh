import 'package:xonadosh/l10n/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xonadosh/config/theme.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'package:xonadosh/presentation/providers/xonadosh_providers.dart';

class XonadoshAssignChoreDialog extends ConsumerStatefulWidget {
  final XonadoshChore chore;

  const XonadoshAssignChoreDialog({
    super.key,
    required this.chore,
  });

  @override
  ConsumerState<XonadoshAssignChoreDialog> createState() =>
      _XonadoshAssignChoreDialogState();
}

class _XonadoshAssignChoreDialogState
    extends ConsumerState<XonadoshAssignChoreDialog> {
  late final TextEditingController _nameController;
  bool _isLoading = false;

  final List<String> _suggestedRoommates = [
    'Asadbek',
    'Javohir',
    'Bobur',
    'Otabek',
    'Shohruh',
    'Sardor',
    'Men',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.chore.assignedName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _assign(String name) async {
    if (name.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(xonadoshRepositoryProvider);
      final ok = await repo.assignChore(
        choreId: widget.chore.id,
        assignedName: name.trim(),
      );

      if (ok) {
        ref.invalidate(xonadoshChoresProvider);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.xonadoshAssignedSnack(widget.chore.title, name)),
              backgroundColor: XonaDoshColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.xonadoshErrGeneric('$e')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              context.l10n.xonadoshAssignDutyTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.xonadoshTaskWithDay(widget.chore.title, widget.chore.dayOfWeek),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: XonaDoshColors.primary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.xonadoshDutyPersonInCharge,
                prefixIcon: const Icon(Icons.person_rounded, color: XonaDoshColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.xonadoshQuickPick,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestedRoommates.map((name) {
                final label = name == 'Men' ? context.l10n.xonadoshMeSelf : name;
                return ActionChip(
                  label: Text(label),
                  backgroundColor: XonaDoshColors.primary.withAlpha(20),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: XonaDoshColors.primary),
                  onPressed: () {
                    _nameController.text = label;
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _assign(_nameController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: XonaDoshColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.l10n.xonadoshAssignChoreBtn, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
