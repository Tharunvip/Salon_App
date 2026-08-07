import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('hi'),
    Locale('te'),
    Locale('ta'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('bn'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'VIP Barber'**
  String get appTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

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

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobile;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccount;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccess;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registerSuccess;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @nearbySalons.
  ///
  /// In en, this message translates to:
  /// **'Nearby Salons'**
  String get nearbySalons;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @shopClosed.
  ///
  /// In en, this message translates to:
  /// **'Shop Closed'**
  String get shopClosed;

  /// No description provided for @bookingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bookings Unavailable'**
  String get bookingsUnavailable;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @noSalonsNearby.
  ///
  /// In en, this message translates to:
  /// **'No salons nearby'**
  String get noSalonsNearby;

  /// No description provided for @noSalonsFound.
  ///
  /// In en, this message translates to:
  /// **'No salons found'**
  String get noSalonsFound;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Get Direction'**
  String get direction;

  /// No description provided for @chooseService.
  ///
  /// In en, this message translates to:
  /// **'Choose your service'**
  String get chooseService;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @noSlotsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No slots available'**
  String get noSlotsAvailable;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @todaysBookings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Bookings'**
  String get todaysBookings;

  /// No description provided for @todaysEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get todaysEarnings;

  /// No description provided for @activeCustomers.
  ///
  /// In en, this message translates to:
  /// **'Active Customers'**
  String get activeCustomers;

  /// No description provided for @pendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @queueManagement.
  ///
  /// In en, this message translates to:
  /// **'Queue Management'**
  String get queueManagement;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// No description provided for @closedNow.
  ///
  /// In en, this message translates to:
  /// **'Closed Now'**
  String get closedNow;

  /// No description provided for @bookingsOn.
  ///
  /// In en, this message translates to:
  /// **'Bookings On'**
  String get bookingsOn;

  /// No description provided for @bookingsOff.
  ///
  /// In en, this message translates to:
  /// **'Bookings Off'**
  String get bookingsOff;

  /// No description provided for @shopSettings.
  ///
  /// In en, this message translates to:
  /// **'Shop Settings'**
  String get shopSettings;

  /// No description provided for @workingDays.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get workingDays;

  /// No description provided for @openingTime.
  ///
  /// In en, this message translates to:
  /// **'Opening Time'**
  String get openingTime;

  /// No description provided for @closingTime.
  ///
  /// In en, this message translates to:
  /// **'Closing Time'**
  String get closingTime;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @totalBookings.
  ///
  /// In en, this message translates to:
  /// **'Total Bookings'**
  String get totalBookings;

  /// No description provided for @completedBookings.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedBookings;

  /// No description provided for @cancelledBookings.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledBookings;

  /// No description provided for @queueTab.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTab;

  /// No description provided for @openQueueManager.
  ///
  /// In en, this message translates to:
  /// **'Open Queue Manager'**
  String get openQueueManager;

  /// No description provided for @token.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get token;

  /// No description provided for @tokenNumber.
  ///
  /// In en, this message translates to:
  /// **'Token #{token}'**
  String tokenNumber(Object token);

  /// No description provided for @tokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Token No: {token}'**
  String tokenLabel(Object token);

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

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

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @startService.
  ///
  /// In en, this message translates to:
  /// **'Start Service'**
  String get startService;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @completeService.
  ///
  /// In en, this message translates to:
  /// **'Complete Service'**
  String get completeService;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @reachedShop.
  ///
  /// In en, this message translates to:
  /// **'Reached Shop'**
  String get reachedShop;

  /// No description provided for @payRemaining.
  ///
  /// In en, this message translates to:
  /// **'Pay Remaining'**
  String get payRemaining;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking Cancelled'**
  String get bookingCancelled;

  /// No description provided for @noBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookings;

  /// No description provided for @queuePosition.
  ///
  /// In en, this message translates to:
  /// **'Queue Position'**
  String get queuePosition;

  /// No description provided for @estimatedWait.
  ///
  /// In en, this message translates to:
  /// **'Estimated Wait'**
  String get estimatedWait;

  /// No description provided for @customersAhead.
  ///
  /// In en, this message translates to:
  /// **'{count} customers ahead'**
  String customersAhead(Object count);

  /// No description provided for @activeChairs.
  ///
  /// In en, this message translates to:
  /// **'Active Chairs'**
  String get activeChairs;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @chair.
  ///
  /// In en, this message translates to:
  /// **'Chair'**
  String get chair;

  /// No description provided for @chairs.
  ///
  /// In en, this message translates to:
  /// **'Chairs'**
  String get chairs;

  /// No description provided for @chairNumber.
  ///
  /// In en, this message translates to:
  /// **'Chair #{number}'**
  String chairNumber(Object number);

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @waitingToStart.
  ///
  /// In en, this message translates to:
  /// **'Waiting to Start'**
  String get waitingToStart;

  /// No description provided for @inService.
  ///
  /// In en, this message translates to:
  /// **'In Service'**
  String get inService;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @waitingQueue.
  ///
  /// In en, this message translates to:
  /// **'Waiting Queue'**
  String get waitingQueue;

  /// No description provided for @statsOverview.
  ///
  /// In en, this message translates to:
  /// **'Stats Overview'**
  String get statsOverview;

  /// No description provided for @serviceStarted.
  ///
  /// In en, this message translates to:
  /// **'Service Started'**
  String get serviceStarted;

  /// No description provided for @serviceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Service Completed'**
  String get serviceCompleted;

  /// No description provided for @pauseService.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseService;

  /// No description provided for @resumeService.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeService;

  /// No description provided for @releaseChair.
  ///
  /// In en, this message translates to:
  /// **'Release Chair'**
  String get releaseChair;

  /// No description provided for @assignNext.
  ///
  /// In en, this message translates to:
  /// **'Assign Next'**
  String get assignNext;

  /// No description provided for @updateRemainingTime.
  ///
  /// In en, this message translates to:
  /// **'Update Time'**
  String get updateRemainingTime;

  /// No description provided for @noWaitingCustomers.
  ///
  /// In en, this message translates to:
  /// **'No waiting customers'**
  String get noWaitingCustomers;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining Time'**
  String get remainingTime;

  /// No description provided for @totalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total Duration'**
  String get totalDuration;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent to customer'**
  String get notificationSent;

  /// No description provided for @assignNextCustomer.
  ///
  /// In en, this message translates to:
  /// **'Assign Next Customer'**
  String get assignNextCustomer;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @upi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upi;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @payAndBook.
  ///
  /// In en, this message translates to:
  /// **'Pay & Book'**
  String get payAndBook;

  /// No description provided for @advanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Booking Advance'**
  String get advanceAmount;

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining Amount'**
  String get remainingAmount;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @goldMember.
  ///
  /// In en, this message translates to:
  /// **'Gold Member'**
  String get goldMember;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @languageSelection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSelection;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @recentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'Recently Used'**
  String get recentlyUsed;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Do you want to cancel this booking?'**
  String get confirmCancel;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this?'**
  String get confirmDelete;

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

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get networkError;

  /// No description provided for @dataSaved.
  ///
  /// In en, this message translates to:
  /// **'Data saved successfully'**
  String get dataSaved;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @invalidMobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get invalidMobile;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters and include uppercase, lowercase, a number, and a special character'**
  String get passwordTooShort;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @notifBookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get notifBookingConfirmedTitle;

  /// No description provided for @notifBookingConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking at {shopName} has been confirmed'**
  String notifBookingConfirmedBody(Object shopName);

  /// No description provided for @notifTokenGenerated.
  ///
  /// In en, this message translates to:
  /// **'Token #{token} generated'**
  String notifTokenGenerated(Object token);

  /// No description provided for @notifQueueUpdated.
  ///
  /// In en, this message translates to:
  /// **'Queue updated'**
  String get notifQueueUpdated;

  /// No description provided for @notifYourTurnIsNear.
  ///
  /// In en, this message translates to:
  /// **'Your turn is near! Please be ready.'**
  String get notifYourTurnIsNear;

  /// No description provided for @notifServiceStarted.
  ///
  /// In en, this message translates to:
  /// **'Your service has started'**
  String get notifServiceStarted;

  /// No description provided for @notifServiceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Your service has been completed. Thank you!'**
  String get notifServiceCompleted;

  /// No description provided for @notifPaymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get notifPaymentSuccessful;

  /// No description provided for @notifNewBooking.
  ///
  /// In en, this message translates to:
  /// **'New booking received'**
  String get notifNewBooking;

  /// No description provided for @notifShopClosed.
  ///
  /// In en, this message translates to:
  /// **'Shop is currently closed'**
  String get notifShopClosed;

  /// No description provided for @notifBookingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bookings are currently unavailable'**
  String get notifBookingsUnavailable;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBack(Object name);

  /// No description provided for @welcomeToApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to VIP Barber!'**
  String get welcomeToApp;

  /// No description provided for @firstLaunchSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Please select your preferred language.'**
  String get firstLaunchSelectLanguage;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get selectLanguageTitle;

  /// No description provided for @continueApp.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueApp;

  /// No description provided for @searchSalons.
  ///
  /// In en, this message translates to:
  /// **'Search for salons...'**
  String get searchSalons;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get filterBy;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @ratings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratings;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaySchedule;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get minutes;

  /// No description provided for @bookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Booking History'**
  String get bookingHistory;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @chooseLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language for the app'**
  String get chooseLanguageBody;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get sessionExpired;

  /// No description provided for @internetError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get internetError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get online;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'₹'**
  String get currency;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @bookingSummary.
  ///
  /// In en, this message translates to:
  /// **'Booking Summary'**
  String get bookingSummary;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @generateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Generate Invoice'**
  String get generateInvoice;

  /// No description provided for @downloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice'**
  String get downloadInvoice;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentPending;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount Due: {amount}'**
  String amountDue(Object amount);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found for \'{query}\''**
  String searchNoResults(Object query);

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'hi',
    'kn',
    'ml',
    'mr',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
