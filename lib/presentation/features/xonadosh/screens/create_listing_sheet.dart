import 'package:flutter/material.dart';
import 'create_listing_screen.dart';

export 'create_listing_screen.dart';

/// Helper to open the full-screen listing creation
void showXonadoshCreateListingSheet(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const XonadoshCreateListingScreen(),
    ),
  );
}

/// Backward compatibility alias
typedef XonadoshCreateListingSheet = XonadoshCreateListingScreen;
