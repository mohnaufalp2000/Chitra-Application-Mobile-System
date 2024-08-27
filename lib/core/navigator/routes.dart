import 'package:camos/pages/attendance/absence_page.dart';
import 'package:camos/pages/attendance/all_presence_page.dart';
import 'package:camos/pages/attendance/attendance_page.dart';
import 'package:camos/pages/attendance/presence_camera_page.dart';
import 'package:camos/pages/attendance/presence_camera_result_page.dart';
import 'package:camos/pages/attendance/presence_page.dart';
import 'package:camos/pages/authentication/email_verification_page.dart';
import 'package:camos/pages/authentication/image_profile_page.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:camos/pages/authentication/register_page.dart';
import 'package:camos/pages/cts/cts_page.dart';
import 'package:camos/pages/home/detail_tire_site_page.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:camos/pages/home/outstanding_filter_page.dart';
import 'package:camos/pages/home/trial/home_page_trial.dart';
import 'package:camos/pages/opening/splash_screen.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_history_page.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_list.dart';
import 'package:camos/pages/pressure_gauge_digital/detail_non_running_tire_inspection_page.dart';
import 'package:camos/pages/pressure_gauge_digital/non_running_inspection_page.dart';
import 'package:camos/pages/pressure_gauge_digital/tire_inspection_form_page.dart';
import 'package:camos/pages/pressure_gauge_digital/select_inspection_page.dart';
import 'package:camos/pages/pressure_gauge_digital/select_unit_page.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_check_form_page.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/daily_pressure_history_trial_page.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/daily_pressure_list_trial_page.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/daily_pressure_trial_page.dart';
import 'package:camos/pages/settings/edit_profile_page.dart';
import 'package:camos/pages/settings/feedback_page.dart';
import 'package:camos/pages/settings/settings_page.dart';
import 'package:camos/pages/site/site_page.dart';
import 'package:camos/pages/site_condition/history_site_condition_page.dart';
import 'package:camos/pages/site_condition/site_condition_page.dart';
import 'package:camos/pages/site_condition/site_condition_pdf.dart';
import 'package:camos/pages/site_condition/site_condition_report_page.dart';
import 'package:camos/pages/tire_condition/detail_tire_condition_page.dart';
import 'package:camos/pages/tire_condition/tire_condition_page.dart';
import 'package:camos/pages/tire_inventory/tire_inventory_page.dart';
import 'package:camos/pages/tire_repair_form/detail_tire_repair_inspection_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection_form_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection_page.dart';
import 'package:camos/pages/tkph_calculator/result_tkph_page.dart';
import 'package:camos/pages/tkph_calculator/tkph_calculator.dart';
import 'package:camos/pages/tpms/qr_tpms_page.dart';
import 'package:camos/pages/tpms/tpms_page.dart';
import 'package:image_picker/image_picker.dart';

var routes = {
  SplashScreen.routeName: (context) => SplashScreen(),
  LoginPage.routeName: (context) => LoginPage(),
  RegisterPage.routeName: (context) => RegisterPage(),
  HomePage.routeName: (context) => HomePage(),
  EmailVerificationPage.routeName: (context) => EmailVerificationPage(),
  ImageProfilePage.routeName: (context) => ImageProfilePage(),
  TKHPCalculator.routeName: (context) => TKHPCalculator(),
  ResultTkphPage.routeName: (context) => ResultTkphPage(),
  SiteConditionPage.routeName: (context) => SiteConditionPage(),
  // SiteConditionReportPage.routeName: (context) => SiteConditionReportPage(),
  SiteConditionPDF.routeName: (context) => SiteConditionPDF(),
  SettingsPage.routeName: (context) => SettingsPage(),
  EditProfilePage.routeName: (context) => EditProfilePage(),
  FeedbackPage.routeName: (context) => FeedbackPage(),
  SitePage.routeName: (context) => SitePage(),
  SelectUnitPage.routeName: (context) => SelectUnitPage(),
  AttendancePage.routeName: (context) => AttendancePage(),
  AllPresencePage.routeName: (context) => AllPresencePage(),
  CtsPage.routeName: (context) => CtsPage(),
  TireConditionPage.routeName: (context) => TireConditionPage(),
  TireInventoryPage.routeName: (context) => TireInventoryPage(),
  DetailTireConditionPage.routeName: (context) => DetailTireConditionPage(),
  OutstandingFilterPage.routeName: (context) => OutstandingFilterPage(),
  PresencePage.routeName: (context) => PresencePage(),
  DetailTireSitePage.routeName: (context) => DetailTireSitePage(),
  TpmsPage.routeName: (context) => TpmsPage(),
  SelectInspectionPage.routeName: (context) => SelectInspectionPage(),
  DailyCheckFormPage.routeName: (context) => DailyCheckFormPage(),
  DailyPressureListPage.routeName: (context) => DailyPressureListPage(),
  QrTpmsPage.routeName: (context) => QrTpmsPage(),
  DailyPressureHistoryPage.routeName: (context) => DailyPressureHistoryPage(),
  NonRunningInspectionPage.routeName: (context) => NonRunningInspectionPage(),
  DetailNonTireRunningTireInspection.routeName: (context) =>
      DetailNonTireRunningTireInspection(),
  HomePageTrial.routeName: (context) => HomePageTrial(),
  DailyPressureTrialPage.routeName: (context) => DailyPressureTrialPage(),
  PresenceCameraPage.routeName: (context) => PresenceCameraPage(),
  AbsencePage.routeName: (context) => AbsencePage(),
  PresenceCameraResultPage.routeName: (context) => PresenceCameraResultPage(),
  HistorySiteConditionPage.routeName: (context) => HistorySiteConditionPage(),
  TireInspectionFormPage.routeName: (context) => TireInspectionFormPage(),
  TireRepairInspectionFormPage.routeName: (context) =>
      TireRepairInspectionFormPage(),
  TireRepairInspectionPage.routeName: (context) => TireRepairInspectionPage(),
  DetailTireRepairInspection.routeName: (context) =>
      DetailTireRepairInspection(),
  DailyPressureListTrialPage.routeName: (context) =>
      DailyPressureListTrialPage(),
  DailyPressureHistoryTrialPage.routeName: (context) =>
      DailyPressureHistoryTrialPage(),
};
