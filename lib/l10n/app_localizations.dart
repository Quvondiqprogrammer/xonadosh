import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// Label or text for app name in UI
  ///
  /// In en, this message translates to:
  /// **'XonaDosh'**
  String get appName;

  /// Label or text for common add in UI
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Label or text for common cancel in UI
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Label or text for common clear in UI
  ///
  /// In en, this message translates to:
  /// **'Clean up'**
  String get commonClear;

  /// Label or text for common close in UI
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Label or text for common confirm in UI
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Label or text for common delete in UI
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Label or text for common edit in UI
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get commonErrorOccurred;

  /// Label or text for common next in UI
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// Label or text for common ok in UI
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Label or text for common retry in UI
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Label or text for common save in UI
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Label or text for common select in UI
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get commonSelect;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @currencyUzsSuffix.
  ///
  /// In en, this message translates to:
  /// **'UZS'**
  String get currencyUzsSuffix;

  /// No description provided for @dashboardServiceXonadosh.
  ///
  /// In en, this message translates to:
  /// **'XonaDosh'**
  String get dashboardServiceXonadosh;

  /// No description provided for @inbarakaCallSeller.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get inbarakaCallSeller;

  /// No description provided for @inbarakaViewOnMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get inbarakaViewOnMap;

  /// Button label for login button
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// Label or text for login no account in UI
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get loginNoAccount;

  /// Label or text for login password in UI
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// Label or text for login username in UI
  ///
  /// In en, this message translates to:
  /// **'Username or phone'**
  String get loginUsername;

  /// No description provided for @nikohErrorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {detail}'**
  String nikohErrorWithDetail(String detail);

  /// Button label for register button
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerButton;

  /// Label or text for register full name in UI
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerFullName;

  /// Title text for register title
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// Label or text for settings logout in UI
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// Thousand short suffix
  ///
  /// In en, this message translates to:
  /// **'k'**
  String get thousandShort;

  /// Per person per day
  ///
  /// In en, this message translates to:
  /// **'1 PERSON / DAY (3 meals)'**
  String get xonadosh1PersonDay;

  /// Per person per week
  ///
  /// In en, this message translates to:
  /// **'1 PERSON / WEEK'**
  String get xonadosh1PersonWeek;

  /// 1 week groceries label
  ///
  /// In en, this message translates to:
  /// **'1-week groceries (3 meals/day):'**
  String get xonadosh1WeekGroceries;

  /// 21 meals 7 days
  ///
  /// In en, this message translates to:
  /// **'21 meals • 7 days'**
  String get xonadosh21Meals7Days;

  /// 7-day meal plan title
  ///
  /// In en, this message translates to:
  /// **'7-Day Schedule (21 meals)'**
  String get xonadosh7DayPlan;

  /// 7-day schedule label
  ///
  /// In en, this message translates to:
  /// **'7-Day Schedule (21 meals)'**
  String get xonadosh7DaySchedule;

  /// No description provided for @xonadoshAboutSelf.
  ///
  /// In en, this message translates to:
  /// **'About myself:'**
  String get xonadoshAboutSelf;

  /// About self hint
  ///
  /// In en, this message translates to:
  /// **'About your interests, personality, leisure time...'**
  String get xonadoshAboutSelfHint;

  /// Active profile status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get xonadoshActiveStatus;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get xonadoshAdd;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get xonadoshAddBtn;

  /// No description provided for @xonadoshAddCustomMeal.
  ///
  /// In en, this message translates to:
  /// **'Add your own dish'**
  String get xonadoshAddCustomMeal;

  /// Add meal button
  ///
  /// In en, this message translates to:
  /// **'+ Add Meal'**
  String get xonadoshAddMeal;

  /// No description provided for @xonadoshAddMealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your recipe and ingredients'**
  String get xonadoshAddMealSubtitle;

  /// No description provided for @xonadoshAddMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new dish'**
  String get xonadoshAddMealTitle;

  /// No description provided for @xonadoshAddNewRecipe.
  ///
  /// In en, this message translates to:
  /// **'Add New Recipe'**
  String get xonadoshAddNewRecipe;

  /// Add new recipe button
  ///
  /// In en, this message translates to:
  /// **'Add your own dish'**
  String get xonadoshAddNewRecipeBtn;

  /// Add to weekly menu button
  ///
  /// In en, this message translates to:
  /// **'Add to weekly menu'**
  String get xonadoshAddToWeeklyMenu;

  /// Address hint
  ///
  /// In en, this message translates to:
  /// **'Street, house number, stop or known landmark'**
  String get xonadoshAddressHint;

  /// Address required label
  ///
  /// In en, this message translates to:
  /// **'Landmark / Exact address *'**
  String get xonadoshAddressReq;

  /// Age label
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get xonadoshAge;

  /// No description provided for @xonadoshAiMatchBasis.
  ///
  /// In en, this message translates to:
  /// **'AI Match Factors:'**
  String get xonadoshAiMatchBasis;

  /// AI Matching badge
  ///
  /// In en, this message translates to:
  /// **'AI Matching'**
  String get xonadoshAiMatchingBadge;

  /// No description provided for @xonadoshAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get xonadoshAll;

  /// All items bought toggle
  ///
  /// In en, this message translates to:
  /// **'All bought'**
  String get xonadoshAllBought;

  /// No description provided for @xonadoshAllDistricts.
  ///
  /// In en, this message translates to:
  /// **'All districts'**
  String get xonadoshAllDistricts;

  /// No description provided for @xonadoshAllRegions.
  ///
  /// In en, this message translates to:
  /// **'All regions'**
  String get xonadoshAllRegions;

  /// No description provided for @xonadoshAllUniversities.
  ///
  /// In en, this message translates to:
  /// **'All universities'**
  String get xonadoshAllUniversities;

  /// No description provided for @xonadoshAmenitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get xonadoshAmenitiesTitle;

  /// No description provided for @xonadoshAreaShort.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get xonadoshAreaShort;

  /// Area in square meters label
  ///
  /// In en, this message translates to:
  /// **'Area (m²)'**
  String get xonadoshAreaSqM;

  /// Assign chore button
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get xonadoshAssignChoreBtn;

  /// No description provided for @xonadoshAssignDutyTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign duty'**
  String get xonadoshAssignDutyTitle;

  /// No description provided for @xonadoshAssignedSnack.
  ///
  /// In en, this message translates to:
  /// **'“{name}” assigned to {title}'**
  String xonadoshAssignedSnack(String title, String name);

  /// No description provided for @xonadoshAudienceAll.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get xonadoshAudienceAll;

  /// No description provided for @xonadoshAudienceBoys.
  ///
  /// In en, this message translates to:
  /// **'For boys / students'**
  String get xonadoshAudienceBoys;

  /// No description provided for @xonadoshAudienceFamily.
  ///
  /// In en, this message translates to:
  /// **'For families'**
  String get xonadoshAudienceFamily;

  /// No description provided for @xonadoshAudienceGirls.
  ///
  /// In en, this message translates to:
  /// **'For girls / students'**
  String get xonadoshAudienceGirls;

  /// Return to list selection
  ///
  /// In en, this message translates to:
  /// **'Back to list selection'**
  String get xonadoshBackToListSelection;

  /// Back to Tashkent center button
  ///
  /// In en, this message translates to:
  /// **'Back to Tashkent center'**
  String get xonadoshBackToTashkentCenter;

  /// Bazaar real prices footnote
  ///
  /// In en, this message translates to:
  /// **'Calculated based on 100% real prices of Chorsu and Kuyluk bazaars'**
  String get xonadoshBazaarRealPricesFootnote;

  /// No description provided for @xonadoshBoys.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get xonadoshBoys;

  /// No description provided for @xonadoshBoysOnly.
  ///
  /// In en, this message translates to:
  /// **'Boys only'**
  String get xonadoshBoysOnly;

  /// No description provided for @xonadoshBreadAndTea.
  ///
  /// In en, this message translates to:
  /// **'Bread and tea'**
  String get xonadoshBreadAndTea;

  /// Bread calculation title
  ///
  /// In en, this message translates to:
  /// **'🍞 Weekly Bread Calculation'**
  String get xonadoshBreadCalcTitle;

  /// No description provided for @xonadoshBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get xonadoshBreakfast;

  /// Budget friendly price level
  ///
  /// In en, this message translates to:
  /// **'Budget-friendly 🟢'**
  String get xonadoshBudgetFriendly;

  /// No description provided for @xonadoshBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'The rent range you are willing to pay'**
  String get xonadoshBudgetHint;

  /// Budget label in xonadosh
  ///
  /// In en, this message translates to:
  /// **'Budget:'**
  String get xonadoshBudgetPrefix;

  /// No description provided for @xonadoshBudgetRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget range'**
  String get xonadoshBudgetRangeLabel;

  /// No description provided for @xonadoshBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get xonadoshBus;

  /// No description provided for @xonadoshCalcFailed.
  ///
  /// In en, this message translates to:
  /// **'Calculation unavailable'**
  String get xonadoshCalcFailed;

  /// Call button
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get xonadoshCall;

  /// Call button label
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get xonadoshCallBtn;

  /// Calories label
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get xonadoshCaloriesKcal;

  /// No description provided for @xonadoshCatFry.
  ///
  /// In en, this message translates to:
  /// **'Fried'**
  String get xonadoshCatFry;

  /// No description provided for @xonadoshCatNational.
  ///
  /// In en, this message translates to:
  /// **'National dish'**
  String get xonadoshCatNational;

  /// No description provided for @xonadoshCatQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick meal'**
  String get xonadoshCatQuick;

  /// No description provided for @xonadoshCatSoup.
  ///
  /// In en, this message translates to:
  /// **'Soup'**
  String get xonadoshCatSoup;

  /// No description provided for @xonadoshCatStudent.
  ///
  /// In en, this message translates to:
  /// **'Student meal'**
  String get xonadoshCatStudent;

  /// Category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get xonadoshCategoryLabel;

  /// Cleanliness
  ///
  /// In en, this message translates to:
  /// **'Cleanliness & Order:'**
  String get xonadoshCleanliness;

  /// Clear filter link
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get xonadoshClearFilter;

  /// No description provided for @xonadoshClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get xonadoshClearFilters;

  /// Duty tab
  ///
  /// In en, this message translates to:
  /// **'Duty / Chores'**
  String get xonadoshColivingDuty;

  /// Coliving groceries tab
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get xonadoshColivingGroceries;

  /// Coliving menu tab
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get xonadoshColivingMenu;

  /// No description provided for @xonadoshColivingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Duty roster, menu & grocery calculation'**
  String get xonadoshColivingSubtitle;

  /// No description provided for @xonadoshColivingTab.
  ///
  /// In en, this message translates to:
  /// **'Together'**
  String get xonadoshColivingTab;

  /// Contact methods title
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get xonadoshContactMethods;

  /// Cooking
  ///
  /// In en, this message translates to:
  /// **'Cooking meals:'**
  String get xonadoshCooking;

  /// Cooking steps hint
  ///
  /// In en, this message translates to:
  /// **'Sequence of frying or boiling ingredients...'**
  String get xonadoshCookingStepsHint;

  /// Cooking steps label
  ///
  /// In en, this message translates to:
  /// **'Brief cooking instructions'**
  String get xonadoshCookingStepsLabel;

  /// Course level label
  ///
  /// In en, this message translates to:
  /// **'Course / Year:'**
  String get xonadoshCourseLevel;

  /// University course year
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get xonadoshCourseYear;

  /// No description provided for @xonadoshCourseYearSuffix.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String xonadoshCourseYearSuffix(int year);

  /// Create listing screen title
  ///
  /// In en, this message translates to:
  /// **'Post New Listing'**
  String get xonadoshCreateListingTitle;

  /// Currency label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get xonadoshCurrency;

  /// No description provided for @xonadoshDailyExpensePerPerson.
  ///
  /// In en, this message translates to:
  /// **'Daily cost per person: ~16 000–18 000 UZS (3 meals + bread + tea)'**
  String get xonadoshDailyExpensePerPerson;

  /// Daily meals schedule title
  ///
  /// In en, this message translates to:
  /// **'Daily 3-Meal Schedule'**
  String get xonadoshDailyMealsSchedule;

  /// Friday
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get xonadoshDayFriday;

  /// Monday
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get xonadoshDayMonday;

  /// Saturday
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get xonadoshDaySaturday;

  /// Sunday
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get xonadoshDaySunday;

  /// Thursday
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get xonadoshDayThursday;

  /// Tuesday
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get xonadoshDayTuesday;

  /// Wednesday
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get xonadoshDayWednesday;

  /// No description provided for @xonadoshDefaultInstructions.
  ///
  /// In en, this message translates to:
  /// **'Clean the ingredients and cook over medium heat.'**
  String get xonadoshDefaultInstructions;

  /// Delete profile button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get xonadoshDeleteProfileBtn;

  /// Delete profile title
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get xonadoshDeleteProfileTitle;

  /// No description provided for @xonadoshDeleteSearchStop.
  ///
  /// In en, this message translates to:
  /// **'Delete profile (stop searching)'**
  String get xonadoshDeleteSearchStop;

  /// Delete survey button
  ///
  /// In en, this message translates to:
  /// **'Delete survey'**
  String get xonadoshDeleteSurvey;

  /// No description provided for @xonadoshDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get xonadoshDescriptionTitle;

  /// Detailed description label
  ///
  /// In en, this message translates to:
  /// **'Detailed description'**
  String get xonadoshDetailedDesc;

  /// Detailed description hint
  ///
  /// In en, this message translates to:
  /// **'Apartment conditions, rules, nearby metro/transport and requirements...'**
  String get xonadoshDetailedDescHint;

  /// No description provided for @xonadoshDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get xonadoshDinner;

  /// District example hint
  ///
  /// In en, this message translates to:
  /// **'E.g.: Urgut center, Shodlik neighborhood'**
  String get xonadoshDistrictExampleHint;

  /// No description provided for @xonadoshDistrictShort.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get xonadoshDistrictShort;

  /// Duty day dropdown label
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get xonadoshDutyDay;

  /// Person in charge label
  ///
  /// In en, this message translates to:
  /// **'Responsible roommate name'**
  String get xonadoshDutyPersonInCharge;

  /// Duty roster tab
  ///
  /// In en, this message translates to:
  /// **'Duty Roster'**
  String get xonadoshDutyRosterTab;

  /// No description provided for @xonadoshDutySchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly Chore Schedule'**
  String get xonadoshDutySchedule;

  /// Task name label
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get xonadoshDutyTaskName;

  /// Task name hint
  ///
  /// In en, this message translates to:
  /// **'E.g.: House cleaning'**
  String get xonadoshDutyTaskNameHint;

  /// Edit button in xonadosh
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get xonadoshEdit;

  /// No description provided for @xonadoshEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter the address'**
  String get xonadoshEnterAddress;

  /// District name input label
  ///
  /// In en, this message translates to:
  /// **'Enter district / city name *'**
  String get xonadoshEnterDistrictName;

  /// No description provided for @xonadoshEnterMealName.
  ///
  /// In en, this message translates to:
  /// **'Enter a dish name'**
  String get xonadoshEnterMealName;

  /// No description provided for @xonadoshEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number'**
  String get xonadoshEnterPhone;

  /// No description provided for @xonadoshEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a price'**
  String get xonadoshEnterPrice;

  /// No description provided for @xonadoshEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get xonadoshEnterTitle;

  /// Generic error message in xonadosh
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String xonadoshErrGeneric(Object error);

  /// No description provided for @xonadoshEstimatedTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get xonadoshEstimatedTimeMinutes;

  /// Exit button
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get xonadoshExitBtn;

  /// Faculty label
  ///
  /// In en, this message translates to:
  /// **'Faculty / Major'**
  String get xonadoshFaculty;

  /// Faculty label
  ///
  /// In en, this message translates to:
  /// **'Faculty / Major'**
  String get xonadoshFacultyField;

  /// Faculty hint
  ///
  /// In en, this message translates to:
  /// **'E.g.: Software Engineering'**
  String get xonadoshFacultyHint;

  /// Family badge
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get xonadoshFamily;

  /// No description provided for @xonadoshFareMonthly.
  ///
  /// In en, this message translates to:
  /// **'{fare} {cur} ({monthly}/mo)'**
  String xonadoshFareMonthly(String fare, String cur, String monthly);

  /// No description provided for @xonadoshFestive.
  ///
  /// In en, this message translates to:
  /// **'Festive'**
  String get xonadoshFestive;

  /// Fill all required fields warning
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields!'**
  String get xonadoshFillAllRequired;

  /// No description provided for @xonadoshFillProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get xonadoshFillProfile;

  /// Fill required fields snackbar
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields!'**
  String get xonadoshFillRequiredFieldsSnack;

  /// Button to fill roommate survey
  ///
  /// In en, this message translates to:
  /// **'Fill survey (Separate window)'**
  String get xonadoshFillSurveyWindow;

  /// No description provided for @xonadoshFindRoommate.
  ///
  /// In en, this message translates to:
  /// **'Find a roommate'**
  String get xonadoshFindRoommate;

  /// Floor label
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get xonadoshFloor;

  /// Floor short
  ///
  /// In en, this message translates to:
  /// **'floor'**
  String get xonadoshFloorShort;

  /// For boys filter tag
  ///
  /// In en, this message translates to:
  /// **'For Boys'**
  String get xonadoshForBoys;

  /// For girls filter tag
  ///
  /// In en, this message translates to:
  /// **'For Girls'**
  String get xonadoshForGirls;

  /// No description provided for @xonadoshForRent.
  ///
  /// In en, this message translates to:
  /// **'🏠 Rent'**
  String get xonadoshForRent;

  /// For sale filter tag
  ///
  /// In en, this message translates to:
  /// **'💰 For Sale'**
  String get xonadoshForSale;

  /// No description provided for @xonadoshFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get xonadoshFree;

  /// Full name hint
  ///
  /// In en, this message translates to:
  /// **'E.g.: Sardor Aliyev'**
  String get xonadoshFullNameHint;

  /// Full name required label
  ///
  /// In en, this message translates to:
  /// **'Your Full Name *'**
  String get xonadoshFullNameReq;

  /// Full name required
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get xonadoshFullNameRequired;

  /// Gender label
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get xonadoshGender;

  /// No description provided for @xonadoshGirl.
  ///
  /// In en, this message translates to:
  /// **'Girl'**
  String get xonadoshGirl;

  /// No description provided for @xonadoshGirls.
  ///
  /// In en, this message translates to:
  /// **'Girls'**
  String get xonadoshGirls;

  /// No description provided for @xonadoshGirlsOnly.
  ///
  /// In en, this message translates to:
  /// **'Girls only'**
  String get xonadoshGirlsOnly;

  /// No description provided for @xonadoshGlobalUzbekistan.
  ///
  /// In en, this message translates to:
  /// **'Global & Uzbekistan'**
  String get xonadoshGlobalUzbekistan;

  /// No description provided for @xonadoshGraduateWorker.
  ///
  /// In en, this message translates to:
  /// **'Graduate / Worker'**
  String get xonadoshGraduateWorker;

  /// No description provided for @xonadoshGroceryList.
  ///
  /// In en, this message translates to:
  /// **'Grocery List'**
  String get xonadoshGroceryList;

  /// Grocery list title with count
  ///
  /// In en, this message translates to:
  /// **'Grocery List ({count} items):'**
  String xonadoshGroceryListCount(Object count);

  /// Grocery shopping tab
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get xonadoshGroceryTab;

  /// No description provided for @xonadoshGuy.
  ///
  /// In en, this message translates to:
  /// **'Guy'**
  String get xonadoshGuy;

  /// Average clean habit
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get xonadoshHabitAverageClean;

  /// No description provided for @xonadoshHabitBalconySmoke.
  ///
  /// In en, this message translates to:
  /// **'Balcony only'**
  String get xonadoshHabitBalconySmoke;

  /// No description provided for @xonadoshHabitCookRotates.
  ///
  /// In en, this message translates to:
  /// **'We take turns'**
  String get xonadoshHabitCookRotates;

  /// No description provided for @xonadoshHabitCookSelf.
  ///
  /// In en, this message translates to:
  /// **'Everyone cooks for themselves'**
  String get xonadoshHabitCookSelf;

  /// Early bird habit
  ///
  /// In en, this message translates to:
  /// **'Early bird'**
  String get xonadoshHabitEarlyBird;

  /// No description provided for @xonadoshHabitEatOut.
  ///
  /// In en, this message translates to:
  /// **'Mostly eat out'**
  String get xonadoshHabitEatOut;

  /// Flexible schedule habit
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get xonadoshHabitFlexible;

  /// Group study habit
  ///
  /// In en, this message translates to:
  /// **'Group study'**
  String get xonadoshHabitGroupStudy;

  /// No description provided for @xonadoshHabitIDontSmoke.
  ///
  /// In en, this message translates to:
  /// **'I don’t smoke'**
  String get xonadoshHabitIDontSmoke;

  /// No description provided for @xonadoshHabitMusicStudy.
  ///
  /// In en, this message translates to:
  /// **'Headphones / music'**
  String get xonadoshHabitMusicStudy;

  /// Night owl habit
  ///
  /// In en, this message translates to:
  /// **'Night owl'**
  String get xonadoshHabitNightOwl;

  /// No smoking habit
  ///
  /// In en, this message translates to:
  /// **'Non-smoker'**
  String get xonadoshHabitNoSmoking;

  /// No description provided for @xonadoshHabitRelaxedClean.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get xonadoshHabitRelaxedClean;

  /// Silent study habit
  ///
  /// In en, this message translates to:
  /// **'Silent study'**
  String get xonadoshHabitSilentStudy;

  /// Smoking habit
  ///
  /// In en, this message translates to:
  /// **'Smoker'**
  String get xonadoshHabitSmoker;

  /// Strict clean habit
  ///
  /// In en, this message translates to:
  /// **'Very neat'**
  String get xonadoshHabitStrictClean;

  /// No description provided for @xonadoshHabitsAiHint.
  ///
  /// In en, this message translates to:
  /// **'AI uses these habits to find compatible roommates'**
  String get xonadoshHabitsAiHint;

  /// Habits and routine title
  ///
  /// In en, this message translates to:
  /// **'Habits & Routine:'**
  String get xonadoshHabitsAndRoutine;

  /// No description provided for @xonadoshHousingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Housing, rent and university distance'**
  String get xonadoshHousingSubtitle;

  /// No description provided for @xonadoshHousingTab.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get xonadoshHousingTab;

  /// Ingredient amount hint
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get xonadoshIngredientAmount;

  /// No description provided for @xonadoshIngredientCountLine.
  ///
  /// In en, this message translates to:
  /// **'{count} ingredients: {names}'**
  String xonadoshIngredientCountLine(int count, String names);

  /// Ingredient name hint
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get xonadoshIngredientName;

  /// No description provided for @xonadoshIngredientsPerPerson.
  ///
  /// In en, this message translates to:
  /// **'Ingredients (per person)'**
  String get xonadoshIngredientsPerPerson;

  /// Lifestyle title
  ///
  /// In en, this message translates to:
  /// **'Lifestyle & Routine'**
  String get xonadoshLifestyle;

  /// Listing created success snackbar
  ///
  /// In en, this message translates to:
  /// **'Your listing was successfully posted!'**
  String get xonadoshListingCreatedSuccess;

  /// Listing not found message
  ///
  /// In en, this message translates to:
  /// **'Listing not found'**
  String get xonadoshListingNotFound;

  /// Listing title hint
  ///
  /// In en, this message translates to:
  /// **'E.g.: Cozy 2-room apartment in center'**
  String get xonadoshListingTitleHint;

  /// Listing title required label
  ///
  /// In en, this message translates to:
  /// **'Listing title *'**
  String get xonadoshListingTitleReq;

  /// No description provided for @xonadoshLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for roommate:'**
  String get xonadoshLookingFor;

  /// Looking for roommate hint
  ///
  /// In en, this message translates to:
  /// **'E.g.: Tidy, studying at TUIT, preferably in IT field...'**
  String get xonadoshLookingForRoommateHint;

  /// No description provided for @xonadoshLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get xonadoshLunch;

  /// Map screen title
  ///
  /// In en, this message translates to:
  /// **'Housing & Unis on Map'**
  String get xonadoshMapHomesAndUnis;

  /// Master degree level
  ///
  /// In en, this message translates to:
  /// **'Master\'s'**
  String get xonadoshMasterDegree;

  /// Match reason budget exact
  ///
  /// In en, this message translates to:
  /// **'Rental budget matches completely'**
  String get xonadoshMatchBudgetExact;

  /// Match reason clean moderate
  ///
  /// In en, this message translates to:
  /// **'Cleanliness standards match (Moderate)'**
  String get xonadoshMatchCleanMod;

  /// Match reason clean strict
  ///
  /// In en, this message translates to:
  /// **'Cleanliness standards match (High neatness)'**
  String get xonadoshMatchCleanStrict;

  /// Match score label
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get xonadoshMatchLabel;

  /// Match reason no smoking
  ///
  /// In en, this message translates to:
  /// **'No bad habits (Non-smoker)'**
  String get xonadoshMatchNoSmoking;

  /// Match reason same university
  ///
  /// In en, this message translates to:
  /// **'Student of the same university ({uni})'**
  String xonadoshMatchSameUni(Object uni);

  /// Match reason sleep early
  ///
  /// In en, this message translates to:
  /// **'Sleep schedule 100% matches (Early birds)'**
  String get xonadoshMatchSleepEarly;

  /// Match reason sleep flex
  ///
  /// In en, this message translates to:
  /// **'Sleep schedule 100% matches (Flexible)'**
  String get xonadoshMatchSleepFlex;

  /// Match reason sleep night
  ///
  /// In en, this message translates to:
  /// **'Sleep schedule 100% matches (Night owls)'**
  String get xonadoshMatchSleepNight;

  /// Match reason study group
  ///
  /// In en, this message translates to:
  /// **'Study atmosphere matches (Group study)'**
  String get xonadoshMatchStudyGroup;

  /// Match reason study silent
  ///
  /// In en, this message translates to:
  /// **'Study atmosphere matches (Quiet & calm)'**
  String get xonadoshMatchStudySilent;

  /// No description provided for @xonadoshMatchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI compatibility & personality match'**
  String get xonadoshMatchingSubtitle;

  /// No description provided for @xonadoshMatchingTab.
  ///
  /// In en, this message translates to:
  /// **'Roommates'**
  String get xonadoshMatchingTab;

  /// Max budget label
  ///
  /// In en, this message translates to:
  /// **'Max budget'**
  String get xonadoshMaxBudget;

  /// No description provided for @xonadoshMeSelf.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get xonadoshMeSelf;

  /// No description provided for @xonadoshMealNameReq.
  ///
  /// In en, this message translates to:
  /// **'Dish name *'**
  String get xonadoshMealNameReq;

  /// No description provided for @xonadoshMealPickedSnack.
  ///
  /// In en, this message translates to:
  /// **'“{name}” selected for {day}'**
  String xonadoshMealPickedSnack(String day, String name);

  /// Medium price level
  ///
  /// In en, this message translates to:
  /// **'Medium 🟡'**
  String get xonadoshMediumBudget;

  /// No description provided for @xonadoshMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get xonadoshMenu;

  /// Meal menu tab
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get xonadoshMenuTab;

  /// No description provided for @xonadoshMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro'**
  String get xonadoshMetro;

  /// Min budget label
  ///
  /// In en, this message translates to:
  /// **'Min budget'**
  String get xonadoshMinBudget;

  /// No description provided for @xonadoshMonth.
  ///
  /// In en, this message translates to:
  /// **'mo'**
  String get xonadoshMonth;

  /// Monthly budget title
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent Budget'**
  String get xonadoshMonthlyBudget;

  /// Near university housing header
  ///
  /// In en, this message translates to:
  /// **'Closest housing to your university:'**
  String get xonadoshNearUniHeader;

  /// No description provided for @xonadoshNearbyStop.
  ///
  /// In en, this message translates to:
  /// **'Nearest stop'**
  String get xonadoshNearbyStop;

  /// Nearby university dropdown title
  ///
  /// In en, this message translates to:
  /// **'Nearby University (Optional)'**
  String get xonadoshNearbyUniOptional;

  /// No description provided for @xonadoshNeedRoommate.
  ///
  /// In en, this message translates to:
  /// **'👥 Need a roommate'**
  String get xonadoshNeedRoommate;

  /// New duty dialog title
  ///
  /// In en, this message translates to:
  /// **'New Duty'**
  String get xonadoshNewDuty;

  /// New recipe button
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get xonadoshNewRecipe;

  /// No duty today message
  ///
  /// In en, this message translates to:
  /// **'No duty scheduled for today ✅'**
  String get xonadoshNoDutyToday;

  /// No listings subtitle
  ///
  /// In en, this message translates to:
  /// **'Clear filters or post a listing yourself.'**
  String get xonadoshNoListingsSubtitle;

  /// No listings title
  ///
  /// In en, this message translates to:
  /// **'No rooms match these filters'**
  String get xonadoshNoListingsTitle;

  /// No description provided for @xonadoshNoMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile — sleep, cleanliness, budget — or change filters.'**
  String get xonadoshNoMatchesBody;

  /// No description provided for @xonadoshNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching roommates yet'**
  String get xonadoshNoMatchesTitle;

  /// No recipe found text
  ///
  /// In en, this message translates to:
  /// **'No such dish found'**
  String get xonadoshNoRecipeFound;

  /// Manual district input option
  ///
  /// In en, this message translates to:
  /// **'✍️ Other district / city (enter manually)...'**
  String get xonadoshOtherDistrictCustom;

  /// No description provided for @xonadoshOtherDistrictWrite.
  ///
  /// In en, this message translates to:
  /// **'Other district / city'**
  String get xonadoshOtherDistrictWrite;

  /// Payment period label
  ///
  /// In en, this message translates to:
  /// **'Payment period'**
  String get xonadoshPaymentPeriod;

  /// No description provided for @xonadoshPeopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String xonadoshPeopleCount(int count);

  /// Per month
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get xonadoshPerMonth;

  /// Per person
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get xonadoshPerPerson;

  /// No description provided for @xonadoshPeriodDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get xonadoshPeriodDay;

  /// No description provided for @xonadoshPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'mo'**
  String get xonadoshPeriodMonth;

  /// No description provided for @xonadoshPeriodTotal.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get xonadoshPeriodTotal;

  /// No description provided for @xonadoshPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'yr'**
  String get xonadoshPeriodYear;

  /// Personal data section title
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get xonadoshPersonalData;

  /// No description provided for @xonadoshPersonalDataHint.
  ///
  /// In en, this message translates to:
  /// **'Basic details so roommates can get to know you'**
  String get xonadoshPersonalDataHint;

  /// Phone number required label
  ///
  /// In en, this message translates to:
  /// **'Phone number *'**
  String get xonadoshPhoneReq;

  /// Phone number required label
  ///
  /// In en, this message translates to:
  /// **'Phone number *'**
  String get xonadoshPhoneRequired;

  /// Photo URL input hint
  ///
  /// In en, this message translates to:
  /// **'Photo URL (optional)'**
  String get xonadoshPhotoUrlOptional;

  /// No description provided for @xonadoshPickMealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the dish for {meal}'**
  String xonadoshPickMealSubtitle(String meal);

  /// No description provided for @xonadoshPickMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a meal: {day}'**
  String xonadoshPickMealTitle(String day);

  /// No description provided for @xonadoshPostListing.
  ///
  /// In en, this message translates to:
  /// **'Post listing'**
  String get xonadoshPostListing;

  /// No description provided for @xonadoshPrepOrder.
  ///
  /// In en, this message translates to:
  /// **'How to cook'**
  String get xonadoshPrepOrder;

  /// Preparation time label
  ///
  /// In en, this message translates to:
  /// **'Preparation time (min)'**
  String get xonadoshPrepTimeMinutes;

  /// Price level label
  ///
  /// In en, this message translates to:
  /// **'Price level'**
  String get xonadoshPriceLevelLabel;

  /// No description provided for @xonadoshPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get xonadoshPriceRange;

  /// Price required label
  ///
  /// In en, this message translates to:
  /// **'Price *'**
  String get xonadoshPriceReq;

  /// Price required label
  ///
  /// In en, this message translates to:
  /// **'Price *'**
  String get xonadoshPriceRequired;

  /// No description provided for @xonadoshProfileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your profile was deleted successfully'**
  String get xonadoshProfileDeleted;

  /// No description provided for @xonadoshProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get xonadoshProfileSaved;

  /// No description provided for @xonadoshPublicTransit.
  ///
  /// In en, this message translates to:
  /// **'Public transport'**
  String get xonadoshPublicTransit;

  /// No description provided for @xonadoshPublishListing.
  ///
  /// In en, this message translates to:
  /// **'Publish listing'**
  String get xonadoshPublishListing;

  /// No description provided for @xonadoshQuickPick.
  ///
  /// In en, this message translates to:
  /// **'Quick pick'**
  String get xonadoshQuickPick;

  /// No description provided for @xonadoshRecipeCatalog.
  ///
  /// In en, this message translates to:
  /// **'Recipes Catalog'**
  String get xonadoshRecipeCatalog;

  /// Recipe catalog count
  ///
  /// In en, this message translates to:
  /// **'Recipe Catalog ({count})'**
  String xonadoshRecipeCatalogCount(Object count);

  /// Dish name hint
  ///
  /// In en, this message translates to:
  /// **'E.g.: Egg lavash, Fried potatoes...'**
  String get xonadoshRecipeNameHint;

  /// Dish name required label
  ///
  /// In en, this message translates to:
  /// **'Dish name *'**
  String get xonadoshRecipeNameReq;

  /// No description provided for @xonadoshRecommendBadge.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get xonadoshRecommendBadge;

  /// Recommended roommates section title
  ///
  /// In en, this message translates to:
  /// **'Recommended Roommates'**
  String get xonadoshRecommendedTitle;

  /// Region filter header
  ///
  /// In en, this message translates to:
  /// **'Region / Province:'**
  String get xonadoshRegionHeader;

  /// No description provided for @xonadoshRentBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent Budget'**
  String get xonadoshRentBudget;

  /// No description provided for @xonadoshRentHouse.
  ///
  /// In en, this message translates to:
  /// **'🏠 Rent'**
  String get xonadoshRentHouse;

  /// Roommates count label
  ///
  /// In en, this message translates to:
  /// **'Number of roommates:'**
  String get xonadoshRoommatesCountLabel;

  /// Rooms count label
  ///
  /// In en, this message translates to:
  /// **'Number of rooms'**
  String get xonadoshRoomsCount;

  /// Rooms short
  ///
  /// In en, this message translates to:
  /// **'rooms'**
  String get xonadoshRoomsShort;

  /// No description provided for @xonadoshSaveAndAddMenu.
  ///
  /// In en, this message translates to:
  /// **'Save and add to menu'**
  String get xonadoshSaveAndAddMenu;

  /// No description provided for @xonadoshSaveAndFind.
  ///
  /// In en, this message translates to:
  /// **'Save and find roommates'**
  String get xonadoshSaveAndFind;

  /// No description provided for @xonadoshSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get xonadoshSaveChanges;

  /// No description provided for @xonadoshSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get xonadoshSaving;

  /// Search near this university button
  ///
  /// In en, this message translates to:
  /// **'Search near this university'**
  String get xonadoshSearchNearThisUni;

  /// Search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search region, city, district, university...'**
  String get xonadoshSearchPlaceholder;

  /// Search recipe hint
  ///
  /// In en, this message translates to:
  /// **'Search by dish name or ingredient...'**
  String get xonadoshSearchRecipeHint;

  /// Search tag
  ///
  /// In en, this message translates to:
  /// **'🔍 Search'**
  String get xonadoshSearchTag;

  /// Seeking rent status
  ///
  /// In en, this message translates to:
  /// **'Looking for rent'**
  String get xonadoshSeekingRent;

  /// No description provided for @xonadoshSelectDestUni.
  ///
  /// In en, this message translates to:
  /// **'Choose destination university'**
  String get xonadoshSelectDestUni;

  /// District required label
  ///
  /// In en, this message translates to:
  /// **'District / City *'**
  String get xonadoshSelectDistrictReq;

  /// Region required label
  ///
  /// In en, this message translates to:
  /// **'Region *'**
  String get xonadoshSelectRegionReq;

  /// No description provided for @xonadoshSelectUniversity.
  ///
  /// In en, this message translates to:
  /// **'Select a university'**
  String get xonadoshSelectUniversity;

  /// No description provided for @xonadoshSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get xonadoshSelected;

  /// No description provided for @xonadoshServingsRange.
  ///
  /// In en, this message translates to:
  /// **'4–6 people'**
  String get xonadoshServingsRange;

  /// No description provided for @xonadoshShareListing.
  ///
  /// In en, this message translates to:
  /// **'🏠 {title}\n💰 {price} {currency}\n📍 {district}, {address}\n📞 {phone}'**
  String xonadoshShareListing(
    String title,
    String price,
    String currency,
    String district,
    String address,
    String phone,
  );

  /// No description provided for @xonadoshSleepEarlyHours.
  ///
  /// In en, this message translates to:
  /// **'Early bird (06:00–23:00)'**
  String get xonadoshSleepEarlyHours;

  /// No description provided for @xonadoshSleepNightHours.
  ///
  /// In en, this message translates to:
  /// **'Night owl (01:00+)'**
  String get xonadoshSleepNightHours;

  /// Sleep schedule
  ///
  /// In en, this message translates to:
  /// **'Sleep schedule:'**
  String get xonadoshSleepSchedule;

  /// Smoking
  ///
  /// In en, this message translates to:
  /// **'Smoking / Cigarettes:'**
  String get xonadoshSmoking;

  /// Stay in form button
  ///
  /// In en, this message translates to:
  /// **'Continue (Stay)'**
  String get xonadoshStayBtn;

  /// Step 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Select your listing type'**
  String get xonadoshStep1Subtitle;

  /// Step 1 listing title
  ///
  /// In en, this message translates to:
  /// **'1. Listing Type & Purpose'**
  String get xonadoshStep1Title;

  /// Step 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'Regions of Uzbekistan or International City'**
  String get xonadoshStep2Subtitle;

  /// Step 2 listing title
  ///
  /// In en, this message translates to:
  /// **'2. Location & Address'**
  String get xonadoshStep2Title;

  /// Step 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'Price, currency & payment period'**
  String get xonadoshStep3Subtitle;

  /// Step 3 title
  ///
  /// In en, this message translates to:
  /// **'3. Title & Price'**
  String get xonadoshStep3Title;

  /// Step 4 subtitle
  ///
  /// In en, this message translates to:
  /// **'Rooms, floor and intended audience'**
  String get xonadoshStep4Subtitle;

  /// Step 4 title
  ///
  /// In en, this message translates to:
  /// **'4. Features & Audience'**
  String get xonadoshStep4Title;

  /// Step 5 subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose from recommended photos or upload your own'**
  String get xonadoshStep5Subtitle;

  /// Step 5 title
  ///
  /// In en, this message translates to:
  /// **'5. Property Photos'**
  String get xonadoshStep5Title;

  /// Step 6 subtitle
  ///
  /// In en, this message translates to:
  /// **'Check all available amenities'**
  String get xonadoshStep6Subtitle;

  /// Step 6 title
  ///
  /// In en, this message translates to:
  /// **'6. Amenities & Appliances'**
  String get xonadoshStep6Title;

  /// Step 7 subtitle
  ///
  /// In en, this message translates to:
  /// **'Phone & Telegram for contact'**
  String get xonadoshStep7Subtitle;

  /// Step 7 title
  ///
  /// In en, this message translates to:
  /// **'7. Contact & Description'**
  String get xonadoshStep7Title;

  /// No description provided for @xonadoshStudentYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get xonadoshStudentYear;

  /// Study environment
  ///
  /// In en, this message translates to:
  /// **'Study environment:'**
  String get xonadoshStudyEnvironment;

  /// No description provided for @xonadoshSurveyEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get xonadoshSurveyEditTitle;

  /// No description provided for @xonadoshSurveyNewHint.
  ///
  /// In en, this message translates to:
  /// **'Once saved, AI ranks roommates by your budget, university, and habits.'**
  String get xonadoshSurveyNewHint;

  /// No description provided for @xonadoshSurveyReadyPercent.
  ///
  /// In en, this message translates to:
  /// **'{pct}% ready'**
  String xonadoshSurveyReadyPercent(int pct);

  /// No description provided for @xonadoshSurveySavedHint.
  ///
  /// In en, this message translates to:
  /// **'After saving, your info updates immediately in the roommate list.'**
  String get xonadoshSurveySavedHint;

  /// No description provided for @xonadoshSurveyStatus.
  ///
  /// In en, this message translates to:
  /// **'Profile status'**
  String get xonadoshSurveyStatus;

  /// No description provided for @xonadoshSurveyStepHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get xonadoshSurveyStepHabits;

  /// No description provided for @xonadoshSurveyStepPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get xonadoshSurveyStepPersonal;

  /// No description provided for @xonadoshSurveyStepReqs.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get xonadoshSurveyStepReqs;

  /// No description provided for @xonadoshSurveyStepUni.
  ///
  /// In en, this message translates to:
  /// **'Uni'**
  String get xonadoshSurveyStepUni;

  /// No description provided for @xonadoshSurveySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find students who match your personality, university, budget, and habits with AI.'**
  String get xonadoshSurveySubtitle;

  /// No description provided for @xonadoshSurveyTitle.
  ///
  /// In en, this message translates to:
  /// **'Roommate profile'**
  String get xonadoshSurveyTitle;

  /// Swap meal action
  ///
  /// In en, this message translates to:
  /// **'Swap / Replace'**
  String get xonadoshSwapMeal;

  /// Target audience label
  ///
  /// In en, this message translates to:
  /// **'Intended for:'**
  String get xonadoshTargetAudience;

  /// No description provided for @xonadoshTaskWithDay.
  ///
  /// In en, this message translates to:
  /// **'Task: {title} ({day})'**
  String xonadoshTaskWithDay(String title, String day);

  /// Telegram label
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get xonadoshTelegram;

  /// Write on Telegram button
  ///
  /// In en, this message translates to:
  /// **'Write on Telegram'**
  String get xonadoshTelegramChat;

  /// No description provided for @xonadoshTelegramShort.
  ///
  /// In en, this message translates to:
  /// **'TG'**
  String get xonadoshTelegramShort;

  /// Today label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get xonadoshToday;

  /// No description provided for @xonadoshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Roommate — find housing and roommates'**
  String get xonadoshTooltip;

  /// No description provided for @xonadoshTotal.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get xonadoshTotal;

  /// Total floors label
  ///
  /// In en, this message translates to:
  /// **'Total floors'**
  String get xonadoshTotalFloors;

  /// No description provided for @xonadoshTotalWeeklyBreadCost.
  ///
  /// In en, this message translates to:
  /// **'Weekly Bread Expense'**
  String get xonadoshTotalWeeklyBreadCost;

  /// No description provided for @xonadoshTransportAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Commute analysis'**
  String get xonadoshTransportAnalysis;

  /// No description provided for @xonadoshTypeForRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get xonadoshTypeForRent;

  /// No description provided for @xonadoshTypeForSale.
  ///
  /// In en, this message translates to:
  /// **'For sale'**
  String get xonadoshTypeForSale;

  /// No description provided for @xonadoshTypeLookingRent.
  ///
  /// In en, this message translates to:
  /// **'Looking to rent'**
  String get xonadoshTypeLookingRent;

  /// No description provided for @xonadoshTypeRentHome.
  ///
  /// In en, this message translates to:
  /// **'Rent (home)'**
  String get xonadoshTypeRentHome;

  /// No description provided for @xonadoshTypeRoommate.
  ///
  /// In en, this message translates to:
  /// **'Roommate'**
  String get xonadoshTypeRoommate;

  /// No description provided for @xonadoshTypeRoommateNeeded.
  ///
  /// In en, this message translates to:
  /// **'Roommate wanted'**
  String get xonadoshTypeRoommateNeeded;

  /// No description provided for @xonadoshUniFallback.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get xonadoshUniFallback;

  /// No university selected option
  ///
  /// In en, this message translates to:
  /// **'Not university bound / Not selected'**
  String get xonadoshUniNone;

  /// No description provided for @xonadoshUniNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not tied to a university'**
  String get xonadoshUniNotLinked;

  /// No description provided for @xonadoshUniOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearby university (optional)'**
  String get xonadoshUniOptionalLabel;

  /// University place title
  ///
  /// In en, this message translates to:
  /// **'University (HEI)'**
  String get xonadoshUniPlace;

  /// No description provided for @xonadoshViewAllListings.
  ///
  /// In en, this message translates to:
  /// **'View all listings'**
  String get xonadoshViewAllListings;

  /// Exit confirmation title
  ///
  /// In en, this message translates to:
  /// **'Do you want to exit?'**
  String get xonadoshWantToExitTitle;

  /// No description provided for @xonadoshWeeklyBreadCalc.
  ///
  /// In en, this message translates to:
  /// **'🍞 Weekly Bread Calculation'**
  String get xonadoshWeeklyBreadCalc;

  /// Weekly duty roster title
  ///
  /// In en, this message translates to:
  /// **'Weekly Duty Schedule'**
  String get xonadoshWeeklyDutySchedule;

  /// Weekly grocery summary
  ///
  /// In en, this message translates to:
  /// **'1-week groceries (3 meals/day):'**
  String get xonadoshWeeklyGrocerySummary;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Student housing, roommate matching, and shared living'**
  String get tagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get register;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to XonaDosh'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find a room. Find a roommate. Live together.'**
  String get loginSubtitle;

  /// No description provided for @registerUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get registerUsername;

  /// No description provided for @registerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get registerPhone;

  /// No description provided for @registerPassword.
  ///
  /// In en, this message translates to:
  /// **'Password (min 8)'**
  String get registerPassword;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Have an account? Log in'**
  String get registerHaveAccount;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get settingsTerms;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and data.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get accountDeleteConfirm;

  /// No description provided for @emptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyStateTitle;

  /// No description provided for @emptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post a listing or complete your profile to get started.'**
  String get emptyStateSubtitle;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @commonLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get commonLogout;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @xonadoshContactOptions.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get xonadoshContactOptions;

  /// No description provided for @xonadoshCopyPhone.
  ///
  /// In en, this message translates to:
  /// **'Copy phone number'**
  String get xonadoshCopyPhone;

  /// No description provided for @xonadoshPhoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get xonadoshPhoneCopied;

  /// No description provided for @xonadoshCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get xonadoshCopiedToClipboard;

  /// No description provided for @xonadoshWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get xonadoshWhatsApp;

  /// No description provided for @xonadoshWebCallHint.
  ///
  /// In en, this message translates to:
  /// **'On desktop, copy the number or open WhatsApp / Telegram.'**
  String get xonadoshWebCallHint;

  /// No description provided for @xonadoshOpenLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get xonadoshOpenLinkFailed;

  /// No description provided for @xonadoshPickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get xonadoshPickFromGallery;

  /// No description provided for @xonadoshTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get xonadoshTakePhoto;

  /// No description provided for @xonadoshUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get xonadoshUploadingPhoto;

  /// No description provided for @xonadoshPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed'**
  String get xonadoshPhotoUploadFailed;

  /// No description provided for @xonadoshUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get xonadoshUseMyLocation;

  /// No description provided for @xonadoshLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get xonadoshLocationDenied;

  /// No description provided for @xonadoshLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get location'**
  String get xonadoshLocationFailed;

  /// No description provided for @reportContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Report content'**
  String get reportContentTitle;

  /// No description provided for @reportContentBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us why this content should be reviewed. Our moderation team will investigate within 24 hours.'**
  String get reportContentBody;

  /// No description provided for @reportContentSubjectListing.
  ///
  /// In en, this message translates to:
  /// **'Listing: {title}'**
  String reportContentSubjectListing(String title);

  /// No description provided for @reportContentSubjectProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile: {name}'**
  String reportContentSubjectProfile(String name);

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or fake listing'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate or offensive content'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or abuse'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonScam.
  ///
  /// In en, this message translates to:
  /// **'Scam or fraud'**
  String get reportReasonScam;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get reportDetailsHint;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get reportSubmitted;

  /// No description provided for @reportLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to report content'**
  String get reportLoginRequired;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportAction;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock user'**
  String get unblockUser;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get blockUserTitle;

  /// No description provided for @blockUserBody.
  ///
  /// In en, this message translates to:
  /// **'You will no longer see their listings or roommate profile. You can unblock them later in Settings.'**
  String get blockUserBody;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked. Their content is hidden.'**
  String get userBlocked;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked.'**
  String get userUnblocked;

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get settingsSectionApp;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal & about'**
  String get settingsSectionLegal;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsBlockedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get settingsBlockedEmpty;

  /// No description provided for @xonadoshFinanceTab.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get xonadoshFinanceTab;

  /// No description provided for @xonadoshPollsTab.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get xonadoshPollsTab;

  /// No description provided for @xonadoshKarmaTab.
  ///
  /// In en, this message translates to:
  /// **'Karma'**
  String get xonadoshKarmaTab;

  /// No description provided for @accountDeletePasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to delete the account.'**
  String get accountDeletePasswordRequired;

  /// No description provided for @registerUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Username: 3+ letters, numbers, _ or .'**
  String get registerUsernameInvalid;

  /// No description provided for @registerPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get registerPhoneInvalid;

  /// No description provided for @xonadoshDeleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete listing'**
  String get xonadoshDeleteListing;

  /// No description provided for @xonadoshDeleteListingBody.
  ///
  /// In en, this message translates to:
  /// **'This listing will be hidden from the feed. You cannot undo this.'**
  String get xonadoshDeleteListingBody;

  /// No description provided for @xonadoshListingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted'**
  String get xonadoshListingDeleted;

  /// No description provided for @xonadoshFindRoom.
  ///
  /// In en, this message translates to:
  /// **'Find a room'**
  String get xonadoshFindRoom;

  /// No description provided for @xonadoshOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'What XonaDosh does'**
  String get xonadoshOnboardingTitle;

  /// No description provided for @xonadoshOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Three simple jobs — instead of messy OLX and Telegram groups.'**
  String get xonadoshOnboardingSubtitle;

  /// No description provided for @xonadoshJobHousingTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a room'**
  String get xonadoshJobHousingTitle;

  /// No description provided for @xonadoshJobHousingBody.
  ///
  /// In en, this message translates to:
  /// **'Student rentals near universities. See price, area, and metro.'**
  String get xonadoshJobHousingBody;

  /// No description provided for @xonadoshJobMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a roommate'**
  String get xonadoshJobMatchTitle;

  /// No description provided for @xonadoshJobMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Match on sleep, cleanliness, and budget — not just a phone number.'**
  String get xonadoshJobMatchBody;

  /// No description provided for @xonadoshJobColivingTitle.
  ///
  /// In en, this message translates to:
  /// **'Live together'**
  String get xonadoshJobColivingTitle;

  /// No description provided for @xonadoshJobColivingBody.
  ///
  /// In en, this message translates to:
  /// **'Chores, groceries, and bills — useful after you have a roommate.'**
  String get xonadoshJobColivingBody;

  /// No description provided for @xonadoshOnboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Let’s start'**
  String get xonadoshOnboardingStart;

  /// No description provided for @xonadoshEmptyMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get xonadoshEmptyMarketTitle;

  /// No description provided for @xonadoshEmptyMarketBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first. Post a room or a roommate request — no Telegram group needed.'**
  String get xonadoshEmptyMarketBody;

  /// No description provided for @xonadoshEmptyMatchesNeedProfile.
  ///
  /// In en, this message translates to:
  /// **'Fill in your university, budget, and habits so we can show who fits.'**
  String get xonadoshEmptyMatchesNeedProfile;

  /// No description provided for @xonadoshEmptyMatchesFiltered.
  ///
  /// In en, this message translates to:
  /// **'These filters hid everyone. Change university or gender, or clear them.'**
  String get xonadoshEmptyMatchesFiltered;

  /// No description provided for @xonadoshColivingUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Together tools'**
  String get xonadoshColivingUnlockTitle;

  /// No description provided for @xonadoshColivingUnlockTip.
  ///
  /// In en, this message translates to:
  /// **'Chores and groceries are here. Most useful after you have a room or roommate — still open to explore.'**
  String get xonadoshColivingUnlockTip;

  /// No description provided for @xonadoshWhyMatch.
  ///
  /// In en, this message translates to:
  /// **'Why this match'**
  String get xonadoshWhyMatch;

  /// No description provided for @xonadoshMatchFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Who are you looking for?'**
  String get xonadoshMatchFiltersLabel;

  /// No description provided for @xonadoshUniversityFilter.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get xonadoshUniversityFilter;

  /// No description provided for @xonadoshKmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} away'**
  String xonadoshKmAway(String km);

  /// No description provided for @xonadoshNearMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro {name}'**
  String xonadoshNearMetro(String name);

  /// No description provided for @xonadoshHousingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get xonadoshHousingHeroTitle;

  /// No description provided for @xonadoshFiltersOn.
  ///
  /// In en, this message translates to:
  /// **'Filters on'**
  String get xonadoshFiltersOn;

  /// No description provided for @xonadoshSearchFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Search filters'**
  String get xonadoshSearchFiltersTitle;

  /// No description provided for @xonadoshSeeResults.
  ///
  /// In en, this message translates to:
  /// **'See results'**
  String get xonadoshSeeResults;

  /// No description provided for @xonadoshAnyPrice.
  ///
  /// In en, this message translates to:
  /// **'Any price'**
  String get xonadoshAnyPrice;

  /// No description provided for @xonadoshRegionCity.
  ///
  /// In en, this message translates to:
  /// **'Region / city'**
  String get xonadoshRegionCity;

  /// No description provided for @xonadoshDistrictArea.
  ///
  /// In en, this message translates to:
  /// **'District / area'**
  String get xonadoshDistrictArea;

  /// No description provided for @xonadoshNearUniversity.
  ///
  /// In en, this message translates to:
  /// **'Near university'**
  String get xonadoshNearUniversity;

  /// No description provided for @xonadoshBudgetFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget (UZS)'**
  String get xonadoshBudgetFilterLabel;

  /// No description provided for @xonadoshWhoFor.
  ///
  /// In en, this message translates to:
  /// **'Who is it for'**
  String get xonadoshWhoFor;

  /// No description provided for @xonadoshTypeRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get xonadoshTypeRent;

  /// No description provided for @xonadoshTypeSell.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get xonadoshTypeSell;

  /// No description provided for @xonadoshTypeBuy.
  ///
  /// In en, this message translates to:
  /// **'Looking'**
  String get xonadoshTypeBuy;

  /// No description provided for @xonadoshMatchStudyMusic.
  ///
  /// In en, this message translates to:
  /// **'Study vibe matches (music / headphones)'**
  String get xonadoshMatchStudyMusic;

  /// No description provided for @xonadoshCallShort.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get xonadoshCallShort;

  /// No description provided for @xonadoshMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get xonadoshMoreDetails;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
