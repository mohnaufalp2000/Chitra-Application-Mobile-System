import 'package:camos/core/services/daily_check_shift_date_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = DailyCheckShiftDateService.instance;

  setUpAll(() async {
    await GetStorage.init();
  });

  setUp(() {
    service.clearCustomDate();
  });

  group('DailyCheckShiftDateService Eligibility', () {
    test('hanya eligible untuk company 1 dan site 1', () {
      expect(service.isEligible('1', '1'), isTrue);
      expect(service.isEligible(' 1 ', ' 1 '), isTrue);
      expect(service.isEligible('1', '2'), isFalse);
      expect(service.isEligible('2', '1'), isFalse);
      expect(service.isEligible('', '1'), isFalse);
      expect(service.isEligible('1', ''), isFalse);
      expect(service.isEligible('7', '7'), isFalse);
    });
  });

  group('DailyCheckShiftDateService Auto-Shift Operational Date', () {
    test('Shift 1 siang (06:00 - 17:59) -> tanggal operasional hari ini', () {
      final time1 = DateTime(2026, 8, 30, 6, 0);
      final time2 = DateTime(2026, 8, 30, 10, 30);
      final time3 = DateTime(2026, 8, 30, 17, 59);

      expect(service.getOperationalDate(time1), DateTime(2026, 8, 30, 6, 0));
      expect(service.getOperationalDate(time2), DateTime(2026, 8, 30, 10, 30));
      expect(service.getOperationalDate(time3), DateTime(2026, 8, 30, 17, 59));
      expect(service.getCurrentShift(time1), 'Shift 1');
      expect(service.getCurrentShift(time2), 'Shift 1');
      expect(service.getCurrentShift(time3), 'Shift 1');
    });

    test('Shift 2 awal (18:00 - 23:59) -> tanggal operasional hari ini', () {
      final time1 = DateTime(2026, 8, 30, 18, 0);
      final time2 = DateTime(2026, 8, 30, 23, 59);

      expect(service.getOperationalDate(time1), DateTime(2026, 8, 30, 18, 0));
      expect(service.getOperationalDate(time2), DateTime(2026, 8, 30, 23, 59));
      expect(service.getCurrentShift(time1), 'Shift 2');
      expect(service.getCurrentShift(time2), 'Shift 2');
    });

    test(
        'Shift 2 dini hari (00:00 - 05:59) -> tanggal operasional otomatis H-1',
        () {
      // Kasus screenshot user: 31 Agustus jam 00:22 -> harus masuk 30 Agustus
      final timeScreenshot = DateTime(2026, 8, 31, 0, 22);
      final operationalDate = service.getOperationalDate(timeScreenshot);

      expect(operationalDate.year, 2026);
      expect(operationalDate.month, 8);
      expect(operationalDate.day, 30);
      expect(service.getCurrentShift(timeScreenshot), 'Shift 2');

      final timeLateNight = DateTime(2026, 8, 31, 5, 45);
      final opLate = service.getOperationalDate(timeLateNight);
      expect(opLate.day, 30);
      expect(service.getCurrentShift(timeLateNight), 'Shift 2');
    });

    test('Pukul 06:00 ke atas hari baru -> tanggal operasional hari baru', () {
      final timeNewDay = DateTime(2026, 8, 31, 6, 0);
      expect(service.getOperationalDate(timeNewDay).day, 31);
      expect(service.getCurrentShift(timeNewDay), 'Shift 1');
    });
  });

  group('DailyCheckShiftDateService Cutoff Calculation', () {
    test('diset dini hari sebelum 06:00 -> cutoff jam 06:00 hari yang sama',
        () {
      final setAt = DateTime(2026, 8, 28, 1, 30);
      final cutoff = service.calculateCutoffTime(setAt);
      expect(cutoff, DateTime(2026, 8, 28, 6, 0, 0));
    });

    test('diset pagi/malam setelah 06:00 -> cutoff jam 06:00 keesokan harinya',
        () {
      final setAtMorning = DateTime(2026, 8, 28, 8, 0);
      expect(
        service.calculateCutoffTime(setAtMorning),
        DateTime(2026, 8, 29, 6, 0, 0),
      );

      final setAtNight = DateTime(2026, 8, 28, 22, 15);
      expect(
        service.calculateCutoffTime(setAtNight),
        DateTime(2026, 8, 29, 6, 0, 0),
      );
    });
  });

  group('DailyCheckShiftDateService Date Active & Auto Reset', () {
    test(
        'non-eligible company/site selalu mengembalikan DateTime.now() kalender',
        () {
      // Pada jam 00:22, site selain 1 tetap mendapat tanggal kalender 31 Agustus
      final now = DateTime(2026, 8, 31, 0, 22);
      final activeDate = service.getActiveDate(
        companyId: '2',
        siteId: '1',
        now: now,
      );
      expect(activeDate, now);
      expect(activeDate.day, 31);
    });

    test(
        'eligible company 1 site 1 default langsung tanggal shift (H-1 saat dini hari)',
        () {
      // Pada jam 00:22 tanpa input apa-apa, langsung otomatis 30 Agustus
      final now = DateTime(2026, 8, 31, 0, 22);
      final activeDate = service.getActiveDate(
        companyId: '1',
        siteId: '1',
        now: now,
      );
      expect(activeDate.day, 30);
    });

    test('custom date disimpan dan digunakan sebelum melewati 06:00', () {
      final setAt = DateTime(2026, 8, 28, 2, 0);
      final customDate = DateTime(2026, 8, 26);

      service.setCustomDate(
        customDate,
        companyId: '1',
        siteId: '1',
        now: setAt,
      );

      // Sebelum 06:00 (misal jam 04:30) -> masih customDate
      final checkTimeBeforeCutoff = DateTime(2026, 8, 28, 4, 30);
      final activeDate = service.getActiveDate(
        companyId: '1',
        siteId: '1',
        now: checkTimeBeforeCutoff,
      );

      expect(activeDate.year, customDate.year);
      expect(activeDate.month, customDate.month);
      expect(activeDate.day, customDate.day);
    });

    test('custom date auto-reset jika waktu melewati 06:00', () {
      final setAt = DateTime(2026, 8, 28, 2, 0);
      final customDate = DateTime(2026, 8, 25);

      service.setCustomDate(
        customDate,
        companyId: '1',
        siteId: '1',
        now: setAt,
      );

      // Setelah 06:00 (misal jam 06:01) -> auto reset ke tanggal operasional
      final checkTimeAfterCutoff = DateTime(2026, 8, 28, 6, 1);
      final activeDate = service.getActiveDate(
        companyId: '1',
        siteId: '1',
        now: checkTimeAfterCutoff,
      );

      expect(activeDate.day, 28);
    });

    test('custom shift disimpan dan auto-reset saat lewat 06:00', () {
      final setAt = DateTime(2026, 8, 28, 2, 0);

      // Default jam 02:00 adalah Shift 2
      expect(
        service.getActiveShift(
          companyId: '1',
          siteId: '1',
          now: setAt,
        ),
        'Shift 2',
      );

      // User ganti manual ke Shift 1
      service.setCustomShift(
        'Shift 1',
        companyId: '1',
        siteId: '1',
        now: setAt,
      );

      // Sebelum jam 06:00 -> tetap Shift 1 yang dipilih user
      expect(
        service.getActiveShift(
          companyId: '1',
          siteId: '1',
          now: DateTime(2026, 8, 28, 5, 0),
        ),
        'Shift 1',
      );

      // Setelah jam 06:00 -> auto reset ke shift aktif bawaan waktu saat itu
      expect(
        service.getActiveShift(
          companyId: '1',
          siteId: '1',
          now: DateTime(2026, 8, 28, 6, 1),
        ),
        'Shift 1', // Jam 06:01 shift bawaannya adalah Shift 1
      );
    });

    test('diset siang hari -> shift cutoff jam 18:00 hari yang sama', () {
      final setAtAfternoon = DateTime(2026, 8, 30, 16, 45);
      final shiftCutoff = service.calculateShiftCutoffTime(setAtAfternoon);
      expect(shiftCutoff, DateTime(2026, 8, 30, 18, 0, 0));
    });

    test('diset malam hari -> shift cutoff jam 06:00 keesokan harinya', () {
      final setAtNight = DateTime(2026, 8, 30, 20, 0);
      final shiftCutoff = service.calculateShiftCutoffTime(setAtNight);
      expect(shiftCutoff, DateTime(2026, 8, 31, 6, 0, 0));
    });

    test('diset dini hari -> shift cutoff jam 06:00 hari yang sama', () {
      final setAtEarly = DateTime(2026, 8, 31, 1, 30);
      final shiftCutoff = service.calculateShiftCutoffTime(setAtEarly);
      expect(shiftCutoff, DateTime(2026, 8, 31, 6, 0, 0));
    });

    test(
        'Kasus user: Diset saat sore (30 Agt 16:45), dicek saat 31 Agt 01:07 -> harus Shift 2 & tgl 30 Agt',
        () {
      final setAt = DateTime(2026, 8, 30, 16, 45);

      // Disimpan saat sore (Shift 1)
      service.setCustomShift(
        'Shift 1',
        companyId: '1',
        siteId: '1',
        now: setAt,
      );

      // Jam HP diubah ke 31 Agustus 01:07 dini hari
      final checkTime = DateTime(2026, 8, 31, 1, 7);

      // Karena sudah melewati cutoff jam 18:00 tgl 30, shift harus reset ke Shift 2
      final activeShift = service.getActiveShift(
        companyId: '1',
        siteId: '1',
        now: checkTime,
      );
      expect(activeShift, 'Shift 2');

      // Tanggal operasional jam 01:07 tgl 31 harus tetap 30 Agustus
      final activeDate = service.getActiveDate(
        companyId: '1',
        siteId: '1',
        now: checkTime,
      );
      expect(activeDate.year, 2026);
      expect(activeDate.month, 8);
      expect(activeDate.day, 30);
    });
  });
}
