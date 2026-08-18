import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _today() => _dateKey(DateTime.now());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Daily Check dan Tire Inspection memakai marker unit yang sama',
      () async {
    expect(
      await shouldLoadUnitListFromApiToday(idSite: '7'),
      isTrue,
    );

    await saveUnitListApiLoadedToday(idSite: '7');

    expect(
      await shouldLoadUnitListFromApiToday(idSite: '7'),
      isFalse,
    );
    expect(
      await shouldLoadUnitListFromApiToday(idSite: '5'),
      isTrue,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('unit_list_last_api_load_daily_check_7'),
      _today(),
    );
    expect(
      prefs.getString('unit_list_last_api_load_tire_inspection_7'),
      _today(),
    );
  });

  test('marker Daily Check lama dimigrasikan ke marker bersama', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'unit_list_last_api_load_daily_check_7': _today(),
    });

    expect(
      await shouldLoadUnitListFromApiToday(idSite: '7'),
      isFalse,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('unit_list_last_api_load_shared_7'),
      _today(),
    );
  });

  test('marker Tire Inspection lama dimigrasikan ke marker bersama', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'unit_list_last_api_load_tire_inspection_7': _today(),
    });

    expect(
      await shouldLoadUnitListFromApiToday(idSite: '7'),
      isFalse,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('unit_list_last_api_load_shared_7'),
      _today(),
    );
  });

  test('marker lama dari hari sebelumnya tidak dianggap fresh', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues(<String, Object>{
      'unit_list_last_api_load_daily_check_7': _dateKey(yesterday),
      'unit_list_last_api_load_tire_inspection_7': _dateKey(yesterday),
    });

    expect(
      await shouldLoadUnitListFromApiToday(idSite: '7'),
      isTrue,
    );
  });
}
