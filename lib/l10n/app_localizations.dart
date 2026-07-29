import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_te.dart';

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
    Locale('kn'),
    Locale('te')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shine Gold'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime from the menu.'**
  String get chooseLanguageSubtitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @changeLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English, Telugu, or Kannada'**
  String get changeLanguageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'తెలుగు'**
  String get telugu;

  /// No description provided for @kannada.
  ///
  /// In en, this message translates to:
  /// **'ಕನ್ನಡ'**
  String get kannada;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Shine Gold'**
  String get logoutSubtitle;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noData;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFarms.
  ///
  /// In en, this message translates to:
  /// **'Farms'**
  String get navFarms;

  /// No description provided for @navVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get navVisits;

  /// No description provided for @navOnboard.
  ///
  /// In en, this message translates to:
  /// **'Onboard'**
  String get navOnboard;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get navTeam;

  /// No description provided for @navHarvests.
  ///
  /// In en, this message translates to:
  /// **'Harvests'**
  String get navHarvests;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToShineGold.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Shine Gold'**
  String get signInToShineGold;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @useEmployeeCredentials.
  ///
  /// In en, this message translates to:
  /// **'Use your employee credentials'**
  String get useEmployeeCredentials;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @employeeIdHint.
  ///
  /// In en, this message translates to:
  /// **'EXEC001'**
  String get employeeIdHint;

  /// No description provided for @enterEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Enter employee ID'**
  String get enterEmployeeId;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid employee ID or password. Please check your credentials and try again.'**
  String get invalidCredentials;

  /// No description provided for @demoCredentials.
  ///
  /// In en, this message translates to:
  /// **'Demo: EXEC001 or ADMIN001 · ChangeMe123!'**
  String get demoCredentials;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request a password reset from your admin'**
  String get forgotPasswordSubtitle;

  /// No description provided for @requestReset.
  ///
  /// In en, this message translates to:
  /// **'Request reset'**
  String get requestReset;

  /// No description provided for @resetRequested.
  ///
  /// In en, this message translates to:
  /// **'Reset request submitted'**
  String get resetRequested;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get moreOptions;

  /// No description provided for @manageAdminWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Manage your admin workspace'**
  String get manageAdminWorkspace;

  /// No description provided for @nearbyFarms.
  ///
  /// In en, this message translates to:
  /// **'Nearby Farms'**
  String get nearbyFarms;

  /// No description provided for @nearbyFarmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Farms near you while travelling'**
  String get nearbyFarmsSubtitle;

  /// No description provided for @farmers.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get farmers;

  /// No description provided for @farmersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View all onboarded farmers'**
  String get farmersSubtitle;

  /// No description provided for @passwordResets.
  ///
  /// In en, this message translates to:
  /// **'Password Resets'**
  String get passwordResets;

  /// No description provided for @passwordResetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approve executive forgot-password requests'**
  String get passwordResetsSubtitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your admin account details'**
  String get profileSubtitle;

  /// No description provided for @fieldExecutive.
  ///
  /// In en, this message translates to:
  /// **'Field Executive'**
  String get fieldExecutive;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdmin;

  /// No description provided for @farmsVisited.
  ///
  /// In en, this message translates to:
  /// **'Farms Visited'**
  String get farmsVisited;

  /// No description provided for @onboarded.
  ///
  /// In en, this message translates to:
  /// **'Onboarded'**
  String get onboarded;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get sendTestNotification;

  /// No description provided for @testingNotification.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get testingNotification;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent'**
  String get testNotificationSent;

  /// No description provided for @homeLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Home location updated'**
  String get homeLocationUpdated;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdated;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @updateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update location'**
  String get updateLocation;

  /// No description provided for @setHomeLocation.
  ///
  /// In en, this message translates to:
  /// **'Set home location'**
  String get setHomeLocation;

  /// No description provided for @usedForNearbyFarms.
  ///
  /// In en, this message translates to:
  /// **'Used to show nearby farms'**
  String get usedForNearbyFarms;

  /// No description provided for @notSetNearbyFarms.
  ///
  /// In en, this message translates to:
  /// **'Not set — nearby farms need a GPS pin'**
  String get notSetNearbyFarms;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get refreshing;

  /// No description provided for @requesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting…'**
  String get requesting;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get enterManually;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @pinCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'PIN code (optional)'**
  String get pinCodeOptional;

  /// No description provided for @pinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled from suggestion when possible'**
  String get pinCodeHint;

  /// No description provided for @locateFromAddress.
  ///
  /// In en, this message translates to:
  /// **'Locate from address'**
  String get locateFromAddress;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get locating;

  /// No description provided for @fetchCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetch current location'**
  String get fetchCurrentLocation;

  /// No description provided for @fetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching…'**
  String get fetching;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get saveLocation;

  /// No description provided for @chooseHomeLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose how to set the pin used for nearby farms.'**
  String get chooseHomeLocation;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @farms.
  ///
  /// In en, this message translates to:
  /// **'Farms'**
  String get farms;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @harvests.
  ///
  /// In en, this message translates to:
  /// **'Harvests'**
  String get harvests;

  /// No description provided for @executives.
  ///
  /// In en, this message translates to:
  /// **'Executives'**
  String get executives;

  /// No description provided for @totalFarms.
  ///
  /// In en, this message translates to:
  /// **'Total farms'**
  String get totalFarms;

  /// No description provided for @totalAcres.
  ///
  /// In en, this message translates to:
  /// **'Total acres'**
  String get totalAcres;

  /// No description provided for @activeVisits.
  ///
  /// In en, this message translates to:
  /// **'Active visits'**
  String get activeVisits;

  /// No description provided for @pendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingApprovals;

  /// No description provided for @farmsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Farms Near You'**
  String get farmsNearYou;

  /// No description provided for @withinKmUpdates.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km · updates every 3 min'**
  String withinKmUpdates(String km);

  /// No description provided for @noFarmsNearby.
  ///
  /// In en, this message translates to:
  /// **'No farms nearby'**
  String get noFarmsNearby;

  /// No description provided for @noFarmsWithinKm.
  ///
  /// In en, this message translates to:
  /// **'No farms within {km} km of your current location.'**
  String noFarmsWithinKm(String km);

  /// No description provided for @closestFarmAway.
  ///
  /// In en, this message translates to:
  /// **'Closest farm is {km} km away.'**
  String closestFarmAway(String km);

  /// No description provided for @viewAllNearbyFarms.
  ///
  /// In en, this message translates to:
  /// **'View all {count} nearby farms'**
  String viewAllNearbyFarms(int count);

  /// No description provided for @refreshNearby.
  ///
  /// In en, this message translates to:
  /// **'Refresh nearby'**
  String get refreshNearby;

  /// No description provided for @withinKmRadius.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km radius'**
  String withinKmRadius(String km);

  /// No description provided for @turnOnLocationNearby.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see farms near you while travelling.'**
  String get turnOnLocationNearby;

  /// No description provided for @usingHomeLocation.
  ///
  /// In en, this message translates to:
  /// **'Using home location'**
  String get usingHomeLocation;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String lastUpdated(String time);

  /// No description provided for @myFarms.
  ///
  /// In en, this message translates to:
  /// **'My Farms'**
  String get myFarms;

  /// No description provided for @allFarms.
  ///
  /// In en, this message translates to:
  /// **'All Farms'**
  String get allFarms;

  /// No description provided for @searchFarms.
  ///
  /// In en, this message translates to:
  /// **'Search farms'**
  String get searchFarms;

  /// No description provided for @noFarmsFound.
  ///
  /// In en, this message translates to:
  /// **'No farms found'**
  String get noFarmsFound;

  /// No description provided for @farmDetails.
  ///
  /// In en, this message translates to:
  /// **'Farm details'**
  String get farmDetails;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @acres.
  ///
  /// In en, this message translates to:
  /// **'Acres'**
  String get acres;

  /// No description provided for @plants.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get plants;

  /// No description provided for @plantCount.
  ///
  /// In en, this message translates to:
  /// **'Plant count'**
  String get plantCount;

  /// No description provided for @aadhar.
  ///
  /// In en, this message translates to:
  /// **'Aadhar'**
  String get aadhar;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkIn;

  /// No description provided for @startVisit.
  ///
  /// In en, this message translates to:
  /// **'Start visit'**
  String get startVisit;

  /// No description provided for @visitReport.
  ///
  /// In en, this message translates to:
  /// **'Visit report'**
  String get visitReport;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @lastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last visit'**
  String get lastVisit;

  /// No description provided for @neverVisited.
  ///
  /// In en, this message translates to:
  /// **'Never visited'**
  String get neverVisited;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedTo;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distance(String km);

  /// No description provided for @sortNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby first'**
  String get sortNearby;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get sortName;

  /// No description provided for @sortFarthest.
  ///
  /// In en, this message translates to:
  /// **'Farthest first'**
  String get sortFarthest;

  /// No description provided for @myVisits.
  ///
  /// In en, this message translates to:
  /// **'My Visits'**
  String get myVisits;

  /// No description provided for @noVisitsYet.
  ///
  /// In en, this message translates to:
  /// **'No visits yet'**
  String get noVisitsYet;

  /// No description provided for @visitInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get visitInProgress;

  /// No description provided for @visitCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get visitCompleted;

  /// No description provided for @offlineVisitSynced.
  ///
  /// In en, this message translates to:
  /// **'{count} offline visit synced'**
  String offlineVisitSynced(int count);

  /// No description provided for @offlineVisitsSynced.
  ///
  /// In en, this message translates to:
  /// **'{count} offline visits synced'**
  String offlineVisitsSynced(int count);

  /// No description provided for @harvestReminderScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count} harvest reminder scheduled'**
  String harvestReminderScheduled(int count);

  /// No description provided for @harvestRemindersScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count} harvest reminders scheduled'**
  String harvestRemindersScheduled(int count);

  /// No description provided for @onboardFarm.
  ///
  /// In en, this message translates to:
  /// **'Onboard farm'**
  String get onboardFarm;

  /// No description provided for @onboardNewFarm.
  ///
  /// In en, this message translates to:
  /// **'Onboard a new farm'**
  String get onboardNewFarm;

  /// No description provided for @farmerName.
  ///
  /// In en, this message translates to:
  /// **'Farmer name'**
  String get farmerName;

  /// No description provided for @farmerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get farmerPhone;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm name'**
  String get farmName;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @pincode.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get pincode;

  /// No description provided for @drawBoundary.
  ///
  /// In en, this message translates to:
  /// **'Draw boundary'**
  String get drawBoundary;

  /// No description provided for @editBoundary.
  ///
  /// In en, this message translates to:
  /// **'Edit boundary'**
  String get editBoundary;

  /// No description provided for @boundarySaved.
  ///
  /// In en, this message translates to:
  /// **'Boundary saved'**
  String get boundarySaved;

  /// No description provided for @submitFarm.
  ///
  /// In en, this message translates to:
  /// **'Submit farm'**
  String get submitFarm;

  /// No description provided for @farmSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Farm submitted successfully'**
  String get farmSubmitted;

  /// No description provided for @selectLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select location on map'**
  String get selectLocationOnMap;

  /// No description provided for @tapToAddPoint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to add points'**
  String get tapToAddPoint;

  /// No description provided for @clearPoints.
  ///
  /// In en, this message translates to:
  /// **'Clear points'**
  String get clearPoints;

  /// No description provided for @undoPoint.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoPoint;

  /// No description provided for @confirmBoundary.
  ///
  /// In en, this message translates to:
  /// **'Confirm boundary'**
  String get confirmBoundary;

  /// No description provided for @checkInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkInTitle;

  /// No description provided for @checkInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm you are at the farm'**
  String get checkInSubtitle;

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get youAreHere;

  /// No description provided for @tooFarFromFarm.
  ///
  /// In en, this message translates to:
  /// **'You seem far from this farm'**
  String get tooFarFromFarm;

  /// No description provided for @confirmCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Confirm check-in'**
  String get confirmCheckIn;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get checkedIn;

  /// No description provided for @interactions.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get interactions;

  /// No description provided for @addInteraction.
  ///
  /// In en, this message translates to:
  /// **'Add interaction'**
  String get addInteraction;

  /// No description provided for @noInteractions.
  ///
  /// In en, this message translates to:
  /// **'No interactions yet'**
  String get noInteractions;

  /// No description provided for @interactionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get interactionNotes;

  /// No description provided for @saveInteraction.
  ///
  /// In en, this message translates to:
  /// **'Save interaction'**
  String get saveInteraction;

  /// No description provided for @farmInvitations.
  ///
  /// In en, this message translates to:
  /// **'Farm invitations'**
  String get farmInvitations;

  /// No description provided for @noInvitations.
  ///
  /// In en, this message translates to:
  /// **'No invitations'**
  String get noInvitations;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @passwordResetRequests.
  ///
  /// In en, this message translates to:
  /// **'Password reset requests'**
  String get passwordResetRequests;

  /// No description provided for @noPendingResets.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingResets;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @indiaMap.
  ///
  /// In en, this message translates to:
  /// **'India map'**
  String get indiaMap;

  /// No description provided for @fullscreenMap.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen map'**
  String get fullscreenMap;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @welcomeSplash.
  ///
  /// In en, this message translates to:
  /// **'Shine Gold'**
  String get welcomeSplash;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Organic Agro Invention'**
  String get welcomeTagline;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @formRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill required fields'**
  String get formRequired;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @recordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get recordAudio;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @playAudio.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playAudio;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed'**
  String get locationPermissionNeeded;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get pendingSync;

  /// No description provided for @acresLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} acres'**
  String acresLabel(String value);

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kmAway(String km);

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @emptyStateHint.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh or try again later'**
  String get emptyStateHint;

  /// No description provided for @adminProfile.
  ///
  /// In en, this message translates to:
  /// **'Admin profile'**
  String get adminProfile;

  /// No description provided for @executiveProfile.
  ///
  /// In en, this message translates to:
  /// **'Executive profile'**
  String get executiveProfile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @homeLocation.
  ///
  /// In en, this message translates to:
  /// **'Home location'**
  String get homeLocation;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @withinRadiusEmptyClosest.
  ///
  /// In en, this message translates to:
  /// **'No farms within {radius} km. Closest farm is {km} km away.'**
  String withinRadiusEmptyClosest(String radius, String km);

  /// No description provided for @nearbyFarmsWithinKm.
  ///
  /// In en, this message translates to:
  /// **'Farms within 5 km while travelling'**
  String get nearbyFarmsWithinKm;

  /// No description provided for @tapPhotoToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Tap your photo above to update it'**
  String get tapPhotoToUpdate;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @employeeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeIdLabel;

  /// No description provided for @adminApprovesPassword.
  ///
  /// In en, this message translates to:
  /// **'Admin approves — then you choose the new password'**
  String get adminApprovesPassword;

  /// No description provided for @resetApprovedSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Your reset was approved. Set a new password below.'**
  String get resetApprovedSetPassword;

  /// No description provided for @waitingAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for super admin approval. Tap refresh after they approve.'**
  String get waitingAdminApproval;

  /// No description provided for @requestResetSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Request a password reset\n2. Super admin approves (no temporary password)\n3. Set your new password here'**
  String get requestResetSteps;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @requestAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'Request already pending'**
  String get requestAlreadyPending;

  /// No description provided for @requestPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Request password reset'**
  String get requestPasswordReset;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get enterNewPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get confirmYourPassword;

  /// No description provided for @requestSentToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Request sent to admin. After they approve, you can set your new password here.'**
  String get requestSentToAdmin;

  /// No description provided for @adminMustApprove.
  ///
  /// In en, this message translates to:
  /// **'Admin must approve your reset request first.'**
  String get adminMustApprove;

  /// No description provided for @updateHomeLocation.
  ///
  /// In en, this message translates to:
  /// **'Update home location'**
  String get updateHomeLocation;

  /// No description provided for @pinReady.
  ///
  /// In en, this message translates to:
  /// **'Pin ready — tap Save'**
  String get pinReady;

  /// No description provided for @addressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find that address. Add city or PIN and try again.'**
  String get addressNotFound;

  /// No description provided for @gettingCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting current location…'**
  String get gettingCurrentLocation;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get current location. Enable GPS and try again.'**
  String get couldNotGetLocation;

  /// No description provided for @currentLocationReady.
  ///
  /// In en, this message translates to:
  /// **'Current location ready — tap Save'**
  String get currentLocationReady;

  /// No description provided for @locateBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Locate or fetch current location before saving'**
  String get locateBeforeSaving;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'Pin · {lat}, {lng}'**
  String pinLabel(String lat, String lng);

  /// No description provided for @weUseGps.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use your phone GPS and fill the address automatically.'**
  String get weUseGps;

  /// No description provided for @syncHarvestReminders.
  ///
  /// In en, this message translates to:
  /// **'Sync harvest reminders'**
  String get syncHarvestReminders;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @couldNotSyncReminders.
  ///
  /// In en, this message translates to:
  /// **'Could not sync harvest reminders. Check network and try again.'**
  String get couldNotSyncReminders;

  /// No description provided for @noUpcomingHarvests.
  ///
  /// In en, this message translates to:
  /// **'No upcoming harvests in the next 90 days.'**
  String get noUpcomingHarvests;

  /// No description provided for @harvestRemindersScheduledTest.
  ///
  /// In en, this message translates to:
  /// **'{count} harvest reminders scheduled. Test notification sent.'**
  String harvestRemindersScheduledTest(int count);

  /// No description provided for @oneHarvestReminderTest.
  ///
  /// In en, this message translates to:
  /// **'1 harvest reminder scheduled. Test notification sent.'**
  String get oneHarvestReminderTest;

  /// No description provided for @welcomeFieldIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Field intelligence for a greener harvest'**
  String get welcomeFieldIntelligence;

  /// No description provided for @checkingSession.
  ///
  /// In en, this message translates to:
  /// **'Checking your session…'**
  String get checkingSession;

  /// No description provided for @tapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to continue'**
  String get tapToContinue;

  /// No description provided for @stillConnecting.
  ///
  /// In en, this message translates to:
  /// **'Still connecting — first load can take a moment…'**
  String get stillConnecting;

  /// No description provided for @forgotYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password? Enter your employee ID — we will show the right next step.'**
  String get forgotYourPassword;

  /// No description provided for @requestAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'Request admin approval to reset your password.'**
  String get requestAdminApproval;

  /// No description provided for @requestWithAdmin.
  ///
  /// In en, this message translates to:
  /// **'Your request is with the super admin.'**
  String get requestWithAdmin;

  /// No description provided for @adminApprovedChoose.
  ///
  /// In en, this message translates to:
  /// **'Admin approved your reset. Choose a new password.'**
  String get adminApprovedChoose;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @statusPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Status: Pending approval'**
  String get statusPendingApproval;

  /// No description provided for @adminNotApprovedYet.
  ///
  /// In en, this message translates to:
  /// **'Super admin has not approved yet. Tap refresh after they approve.'**
  String get adminNotApprovedYet;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Status: Approved'**
  String get statusApproved;

  /// No description provided for @setNewPasswordNoLogin.
  ///
  /// In en, this message translates to:
  /// **'You can set a new password now. No login or temporary password needed.'**
  String get setNewPasswordNoLogin;

  /// No description provided for @requestPasswordResetButton.
  ///
  /// In en, this message translates to:
  /// **'Request password reset'**
  String get requestPasswordResetButton;

  /// No description provided for @refreshStatusButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatusButton;

  /// No description provided for @passwordUpdatedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in with your new password.'**
  String get passwordUpdatedSignIn;

  /// No description provided for @enterYourEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Enter your employee ID.'**
  String get enterYourEmployeeId;

  /// No description provided for @shineGoldOverview.
  ///
  /// In en, this message translates to:
  /// **'Shine Gold overview'**
  String get shineGoldOverview;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operations;

  /// No description provided for @registeredFarms.
  ///
  /// In en, this message translates to:
  /// **'REGISTERED FARMS'**
  String get registeredFarms;

  /// No description provided for @activeFarmsInNetwork.
  ///
  /// In en, this message translates to:
  /// **'Active farms in the network'**
  String get activeFarmsInNetwork;

  /// No description provided for @fieldExecutives.
  ///
  /// In en, this message translates to:
  /// **'FIELD EXECUTIVES'**
  String get fieldExecutives;

  /// No description provided for @teamMembersOnGround.
  ///
  /// In en, this message translates to:
  /// **'Team members on ground'**
  String get teamMembersOnGround;

  /// No description provided for @visitsLogged.
  ///
  /// In en, this message translates to:
  /// **'VISITS LOGGED'**
  String get visitsLogged;

  /// No description provided for @completedAndOngoingVisits.
  ///
  /// In en, this message translates to:
  /// **'Completed & ongoing visits'**
  String get completedAndOngoingVisits;

  /// No description provided for @combinedFarmAcreage.
  ///
  /// In en, this message translates to:
  /// **'Combined farm acreage'**
  String get combinedFarmAcreage;

  /// No description provided for @farmersOnboardedLabel.
  ///
  /// In en, this message translates to:
  /// **'FARMERS ONBOARDED'**
  String get farmersOnboardedLabel;

  /// No description provided for @newFarmersThisSeason.
  ///
  /// In en, this message translates to:
  /// **'New farmers this season'**
  String get newFarmersThisSeason;

  /// No description provided for @fieldTeam.
  ///
  /// In en, this message translates to:
  /// **'Field Team'**
  String get fieldTeam;

  /// No description provided for @xMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String xMembers(int count);

  /// No description provided for @xVisits.
  ///
  /// In en, this message translates to:
  /// **'{count} visits'**
  String xVisits(int count);

  /// No description provided for @createFarm.
  ///
  /// In en, this message translates to:
  /// **'Create Farm'**
  String get createFarm;

  /// No description provided for @xFarmsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} farms total'**
  String xFarmsTotal(int count);

  /// No description provided for @searchFarmsEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Search farms...'**
  String get searchFarmsEllipsis;

  /// No description provided for @addExecutive.
  ///
  /// In en, this message translates to:
  /// **'Add Executive'**
  String get addExecutive;

  /// No description provided for @addressPinLocateInfo.
  ///
  /// In en, this message translates to:
  /// **'Address + PIN must Locate successfully so home GPS is stored.'**
  String get addressPinLocateInfo;

  /// No description provided for @createExecutive.
  ///
  /// In en, this message translates to:
  /// **'Create Executive'**
  String get createExecutive;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @tenDigitMobile.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile'**
  String get tenDigitMobile;

  /// No description provided for @mobileNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileNumberRequired;

  /// No description provided for @enterValidMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get enterValidMobileNumber;

  /// No description provided for @startTypingToSearch.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search address'**
  String get startTypingToSearch;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @enterFullerAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a fuller address (street / area / city)'**
  String get enterFullerAddress;

  /// No description provided for @includeLocalityCity.
  ///
  /// In en, this message translates to:
  /// **'Include locality and city'**
  String get includeLocalityCity;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get pinCode;

  /// No description provided for @autoFilledFromSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled from suggestion when possible'**
  String get autoFilledFromSuggestion;

  /// No description provided for @pinCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'PIN code is required'**
  String get pinCodeRequired;

  /// No description provided for @enterValid6DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit PIN'**
  String get enterValid6DigitPin;

  /// No description provided for @enterValidIndianPin.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Indian PIN code'**
  String get enterValidIndianPin;

  /// No description provided for @homeGpsPinRequired.
  ///
  /// In en, this message translates to:
  /// **'Home GPS pin (required)'**
  String get homeGpsPinRequired;

  /// No description provided for @tapLocateAfterAddress.
  ///
  /// In en, this message translates to:
  /// **'Tap Locate after entering address + PIN. Create stays blocked until the pin is verified.'**
  String get tapLocateAfterAddress;

  /// No description provided for @locateAndVerifyAddress.
  ///
  /// In en, this message translates to:
  /// **'Locate & verify address'**
  String get locateAndVerifyAddress;

  /// No description provided for @reVerifyAddress.
  ///
  /// In en, this message translates to:
  /// **'Re-verify address'**
  String get reVerifyAddress;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @atLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Characters;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMustBe6Chars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBe6Chars;

  /// No description provided for @executiveCreated.
  ///
  /// In en, this message translates to:
  /// **'Executive created successfully'**
  String get executiveCreated;

  /// No description provided for @executiveCreatedWithId.
  ///
  /// In en, this message translates to:
  /// **'Executive created — ID: {id}'**
  String executiveCreatedWithId(String id);

  /// No description provided for @xOfYExecutives.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} executives'**
  String xOfYExecutives(int filtered, int total);

  /// No description provided for @searchByNameIdMobile.
  ///
  /// In en, this message translates to:
  /// **'Search by name, ID, or mobile...'**
  String get searchByNameIdMobile;

  /// No description provided for @noExecutives.
  ///
  /// In en, this message translates to:
  /// **'No executives'**
  String get noExecutives;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @addFirstExecutive.
  ///
  /// In en, this message translates to:
  /// **'Add your first field executive'**
  String get addFirstExecutive;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @addressCouldNotVerify.
  ///
  /// In en, this message translates to:
  /// **'Address could not be verified on the map. Improve address/PIN, tap Locate, then create again.'**
  String get addressCouldNotVerify;

  /// No description provided for @couldNotVerifyAddress.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify this address. Add clearer area/city + correct PIN, then try again.'**
  String get couldNotVerifyAddress;

  /// No description provided for @locateBeforeCreating.
  ///
  /// In en, this message translates to:
  /// **'Locate & verify address before creating'**
  String get locateBeforeCreating;

  /// No description provided for @enterAddressFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter an address first'**
  String get enterAddressFirst;

  /// No description provided for @enterPinFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit PIN code first'**
  String get enterPinFirst;

  /// No description provided for @pinMustBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'PIN code must be a 6-digit number'**
  String get pinMustBe6Digits;

  /// No description provided for @fieldExecutiveId.
  ///
  /// In en, this message translates to:
  /// **'Field Executive · {id}'**
  String fieldExecutiveId(String id);

  /// No description provided for @assignedFarms.
  ///
  /// In en, this message translates to:
  /// **'Assigned Farms'**
  String get assignedFarms;

  /// No description provided for @xFarms.
  ///
  /// In en, this message translates to:
  /// **'{count} farms'**
  String xFarms(int count);

  /// No description provided for @noFarmsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No farms assigned yet'**
  String get noFarmsAssigned;

  /// No description provided for @visitHistory.
  ///
  /// In en, this message translates to:
  /// **'Visit History'**
  String get visitHistory;

  /// No description provided for @xRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String xRecords(int count);

  /// No description provided for @searchVisitsByFarm.
  ///
  /// In en, this message translates to:
  /// **'Search visits by farm name...'**
  String get searchVisitsByFarm;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @executiveHasNoVisits.
  ///
  /// In en, this message translates to:
  /// **'This executive has no visit records'**
  String get executiveHasNoVisits;

  /// No description provided for @tryDifferentFarmName.
  ///
  /// In en, this message translates to:
  /// **'Try a different farm name'**
  String get tryDifferentFarmName;

  /// No description provided for @unblockExecutive.
  ///
  /// In en, this message translates to:
  /// **'Unblock executive'**
  String get unblockExecutive;

  /// No description provided for @blockExecutive.
  ///
  /// In en, this message translates to:
  /// **'Block executive'**
  String get blockExecutive;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @onboardingCoverage.
  ///
  /// In en, this message translates to:
  /// **'Onboarding coverage'**
  String get onboardingCoverage;

  /// No description provided for @oneFarmOnboarded.
  ///
  /// In en, this message translates to:
  /// **'1 farm onboarded · {acres} acres'**
  String oneFarmOnboarded(String acres);

  /// No description provided for @xFarmsOnboarded.
  ///
  /// In en, this message translates to:
  /// **'{count} farms onboarded · {acres} acres'**
  String xFarmsOnboarded(int count, String acres);

  /// No description provided for @xMinOnSite.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min on site'**
  String xMinOnSite(int minutes);

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @lastVisitDate.
  ///
  /// In en, this message translates to:
  /// **'Last visit: {date}'**
  String lastVisitDate(String date);

  /// No description provided for @notVisitedYet.
  ///
  /// In en, this message translates to:
  /// **'Not visited yet'**
  String get notVisitedYet;

  /// No description provided for @xScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count} scheduled'**
  String xScheduled(int count);

  /// No description provided for @searchHarvestsByCrop.
  ///
  /// In en, this message translates to:
  /// **'Search harvests by farm or crop...'**
  String get searchHarvestsByCrop;

  /// No description provided for @harvestsOnDate.
  ///
  /// In en, this message translates to:
  /// **'Harvests on {day}/{month}/{year}'**
  String harvestsOnDate(int day, int month, int year);

  /// No description provided for @noHarvests.
  ///
  /// In en, this message translates to:
  /// **'No harvests'**
  String get noHarvests;

  /// No description provided for @nothingScheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled for this date'**
  String get nothingScheduledDate;

  /// No description provided for @xOfYFarmers.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} farmers'**
  String xOfYFarmers(int filtered, int total);

  /// No description provided for @searchFarmersFarms.
  ///
  /// In en, this message translates to:
  /// **'Search farmers, farms, or location...'**
  String get searchFarmersFarms;

  /// No description provided for @noFarmers.
  ///
  /// In en, this message translates to:
  /// **'No farmers'**
  String get noFarmers;

  /// No description provided for @onboardedFarmersAppear.
  ///
  /// In en, this message translates to:
  /// **'Onboarded farmers will appear here'**
  String get onboardedFarmersAppear;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @xYears.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String xYears(int age);

  /// No description provided for @linkedFarms.
  ///
  /// In en, this message translates to:
  /// **'Linked Farms'**
  String get linkedFarms;

  /// No description provided for @noFarmLinked.
  ///
  /// In en, this message translates to:
  /// **'No farm linked to this farmer yet.'**
  String get noFarmLinked;

  /// No description provided for @cropLabel.
  ///
  /// In en, this message translates to:
  /// **'Crop: {crop}'**
  String cropLabel(String crop);

  /// No description provided for @cropNotSet.
  ///
  /// In en, this message translates to:
  /// **'Crop not set'**
  String get cropNotSet;

  /// No description provided for @oneFarm.
  ///
  /// In en, this message translates to:
  /// **'1 farm'**
  String get oneFarm;

  /// No description provided for @farmsNearYouLabel.
  ///
  /// In en, this message translates to:
  /// **'Farms Near You'**
  String get farmsNearYouLabel;

  /// No description provided for @withinKmUpdates3min.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km · updates every 3 min'**
  String withinKmUpdates3min(String km);

  /// No description provided for @refreshNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh now'**
  String get refreshNow;

  /// No description provided for @locationActive.
  ///
  /// In en, this message translates to:
  /// **'Location active'**
  String get locationActive;

  /// No description provided for @usingYourHomeLocation.
  ///
  /// In en, this message translates to:
  /// **'Using your home location'**
  String get usingYourHomeLocation;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location…'**
  String get gettingLocation;

  /// No description provided for @waitingForGpsFix.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS fix'**
  String get waitingForGpsFix;

  /// No description provided for @locationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location needed'**
  String get locationNeeded;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @updatedTime.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedTime(String time);

  /// No description provided for @latLngLabel.
  ///
  /// In en, this message translates to:
  /// **'Lat {lat}, Lng {lng}'**
  String latLngLabel(String lat, String lng);

  /// No description provided for @noFarmsWithinKmLocation.
  ///
  /// In en, this message translates to:
  /// **'No farms within {km} km of your current location.'**
  String noFarmsWithinKmLocation(String km);

  /// No description provided for @noFarmsClosestAway.
  ///
  /// In en, this message translates to:
  /// **'No farms within {km} km. Closest farm is {closest} km away.'**
  String noFarmsClosestAway(String km, String closest);

  /// No description provided for @viewAllXNearbyFarms.
  ///
  /// In en, this message translates to:
  /// **'View all {count} nearby farms'**
  String viewAllXNearbyFarms(int count);

  /// No description provided for @openFullMapList.
  ///
  /// In en, this message translates to:
  /// **'Open full map list'**
  String get openFullMapList;

  /// No description provided for @noFarmsNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'No farms nearby'**
  String get noFarmsNearbyTitle;

  /// No description provided for @noFarmsFoundNearPosition.
  ///
  /// In en, this message translates to:
  /// **'No farms found near your current position yet.'**
  String get noFarmsFoundNearPosition;

  /// No description provided for @closestFarmOutsideRadius.
  ///
  /// In en, this message translates to:
  /// **'Closest farm is {km} km away (outside the {radius} km radius).'**
  String closestFarmOutsideRadius(String km, String radius);

  /// No description provided for @reviewPasswordResetRequests.
  ///
  /// In en, this message translates to:
  /// **'Review executive password-reset requests. Approve so they can set a new password themselves.'**
  String get reviewPasswordResetRequests;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @allRequests.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allRequests;

  /// No description provided for @couldNotLoadRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests'**
  String get couldNotLoadRequests;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @noResetRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No reset requests yet'**
  String get noResetRequestsYet;

  /// No description provided for @requestsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Requests from the forgot-password screen will appear here.'**
  String get requestsAppearHere;

  /// No description provided for @approvedPendingShow.
  ///
  /// In en, this message translates to:
  /// **'Approved and pending requests will show in this list.'**
  String get approvedPendingShow;

  /// No description provided for @approvePasswordResetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Approve password reset?'**
  String get approvePasswordResetQuestion;

  /// No description provided for @allowUserSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Allow {name} ({id}) to set a new password from their profile. You will not set a temporary password.'**
  String allowUserSetPassword(String name, String id);

  /// No description provided for @approvedUserCanSet.
  ///
  /// In en, this message translates to:
  /// **'Approved — {id} can now set a new password'**
  String approvedUserCanSet(String id);

  /// No description provided for @requestedDate.
  ///
  /// In en, this message translates to:
  /// **'Requested {date}'**
  String requestedDate(String date);

  /// No description provided for @superAdminId.
  ///
  /// In en, this message translates to:
  /// **'Super Admin · {id}'**
  String superAdminId(String id);

  /// No description provided for @tapPhotoToUpdateIt.
  ///
  /// In en, this message translates to:
  /// **'Tap your photo above to update it'**
  String get tapPhotoToUpdateIt;

  /// No description provided for @editMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Mobile Number'**
  String get editMobileNumber;

  /// No description provided for @updateContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Update your contact number'**
  String get updateContactNumber;

  /// No description provided for @saveMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Save Mobile Number'**
  String get saveMobileNumber;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get enterMobileNumber;

  /// No description provided for @enterValidMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number'**
  String get enterValidMobile;

  /// No description provided for @mobileNumberUpdated.
  ///
  /// In en, this message translates to:
  /// **'Mobile number updated'**
  String get mobileNumberUpdated;

  /// No description provided for @editOfficeAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Office Address'**
  String get editOfficeAddress;

  /// No description provided for @updateAdminAddress.
  ///
  /// In en, this message translates to:
  /// **'Update your administrator address'**
  String get updateAdminAddress;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// No description provided for @officeAddress.
  ///
  /// In en, this message translates to:
  /// **'Office Address'**
  String get officeAddress;

  /// No description provided for @enterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enterYourAddress;

  /// No description provided for @officeAddressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Office address updated'**
  String get officeAddressUpdated;

  /// No description provided for @chooseNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your admin account'**
  String get chooseNewPassword;

  /// No description provided for @passwordMustBe6CharsLong.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBe6CharsLong;

  /// No description provided for @confirmNewPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get confirmNewPasswordPrompt;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchError;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @superAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Super Administrator'**
  String get superAdministrator;

  /// No description provided for @managingShineGold.
  ///
  /// In en, this message translates to:
  /// **'Managing Shine Gold operations'**
  String get managingShineGold;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @hiName.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String hiName(String name);

  /// No description provided for @recordConversations.
  ///
  /// In en, this message translates to:
  /// **'Record conversations with farmers you want to onboard'**
  String get recordConversations;

  /// No description provided for @farmsYouOnboarded.
  ///
  /// In en, this message translates to:
  /// **'Farms you onboarded'**
  String get farmsYouOnboarded;

  /// No description provided for @noFarmsOnboardedYet.
  ///
  /// In en, this message translates to:
  /// **'No farms onboarded yet'**
  String get noFarmsOnboardedYet;

  /// No description provided for @farmsFromOnboardTab.
  ///
  /// In en, this message translates to:
  /// **'Farms you add from the Onboard tab will show here'**
  String get farmsFromOnboardTab;

  /// No description provided for @moreOnboardedFarms.
  ///
  /// In en, this message translates to:
  /// **'+{count} more onboarded farms'**
  String moreOnboardedFarms(int count);

  /// No description provided for @noPriorityFarms.
  ///
  /// In en, this message translates to:
  /// **'No priority farms'**
  String get noPriorityFarms;

  /// No description provided for @pendingVisitsToday.
  ///
  /// In en, this message translates to:
  /// **'Pending visits for today will show up here'**
  String get pendingVisitsToday;

  /// No description provided for @farmsForToday.
  ///
  /// In en, this message translates to:
  /// **'Farms for today'**
  String get farmsForToday;

  /// No description provided for @tapToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to view details'**
  String get tapToViewDetails;

  /// No description provided for @harvest.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get harvest;

  /// No description provided for @assignedFarmsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} assigned farms'**
  String assignedFarmsCount(int count);

  /// No description provided for @nearbyUnassignedFarms.
  ///
  /// In en, this message translates to:
  /// **'Nearby unassigned farms'**
  String get nearbyUnassignedFarms;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @nearbyFirst.
  ///
  /// In en, this message translates to:
  /// **'Nearby first'**
  String get nearbyFirst;

  /// No description provided for @farthestFirst.
  ///
  /// In en, this message translates to:
  /// **'Farthest first'**
  String get farthestFirst;

  /// No description provided for @nameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get nameAZ;

  /// No description provided for @searchFarmFarmerMobile.
  ///
  /// In en, this message translates to:
  /// **'Search farm, farmer, mobile...'**
  String get searchFarmFarmerMobile;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @nearbyFarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Farms'**
  String get nearbyFarmsTitle;

  /// No description provided for @unassignedFarmsWithinKm.
  ///
  /// In en, this message translates to:
  /// **'{count} unassigned farms within 70 km'**
  String unassignedFarmsWithinKm(int count);

  /// No description provided for @noNearbyInvitations.
  ///
  /// In en, this message translates to:
  /// **'No nearby invitations'**
  String get noNearbyInvitations;

  /// No description provided for @unassignedFarmsDescription.
  ///
  /// In en, this message translates to:
  /// **'Unassigned farms within 70 km of your home location will appear here. Set your home location in Profile if needed.'**
  String get unassignedFarmsDescription;

  /// No description provided for @farmerPrefix.
  ///
  /// In en, this message translates to:
  /// **'Farmer: {name}'**
  String farmerPrefix(String name);

  /// No description provided for @kmAwayLabel.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kmAwayLabel(String km);

  /// No description provided for @acceptAssignment.
  ///
  /// In en, this message translates to:
  /// **'Accept Assignment'**
  String get acceptAssignment;

  /// No description provided for @farmAddedToYourFarms.
  ///
  /// In en, this message translates to:
  /// **'{farmName} added to your farms'**
  String farmAddedToYourFarms(String farmName);

  /// No description provided for @farmSummary.
  ///
  /// In en, this message translates to:
  /// **'Farm Summary'**
  String get farmSummary;

  /// No description provided for @harvestInformation.
  ///
  /// In en, this message translates to:
  /// **'Harvest Information'**
  String get harvestInformation;

  /// No description provided for @setHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'SET HARVEST DATE'**
  String get setHarvestDate;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @harvestStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Harvest Status'**
  String get harvestStatusLabel;

  /// No description provided for @updateHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'Update harvest date'**
  String get updateHarvestDate;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @harvestDateHistory.
  ///
  /// In en, this message translates to:
  /// **'Harvest date history'**
  String get harvestDateHistory;

  /// No description provided for @byLabel.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get byLabel;

  /// No description provided for @mapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapLabel;

  /// No description provided for @farmPhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm Photos'**
  String get farmPhotosLabel;

  /// No description provided for @noVisitsRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No visits recorded yet'**
  String get noVisitsRecordedYet;

  /// No description provided for @continueVisit.
  ///
  /// In en, this message translates to:
  /// **'Continue Visit'**
  String get continueVisit;

  /// No description provided for @updateHarvestDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update harvest date'**
  String get updateHarvestDateTitle;

  /// No description provided for @currentHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'Current: {date}'**
  String currentHarvestDate(String date);

  /// No description provided for @currentNotSet.
  ///
  /// In en, this message translates to:
  /// **'Current: Not set'**
  String get currentNotSet;

  /// No description provided for @tapToPickNewDate.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick a new date'**
  String get tapToPickNewDate;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @whyHarvestDateChanging.
  ///
  /// In en, this message translates to:
  /// **'Why is the harvest date changing?'**
  String get whyHarvestDateChanging;

  /// No description provided for @saveHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'Save harvest date'**
  String get saveHarvestDate;

  /// No description provided for @harvestDateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Harvest date updated'**
  String get harvestDateUpdated;

  /// No description provided for @pickDifferentDateToSave.
  ///
  /// In en, this message translates to:
  /// **'Pick a different date to save a change'**
  String get pickDifferentDateToSave;

  /// No description provided for @farmNotFound.
  ///
  /// In en, this message translates to:
  /// **'Farm not found.'**
  String get farmNotFound;

  /// No description provided for @noMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'No mobile number'**
  String get noMobileNumber;

  /// No description provided for @aadharPrefix.
  ///
  /// In en, this message translates to:
  /// **'Aadhar: {number}'**
  String aadharPrefix(String number);

  /// No description provided for @assignExecutives.
  ///
  /// In en, this message translates to:
  /// **'Assign executives'**
  String get assignExecutives;

  /// No description provided for @executivesLabel.
  ///
  /// In en, this message translates to:
  /// **'Executives'**
  String get executivesLabel;

  /// No description provided for @executiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Executive'**
  String get executiveLabel;

  /// No description provided for @farmVisit.
  ///
  /// In en, this message translates to:
  /// **'Farm Visit'**
  String get farmVisit;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @reportLabel.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportLabel;

  /// No description provided for @mediaLabel.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaLabel;

  /// No description provided for @offlineAnswersStayOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Offline — answers & media stay on this device until sync'**
  String get offlineAnswersStayOnDevice;

  /// No description provided for @startVisitButton.
  ///
  /// In en, this message translates to:
  /// **'Start Visit'**
  String get startVisitButton;

  /// No description provided for @checkinRecordsTimeLocation.
  ///
  /// In en, this message translates to:
  /// **'Check-in records your time and location. You will then complete the field visit report.'**
  String get checkinRecordsTimeLocation;

  /// No description provided for @continueToMedia.
  ///
  /// In en, this message translates to:
  /// **'Continue to Media'**
  String get continueToMedia;

  /// No description provided for @photosAndVoice.
  ///
  /// In en, this message translates to:
  /// **'Photos & Voice'**
  String get photosAndVoice;

  /// No description provided for @optionalPhotosVoice.
  ///
  /// In en, this message translates to:
  /// **'Optional — up to 5 geotagged photos and a voice note (max 2:30)'**
  String get optionalPhotosVoice;

  /// No description provided for @reviewAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewAndSubmit;

  /// No description provided for @reviewVisit.
  ///
  /// In en, this message translates to:
  /// **'Review Visit'**
  String get reviewVisit;

  /// No description provided for @reportFields.
  ///
  /// In en, this message translates to:
  /// **'Report fields'**
  String get reportFields;

  /// No description provided for @requiredFieldsCount.
  ///
  /// In en, this message translates to:
  /// **'{answered} / {required} required'**
  String requiredFieldsCount(int answered, int required);

  /// No description provided for @photosAttachedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attached'**
  String photosAttachedCount(int count);

  /// No description provided for @voiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get voiceNote;

  /// No description provided for @marked.
  ///
  /// In en, this message translates to:
  /// **'Marked'**
  String get marked;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @submitVisit.
  ///
  /// In en, this message translates to:
  /// **'Submit Visit'**
  String get submitVisit;

  /// No description provided for @requiredFieldNeedsAnswer.
  ///
  /// In en, this message translates to:
  /// **'1 required field still needs your answer'**
  String get requiredFieldNeedsAnswer;

  /// No description provided for @requiredFieldsNeedAnswers.
  ///
  /// In en, this message translates to:
  /// **'{count} required fields still need your answers'**
  String requiredFieldsNeedAnswers(int count);

  /// No description provided for @requiredFieldNeedAnswerBelow.
  ///
  /// In en, this message translates to:
  /// **'1 required field needs your answer below'**
  String get requiredFieldNeedAnswerBelow;

  /// No description provided for @requiredFieldsNeedAnswersBelow.
  ///
  /// In en, this message translates to:
  /// **'{count} required fields need your answers below'**
  String requiredFieldsNeedAnswersBelow(int count);

  /// No description provided for @voiceNoteMarked.
  ///
  /// In en, this message translates to:
  /// **'Voice note marked'**
  String get voiceNoteMarked;

  /// No description provided for @voiceNoteAutoSaved.
  ///
  /// In en, this message translates to:
  /// **'Voice note auto-saved at the 2:30 limit'**
  String get voiceNoteAutoSaved;

  /// No description provided for @offlineModeSyncLater.
  ///
  /// In en, this message translates to:
  /// **'Offline mode — visit will sync when internet returns'**
  String get offlineModeSyncLater;

  /// No description provided for @noInternetFarmNotCached.
  ///
  /// In en, this message translates to:
  /// **'No internet and this farm is not cached yet. Open the farm once while online, then try again.'**
  String get noInternetFarmNotCached;

  /// No description provided for @noInternetNoFormCached.
  ///
  /// In en, this message translates to:
  /// **'No internet and no saved visit form yet. Complete one online visit first so the form can be cached.'**
  String get noInternetNoFormCached;

  /// No description provided for @couldNotCancelVisit.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel visit: {error}'**
  String couldNotCancelVisit(String error);

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record'**
  String get microphonePermissionRequired;

  /// No description provided for @couldNotStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording: {error}'**
  String couldNotStartRecording(String error);

  /// No description provided for @couldNotStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Could not stop recording: {error}'**
  String couldNotStopRecording(String error);

  /// No description provided for @voiceSavedLocallyWillUpload.
  ///
  /// In en, this message translates to:
  /// **'Voice saved locally — will upload when online'**
  String get voiceSavedLocallyWillUpload;

  /// No description provided for @voiceUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice upload failed: {error}'**
  String voiceUploadFailed(String error);

  /// No description provided for @maximum5PhotosAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 photos allowed'**
  String get maximum5PhotosAllowed;

  /// No description provided for @visitSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Visit submitted successfully'**
  String get visitSubmittedSuccessfully;

  /// No description provided for @visitSavedOfflineSyncLater.
  ///
  /// In en, this message translates to:
  /// **'Visit saved offline. It will sync automatically when internet returns.'**
  String get visitSavedOfflineSyncLater;

  /// No description provided for @myVisitsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Visits'**
  String get myVisitsTitle;

  /// No description provided for @visitRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} visit records'**
  String visitRecordsCount(int count);

  /// No description provided for @visitsWaitingToSync.
  ///
  /// In en, this message translates to:
  /// **'{count} visits · {pending} waiting to sync'**
  String visitsWaitingToSync(int count, int pending);

  /// No description provided for @syncingOfflineVisits.
  ///
  /// In en, this message translates to:
  /// **'Syncing offline visits — this can take a few minutes on a slow connection…'**
  String get syncingOfflineVisits;

  /// No description provided for @searchByFarmName.
  ///
  /// In en, this message translates to:
  /// **'Search by farm name...'**
  String get searchByFarmName;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @ongoingLabel.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoingLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @yourFarmVisitsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your farm visits will appear here'**
  String get yourFarmVisitsAppearHere;

  /// No description provided for @offlineVisitSyncedSingular.
  ///
  /// In en, this message translates to:
  /// **'1 offline visit synced'**
  String get offlineVisitSyncedSingular;

  /// No description provided for @offlineVisitsSyncedPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} offline visits synced'**
  String offlineVisitsSyncedPlural(int count);

  /// No description provided for @stillOfflineSyncRetryLater.
  ///
  /// In en, this message translates to:
  /// **'Still offline — sync will retry later'**
  String get stillOfflineSyncRetryLater;

  /// No description provided for @nothingWaitingToSync.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting to sync'**
  String get nothingWaitingToSync;

  /// No description provided for @savedOnDeviceTapToSync.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device · tap to sync now'**
  String get savedOnDeviceTapToSync;

  /// No description provided for @onboardFarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Onboard farm'**
  String get onboardFarmTitle;

  /// No description provided for @farmCreated.
  ///
  /// In en, this message translates to:
  /// **'Farm Created!'**
  String get farmCreated;

  /// No description provided for @farmOnboardedExclaim.
  ///
  /// In en, this message translates to:
  /// **'Farm Onboarded!'**
  String get farmOnboardedExclaim;

  /// No description provided for @farmAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'The farm has been added successfully.'**
  String get farmAddedSuccessfully;

  /// No description provided for @viewDashboard.
  ///
  /// In en, this message translates to:
  /// **'View dashboard'**
  String get viewDashboard;

  /// No description provided for @onboardAnother.
  ///
  /// In en, this message translates to:
  /// **'Onboard Another'**
  String get onboardAnother;

  /// No description provided for @nextFarmerDetails.
  ///
  /// In en, this message translates to:
  /// **'Next: Farmer Details'**
  String get nextFarmerDetails;

  /// No description provided for @farmNameInput.
  ///
  /// In en, this message translates to:
  /// **'Farm Name'**
  String get farmNameInput;

  /// No description provided for @editFarmBoundary.
  ///
  /// In en, this message translates to:
  /// **'Edit farm boundary'**
  String get editFarmBoundary;

  /// No description provided for @markFarmBoundaryOnMap.
  ///
  /// In en, this message translates to:
  /// **'Mark farm boundary on map'**
  String get markFarmBoundaryOnMap;

  /// No description provided for @yourLocationShownOnMap.
  ///
  /// In en, this message translates to:
  /// **'Your location shown on map · {pins} boundary pins · {acres} acres'**
  String yourLocationShownOnMap(int pins, String acres);

  /// No description provided for @yourCurrentGpsShown.
  ///
  /// In en, this message translates to:
  /// **'Your current GPS is shown on the map — tap the button to mark boundary pins'**
  String get yourCurrentGpsShown;

  /// No description provided for @waitingForGpsEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS… enable location to center the map on you'**
  String get waitingForGpsEnableLocation;

  /// No description provided for @locationAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Location address (optional)'**
  String get locationAddressOptional;

  /// No description provided for @locationAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Area, city, PIN — display only; map pin drives distance'**
  String get locationAddressHint;

  /// No description provided for @cropInput.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get cropInput;

  /// No description provided for @harvestTypeInput.
  ///
  /// In en, this message translates to:
  /// **'Harvest Type'**
  String get harvestTypeInput;

  /// No description provided for @harvestDateInput.
  ///
  /// In en, this message translates to:
  /// **'Harvest Date'**
  String get harvestDateInput;

  /// No description provided for @totalAcresInput.
  ///
  /// In en, this message translates to:
  /// **'Total Acres'**
  String get totalAcresInput;

  /// No description provided for @calculatedFromBoundary.
  ///
  /// In en, this message translates to:
  /// **'Calculated from boundary pins'**
  String get calculatedFromBoundary;

  /// No description provided for @numberOfPlantsInput.
  ///
  /// In en, this message translates to:
  /// **'Number of Plants'**
  String get numberOfPlantsInput;

  /// No description provided for @totalPlantsOnFarm.
  ///
  /// In en, this message translates to:
  /// **'Total plants on this farm'**
  String get totalPlantsOnFarm;

  /// No description provided for @farmPhotosSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm Photos'**
  String get farmPhotosSectionLabel;

  /// No description provided for @addPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhotoLabel;

  /// No description provided for @tapPhotoToReplace.
  ///
  /// In en, this message translates to:
  /// **'Tap a photo to replace it, or use Remove.'**
  String get tapPhotoToReplace;

  /// No description provided for @optionalAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Optional — add up to {max} photos (camera or gallery)'**
  String optionalAddPhotos(int max);

  /// No description provided for @farmerNameInput.
  ///
  /// In en, this message translates to:
  /// **'Farmer name'**
  String get farmerNameInput;

  /// No description provided for @mobileNumberInput.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumberInput;

  /// No description provided for @aadharNumberInput.
  ///
  /// In en, this message translates to:
  /// **'Aadhar Number'**
  String get aadharNumberInput;

  /// No description provided for @aadharHint.
  ///
  /// In en, this message translates to:
  /// **'12-digit Aadhar'**
  String get aadharHint;

  /// No description provided for @genderInput.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderInput;

  /// No description provided for @ageInput.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageInput;

  /// No description provided for @enterFarmName.
  ///
  /// In en, this message translates to:
  /// **'Enter farm name'**
  String get enterFarmName;

  /// No description provided for @pinFarmBoundaryMinimum3.
  ///
  /// In en, this message translates to:
  /// **'Pin the farm boundary on the map (minimum 3 pins)'**
  String get pinFarmBoundaryMinimum3;

  /// No description provided for @enterCropName.
  ///
  /// In en, this message translates to:
  /// **'Enter crop name'**
  String get enterCropName;

  /// No description provided for @enterNumberOfPlants.
  ///
  /// In en, this message translates to:
  /// **'Enter number of plants'**
  String get enterNumberOfPlants;

  /// No description provided for @enterFarmerName.
  ///
  /// In en, this message translates to:
  /// **'Enter farmer name'**
  String get enterFarmerName;

  /// No description provided for @enterFarmerMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter farmer mobile number'**
  String get enterFarmerMobile;

  /// No description provided for @enterValid12DigitAadhar.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 12-digit Aadhar number'**
  String get enterValid12DigitAadhar;

  /// No description provided for @pleaseSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select gender'**
  String get pleaseSelectGender;

  /// No description provided for @enterValidFarmerAge.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid farmer age'**
  String get enterValidFarmerAge;

  /// No description provided for @enterHarvestTypeOnFarmDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter harvest type on the farm details step'**
  String get enterHarvestTypeOnFarmDetails;

  /// No description provided for @farmBoundaryRequiredGoBack.
  ///
  /// In en, this message translates to:
  /// **'Farm boundary is required. Go back and mark the boundary.'**
  String get farmBoundaryRequiredGoBack;

  /// No description provided for @farmCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Farm created successfully'**
  String get farmCreatedSuccessfully;

  /// No description provided for @maximumPhotosAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} photos allowed'**
  String maximumPhotosAllowed(int max);

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @youMustBeSignedInToOnboard.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to onboard a farm.'**
  String get youMustBeSignedInToOnboard;

  /// No description provided for @selectFarmBoundary.
  ///
  /// In en, this message translates to:
  /// **'Select Farm Boundary'**
  String get selectFarmBoundary;

  /// No description provided for @recenterOnMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Recenter on my location'**
  String get recenterOnMyLocation;

  /// No description provided for @showIndia.
  ///
  /// In en, this message translates to:
  /// **'Show India'**
  String get showIndia;

  /// No description provided for @searchVillageDistrict.
  ///
  /// In en, this message translates to:
  /// **'Search village, district in India...'**
  String get searchVillageDistrict;

  /// No description provided for @farmBoundaryStatus.
  ///
  /// In en, this message translates to:
  /// **'Farm boundary — status'**
  String get farmBoundaryStatus;

  /// No description provided for @readyToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Ready to confirm · {pins} pins, {acres} acres'**
  String readyToConfirm(int pins, String acres);

  /// No description provided for @tapMapToDropBoundary.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to drop boundary corners'**
  String get tapMapToDropBoundary;

  /// No description provided for @boundaryPinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Boundary pins'**
  String get boundaryPinsLabel;

  /// No description provided for @pinsPlaced.
  ///
  /// In en, this message translates to:
  /// **'{pins} pins · {acres} acres'**
  String pinsPlaced(int pins, String acres);

  /// No description provided for @minPinsRequired.
  ///
  /// In en, this message translates to:
  /// **'{pins} of 3 minimum pins placed'**
  String minPinsRequired(int pins);

  /// No description provided for @tapMapAtEachCorner.
  ///
  /// In en, this message translates to:
  /// **'Tap the map at each corner of the farm.'**
  String get tapMapAtEachCorner;

  /// No description provided for @gpsLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'GPS location'**
  String get gpsLocationLabel;

  /// No description provided for @gettingFix.
  ///
  /// In en, this message translates to:
  /// **'Getting a fix…'**
  String get gettingFix;

  /// No description provided for @noGpsFixYet.
  ///
  /// In en, this message translates to:
  /// **'No GPS fix yet.'**
  String get noGpsFixYet;

  /// No description provided for @fixOutsideIndia.
  ///
  /// In en, this message translates to:
  /// **'Fix is outside India ({lat}, {lng}).'**
  String fixOutsideIndia(String lat, String lng);

  /// No description provided for @gpsOptionalCanPinManually.
  ///
  /// In en, this message translates to:
  /// **'GPS is optional here — you can still pin the boundary manually. Tap Recenter to retry.'**
  String get gpsOptionalCanPinManually;

  /// No description provided for @addressLookup.
  ///
  /// In en, this message translates to:
  /// **'Address lookup'**
  String get addressLookup;

  /// No description provided for @noAddressFound.
  ///
  /// In en, this message translates to:
  /// **'No address found for this location.'**
  String get noAddressFound;

  /// No description provided for @notLookedUpYet.
  ///
  /// In en, this message translates to:
  /// **'Not looked up yet.'**
  String get notLookedUpYet;

  /// No description provided for @addressOptionalNeverBlocks.
  ///
  /// In en, this message translates to:
  /// **'Optional — you can type the address on the previous screen. This never blocks Confirm.'**
  String get addressOptionalNeverBlocks;

  /// No description provided for @locationSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Location search'**
  String get locationSearchLabel;

  /// No description provided for @searchOptionalPinDirectly.
  ///
  /// In en, this message translates to:
  /// **'Search is optional — pin the boundary directly on the map.'**
  String get searchOptionalPinDirectly;

  /// No description provided for @bluePinYourGps.
  ///
  /// In en, this message translates to:
  /// **'Blue pin = your GPS. Tap the map to drop boundary corners around the farm.'**
  String get bluePinYourGps;

  /// No description provided for @tapMapToDropPinsIndia.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to drop pins around your farm boundary (India only)'**
  String get tapMapToDropPinsIndia;

  /// No description provided for @pinsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pins'**
  String pinsCount(int count);

  /// No description provided for @acresDisplay.
  ///
  /// In en, this message translates to:
  /// **'{acres} acres'**
  String acresDisplay(String acres);

  /// No description provided for @min3Pins.
  ///
  /// In en, this message translates to:
  /// **'Min 3 pins'**
  String get min3Pins;

  /// No description provided for @undoLabel.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @confirmBoundaryButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm boundary'**
  String get confirmBoundaryButton;

  /// No description provided for @addMorePins.
  ///
  /// In en, this message translates to:
  /// **'Add {count} more pin{plural}'**
  String addMorePins(int count, String plural);

  /// No description provided for @turnOnLocationToOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to open the map at your current position.'**
  String get turnOnLocationToOpenMap;

  /// No description provided for @farmBoundaryMustBeInIndia.
  ///
  /// In en, this message translates to:
  /// **'Farm boundary must be inside India.'**
  String get farmBoundaryMustBeInIndia;

  /// No description provided for @couldNotGetGpsEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get GPS. Enable location and try again.'**
  String get couldNotGetGpsEnableLocation;

  /// No description provided for @gpsOutsideIndiaSearchVillage.
  ///
  /// In en, this message translates to:
  /// **'Your GPS is outside India. Open the boundary map and search the farm village.'**
  String get gpsOutsideIndiaSearchVillage;

  /// No description provided for @yourGpsOutsideIndiaSearch.
  ///
  /// In en, this message translates to:
  /// **'Your GPS is outside India. Search for the farm village, then mark pins.'**
  String get yourGpsOutsideIndiaSearch;

  /// No description provided for @recordInteractionButton.
  ///
  /// In en, this message translates to:
  /// **'Record interaction'**
  String get recordInteractionButton;

  /// No description provided for @editInteractionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit interaction'**
  String get editInteractionTitle;

  /// No description provided for @captureProspectFarmerDetails.
  ///
  /// In en, this message translates to:
  /// **'Capture prospect farmer details from your conversation'**
  String get captureProspectFarmerDetails;

  /// No description provided for @phoneNumberInput.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberInput;

  /// No description provided for @landLocationInput.
  ///
  /// In en, this message translates to:
  /// **'Land location'**
  String get landLocationInput;

  /// No description provided for @landLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Village / mandal / area'**
  String get landLocationHint;

  /// No description provided for @acresInput.
  ///
  /// In en, this message translates to:
  /// **'Acres'**
  String get acresInput;

  /// No description provided for @currentCropInput.
  ///
  /// In en, this message translates to:
  /// **'Current crop'**
  String get currentCropInput;

  /// No description provided for @specifyCrop.
  ///
  /// In en, this message translates to:
  /// **'Specify crop'**
  String get specifyCrop;

  /// No description provided for @planningToTake.
  ///
  /// In en, this message translates to:
  /// **'Planning to take'**
  String get planningToTake;

  /// No description provided for @monthSingular.
  ///
  /// In en, this message translates to:
  /// **'{count} month'**
  String monthSingular(int count);

  /// No description provided for @monthPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String monthPlural(int count);

  /// No description provided for @moLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} mo'**
  String moLabel(int count);

  /// No description provided for @onboardingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Onboarding status'**
  String get onboardingStatusLabel;

  /// No description provided for @farmerReadyForOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Farmer is ready for onboarding soon'**
  String get farmerReadyForOnboarding;

  /// No description provided for @needsMoreTime.
  ///
  /// In en, this message translates to:
  /// **'Needs more time before deciding'**
  String get needsMoreTime;

  /// No description provided for @stillEvaluating.
  ///
  /// In en, this message translates to:
  /// **'Still evaluating or undecided'**
  String get stillEvaluating;

  /// No description provided for @notesOptionalInput.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptionalInput;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @saveInteractionButton.
  ///
  /// In en, this message translates to:
  /// **'Save interaction'**
  String get saveInteractionButton;

  /// No description provided for @pleaseSelectCropAndMonths.
  ///
  /// In en, this message translates to:
  /// **'Please select crop and planned months'**
  String get pleaseSelectCropAndMonths;

  /// No description provided for @enterTheCropName.
  ///
  /// In en, this message translates to:
  /// **'Enter the crop name'**
  String get enterTheCropName;

  /// No description provided for @interactionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Interaction updated'**
  String get interactionUpdated;

  /// No description provided for @interactionSaved.
  ///
  /// In en, this message translates to:
  /// **'Interaction saved'**
  String get interactionSaved;

  /// No description provided for @enterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterValidPhoneNumber;

  /// No description provided for @enterAcres.
  ///
  /// In en, this message translates to:
  /// **'Enter acres'**
  String get enterAcres;

  /// No description provided for @selectACrop.
  ///
  /// In en, this message translates to:
  /// **'Select a crop'**
  String get selectACrop;

  /// No description provided for @interactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get interactionsTitle;

  /// No description provided for @prospectConversationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} prospect conversation{plural}'**
  String prospectConversationsCount(int count, String plural);

  /// No description provided for @searchNamePhoneLocation.
  ///
  /// In en, this message translates to:
  /// **'Search name, phone, location'**
  String get searchNamePhoneLocation;

  /// No description provided for @noInteractionsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No interactions yet'**
  String get noInteractionsYetTitle;

  /// No description provided for @logConversationsWithFarmers.
  ///
  /// In en, this message translates to:
  /// **'Log conversations with farmers you are trying to bring into the plan'**
  String get logConversationsWithFarmers;

  /// No description provided for @recordButton.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordButton;

  /// No description provided for @planningMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Planning {months} month{plural} · {date}'**
  String planningMonthsLabel(int months, String plural, String date);

  /// No description provided for @visitReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit Report'**
  String get visitReportTitle;

  /// No description provided for @pdfLabel.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdfLabel;

  /// No description provided for @savingPdf.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingPdf;

  /// No description provided for @downloadPDFButton.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPDFButton;

  /// No description provided for @preparingPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF…'**
  String get preparingPdf;

  /// No description provided for @downloadReportPdf.
  ///
  /// In en, this message translates to:
  /// **'Download report PDF'**
  String get downloadReportPdf;

  /// No description provided for @reportPdfReadyToShare.
  ///
  /// In en, this message translates to:
  /// **'Report PDF ready to share/save'**
  String get reportPdfReadyToShare;

  /// No description provided for @fieldReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Field Report'**
  String get fieldReportTitle;

  /// No description provided for @noStructuredReportAnswers.
  ///
  /// In en, this message translates to:
  /// **'No structured report answers were saved for this visit.'**
  String get noStructuredReportAnswers;

  /// No description provided for @additionalNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional notes'**
  String get additionalNotesLabel;

  /// No description provided for @voiceNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Note'**
  String get voiceNoteTitle;

  /// No description provided for @voiceNoteRecordedButNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Voice note was recorded but the audio file is not available.'**
  String get voiceNoteRecordedButNotAvailable;

  /// No description provided for @photosCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos ({count})'**
  String photosCountLabel(int count);

  /// No description provided for @executiveFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Executive'**
  String get executiveFieldLabel;

  /// No description provided for @checkInLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkInLabel;

  /// No description provided for @checkOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkOutLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @fetchingPhotosAssemblingPdf.
  ///
  /// In en, this message translates to:
  /// **'Fetching photos and assembling your PDF — this can take a few minutes…'**
  String get fetchingPhotosAssemblingPdf;

  /// No description provided for @yourCoverage.
  ///
  /// In en, this message translates to:
  /// **'YOUR COVERAGE'**
  String get yourCoverage;

  /// No description provided for @networkOverview.
  ///
  /// In en, this message translates to:
  /// **'Network Overview'**
  String get networkOverview;

  /// No description provided for @acrossAllFieldOperations.
  ///
  /// In en, this message translates to:
  /// **'Across all field operations'**
  String get acrossAllFieldOperations;

  /// No description provided for @totalFieldVisitsLogged.
  ///
  /// In en, this message translates to:
  /// **'Total field visits logged'**
  String get totalFieldVisitsLogged;

  /// No description provided for @fieldActivity.
  ///
  /// In en, this message translates to:
  /// **'Field activity'**
  String get fieldActivity;

  /// No description provided for @harvestSoon.
  ///
  /// In en, this message translates to:
  /// **'Harvest soon'**
  String get harvestSoon;

  /// No description provided for @farmNetworkIndia.
  ///
  /// In en, this message translates to:
  /// **'Farm Network — India'**
  String get farmNetworkIndia;

  /// No description provided for @pinchToZoomHint.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom · drag to pan · tap a pin for farm details'**
  String get pinchToZoomHint;

  /// No description provided for @viewFarmDetails.
  ///
  /// In en, this message translates to:
  /// **'View Farm Details'**
  String get viewFarmDetails;

  /// No description provided for @indiaFarmMap.
  ///
  /// In en, this message translates to:
  /// **'India farm map'**
  String get indiaFarmMap;

  /// No description provided for @fullScreenMap.
  ///
  /// In en, this message translates to:
  /// **'Full screen map'**
  String get fullScreenMap;

  /// No description provided for @resetView.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get resetView;

  /// No description provided for @statesLabel.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get statesLabel;

  /// No description provided for @contactAndIdentity.
  ///
  /// In en, this message translates to:
  /// **'Contact & Identity'**
  String get contactAndIdentity;

  /// No description provided for @verifiedAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Verified Administrator'**
  String get verifiedAdministrator;

  /// No description provided for @fullAccessFarmsTeam.
  ///
  /// In en, this message translates to:
  /// **'Full access to farms, team & harvest data'**
  String get fullAccessFarmsTeam;

  /// No description provided for @visitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} visits'**
  String visitsCount(int count);

  /// No description provided for @farmsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} farms'**
  String farmsCount(int count);

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String recordsCount(int count);

  /// No description provided for @minOnSite.
  ///
  /// In en, this message translates to:
  /// **'{count} min on site'**
  String minOnSite(int count);

  /// No description provided for @onboardFarmTitleCase.
  ///
  /// In en, this message translates to:
  /// **'Onboard Farm'**
  String get onboardFarmTitleCase;

  /// No description provided for @photosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosLabel;

  /// No description provided for @copyReport.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get copyReport;

  /// No description provided for @reportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get reportCopied;

  /// No description provided for @couldNotOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not open phone dialer'**
  String get couldNotOpenDialer;

  /// No description provided for @couldNotOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get couldNotOpenWhatsApp;

  /// No description provided for @tapToRecordMax.
  ///
  /// In en, this message translates to:
  /// **'Tap to record (max {max})'**
  String tapToRecordMax(String max);

  /// No description provided for @acresLower.
  ///
  /// In en, this message translates to:
  /// **'acres'**
  String get acresLower;
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
      <String>['en', 'kn', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kn':
      return AppLocalizationsKn();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
