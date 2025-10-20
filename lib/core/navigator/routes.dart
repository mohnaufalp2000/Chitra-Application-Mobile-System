import 'package:camos/pages/dashboard/dashboard_page.dart';

import '../../pages/attendance/absence_page.dart';
import '../../pages/attendance/all_presence_page.dart';
import '../../pages/attendance/attendance_page.dart';
import '../../pages/attendance/presence_camera_page.dart';
import '../../pages/attendance/presence_camera_result_page.dart';
import '../../pages/attendance/presence_page.dart';
import '../../pages/authentication/email_verification_page.dart';
import '../../pages/authentication/image_profile_page.dart';
import '../../pages/authentication/login_page.dart';
import '../../pages/authentication/register_page.dart';
import '../../pages/cts/cts_page.dart';
import '../../pages/home/detail_tire_site_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/home/outstanding_filter_page.dart';
import '../../pages/home/trial/home_page_trial.dart';
import '../../pages/opening/splash_screen.dart';
import '../../pages/pressure_gauge_digital/daily_pressure_history_page.dart';
import '../../pages/pressure_gauge_digital/daily_pressure_list.dart';
import '../../pages/pressure_gauge_digital/tire_inspection_form_page.dart';
import '../../pages/pressure_gauge_digital/select_inspection_page.dart';
import '../../pages/pressure_gauge_digital/select_unit_page.dart';
import '../../pages/pressure_gauge_digital/daily_check_form_page.dart';
import '../../pages/pressure_gauge_digital/trial/daily_pressure_history_trial_page.dart';
import '../../pages/pressure_gauge_digital/trial/daily_pressure_list_trial_page.dart';
import '../../pages/pressure_gauge_digital/trial/daily_pressure_trial_page.dart';
import '../../pages/pressure_gauge_digital/trial/dashboard_daily_page.dart';
import '../../pages/pressure_gauge_digital/trial/scan_device_page.dart';
import '../../pages/settings/edit_profile_page.dart';
import '../../pages/settings/feedback_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/site/site_page.dart';
import '../../pages/site_condition/history_site_condition_page.dart';
import '../../pages/site_condition/site_condition_page.dart';
import '../../pages/site_condition/site_condition_pdf.dart';
import '../../pages/site_condition/site_condition_report_page.dart';
import '../../pages/tire_condition/detail_tire_condition_page.dart';
import '../../pages/tire_condition/tire_condition_page.dart';
import '../../pages/tire_inventory/tire_inventory_page.dart';
import '../../pages/tire_repair_form/jobcard_repair/history_jobcard_repair_page.dart';
import '../../pages/tire_repair_form/jobcard_repair/jobcard_finish_page.dart';
import '../../pages/tire_repair_form/jobcard_repair/jobcard_form_page.dart';
import '../../pages/tire_repair_form/jobcard_repair/jobcard_qc_page.dart';
import '../../pages/tire_repair_form/jobcard_repair/jobcard_selected_job_page.dart';
import '../../pages/tire_repair_form/jobcard_repair/list_jobcard_repair_page.dart';
import '../../pages/tire_repair_form/select_tire_repair_page.dart';
import '../../pages/tire_repair_form/tire_repair_inspection/detail_tire_repair_inspection_page.dart';
import '../../pages/tire_repair_form/tire_repair_inspection/tire_repair_inspection_form_page.dart';
import '../../pages/tire_repair_form/tire_repair_inspection/tire_repair_inspection_page.dart';
import '../../pages/tire_repair_form/tire_repair_inspection/tire_repair_pdf_page.dart';
import '../../pages/tire_repair_form/tire_repair_inspection_old/tire_repair_inspection_old_page.dart';
import '../../pages/tkph_calculator/result_tkph_page.dart';
import '../../pages/tkph_calculator/tkph_calculator.dart';
import '../../pages/tpms/qr_tpms_page.dart';
import '../../pages/tpms/tpms_page.dart';
import 'package:image_picker/image_picker.dart';

var routes = {
  SplashScreen.routeName: (context) => const SplashScreen(),
  LoginPage.routeName: (context) => const LoginPage(),
  RegisterPage.routeName: (context) => const RegisterPage(),
  HomePage.routeName: (context) => const HomePage(),
  EmailVerificationPage.routeName: (context) => const EmailVerificationPage(),
  ImageProfilePage.routeName: (context) => const ImageProfilePage(),
  TKHPCalculator.routeName: (context) => const TKHPCalculator(),
  ResultTkphPage.routeName: (context) => const ResultTkphPage(),
  SiteConditionPage.routeName: (context) => const SiteConditionPage(),
  // SiteConditionReportPage.routeName: (context) => SiteConditionReportPage(),
  SiteConditionPDF.routeName: (context) => const SiteConditionPDF(),
  SettingsPage.routeName: (context) => const SettingsPage(),
  EditProfilePage.routeName: (context) => const EditProfilePage(),
  FeedbackPage.routeName: (context) => const FeedbackPage(),
  SitePage.routeName: (context) => const SitePage(),
  SelectUnitPage.routeName: (context) => SelectUnitPage(),
  AttendancePage.routeName: (context) => const AttendancePage(),
  AllPresencePage.routeName: (context) => const AllPresencePage(),
  CtsPage.routeName: (context) => const CtsPage(),
  TireConditionPage.routeName: (context) => const TireConditionPage(),
  TireInventoryPage.routeName: (context) => const TireInventoryPage(),
  DetailTireConditionPage.routeName: (context) =>
      const DetailTireConditionPage(),
  OutstandingFilterPage.routeName: (context) => const OutstandingFilterPage(),
  PresencePage.routeName: (context) => const PresencePage(),
  DetailTireSitePage.routeName: (context) => const DetailTireSitePage(),
  TpmsPage.routeName: (context) => const TpmsPage(),
  SelectInspectionPage.routeName: (context) => const SelectInspectionPage(),
  DailyCheckFormPage.routeName: (context) => const DailyCheckFormPage(),
  DailyPressureListPage.routeName: (context) => const DailyPressureListPage(),
  QrTpmsPage.routeName: (context) => const QrTpmsPage(),
  DailyPressureHistoryPage.routeName: (context) =>
      const DailyPressureHistoryPage(),
  HomePageTrial.routeName: (context) => const HomePageTrial(),
  DailyPressureTrialPage.routeName: (context) => const DailyPressureTrialPage(),
  PresenceCameraPage.routeName: (context) => const PresenceCameraPage(),
  AbsencePage.routeName: (context) => const AbsencePage(),
  PresenceCameraResultPage.routeName: (context) =>
      const PresenceCameraResultPage(),
  HistorySiteConditionPage.routeName: (context) =>
      const HistorySiteConditionPage(),
  TireInspectionFormPage.routeName: (context) => const TireInspectionFormPage(),
  TireRepairInspectionFormPage.routeName: (context) =>
      const TireRepairInspectionFormPage(),
  TireRepairInspectionPage.routeName: (context) =>
      const TireRepairInspectionPage(),
  DetailTireRepairInspection.routeName: (context) =>
      DetailTireRepairInspection(),
  DailyPressureListTrialPage.routeName: (context) =>
      const DailyPressureListTrialPage(),
  DailyPressureHistoryTrialPage.routeName: (context) =>
      const DailyPressureHistoryTrialPage(),
  ScanDevicePage.routeName: (context) => const ScanDevicePage(),
  DashboardDailyPage.routeName: (context) => const DashboardDailyPage(),
  TireRepairPDFPage.routeName: (context) => const TireRepairPDFPage(),
  SelectTireRepairPage.routeName: (context) => const SelectTireRepairPage(),
  ListJobcardRepair.routeName: (context) => const ListJobcardRepair(),
  JobcardFormPage.routeName: (context) => const JobcardFormPage(),
  JobcardQCPage.routeName: (context) => const JobcardQCPage(),
  JobcardFinishPage.routeName: (context) => const JobcardFinishPage(),
  HistoryJobcardRepairPage.routeName: (context) =>
      const HistoryJobcardRepairPage(),

  TireRepairInspectionOldPage.routeName: (context) =>
      const TireRepairInspectionOldPage(),
  JobcardSelectedJobPage.routeName: (context) => const JobcardSelectedJobPage(),
  DashboardPage.routeName: (context) => DashboardPage(),
};
