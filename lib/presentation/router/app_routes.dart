class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const shell = '/app';
  static const settings = '/settings';

  /// Aliases matching ported Hamyon screens.
  static const xonadosh = shell;
  static const xonadoshMap = '/app/map';
  static const xonadoshListingDetail = '/app/listing/:id';
  static const xonadoshProfileEdit = '/app/profile-edit';
  static const xonadoshCreateListing = '/app/create-listing';
}
