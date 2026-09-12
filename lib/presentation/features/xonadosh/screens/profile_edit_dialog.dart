import 'package:flutter/material.dart';
import 'package:xonadosh/data/models/xonadosh_models.dart';
import 'profile_edit_screen.dart';

export 'profile_edit_screen.dart';

/// Helper to open the full-screen anketa
void showXonadoshAnketaSheet(BuildContext context, {XonadoshProfile? initialProfile}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => XonadoshProfileEditScreen(initialProfile: initialProfile),
    ),
  );
}

/// Backward compatibility alias
typedef XonadoshProfileEditDialog = XonadoshProfileEditScreen;
