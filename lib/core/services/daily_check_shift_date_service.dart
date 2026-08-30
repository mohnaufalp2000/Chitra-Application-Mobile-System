import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class DailyCheckShiftDateService {
  DailyCheckShiftDateService._();
  static final DailyCheckShiftDateService instance =
      DailyCheckShiftDateService._();

  final GetStorage _box = GetStorage();

  static const String _keySelectedDate = 'daily_check_shift_custom_date';
  static const String _keyDateSetAt = 'daily_check_shift_custom_date_set_at';
  static const String _keySelectedShift = 'daily_check_shift_custom_shift';
  static const String _keyShiftSetAt = 'daily_check_shift_custom_shift_set_at';
  static const String _keySetAt = 'daily_check_shift_custom_set_at';
  static const String _keyCompanyId = 'daily_check_shift_company_id';
  static const String _keySiteId = 'daily_check_shift_site_id';

  /// Memeriksa apakah fitur pemilihan tanggal shift aktif untuk company dan site ini.
  /// Hanya aktif untuk Company ID '1' dan Site ID '1'.
  bool isEligible(String companyId, String siteId) {
    return companyId.trim() == '1' && siteId.trim() == '1';
  }

  /// Menghitung tanggal operasional tambang berdasarkan siklus shift (06:00 s/d 06:00).
  /// - Pukul 06:00 - 23:59 -> Hari ini
  /// - Pukul 00:00 - 05:59 -> Kemarin (Shift 2 malam sebelumnya)
  DateTime getOperationalDate([DateTime? now]) {
    final time = now ?? DateTime.now();
    if (time.hour < 6) {
      return time.subtract(const Duration(days: 1));
    }
    return time;
  }

  /// Mendapatkan nama shift aktif berdasarkan jam saat ini.
  /// - 06:00 - 17:59 -> Shift 1
  /// - 18:00 - 05:59 -> Shift 2
  String getCurrentShift([DateTime? now]) {
    final time = now ?? DateTime.now();
    if (time.hour >= 6 && time.hour < 18) {
      return 'Shift 1';
    }
    return 'Shift 2';
  }

  /// Mendapatkan shift aktif yang harus digunakan untuk form Daily Check.
  /// Jika user pernah memilih custom shift dan belum melewati cutoff pergantian shift, mengembalikan custom shift tersebut.
  /// Jika tidak ada custom shift atau sudah lewat cutoff shift, mengembalikan shift bawaan waktu saat ini.
  String getActiveShift({
    required String companyId,
    required String siteId,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final defaultShift = getCurrentShift(currentTime);
    if (!isEligible(companyId, siteId)) {
      return defaultShift;
    }

    final storedCompanyId = _box.read<String>(_keyCompanyId) ?? '';
    final storedSiteId = _box.read<String>(_keySiteId) ?? '';
    if (storedCompanyId != companyId.trim() || storedSiteId != siteId.trim()) {
      return defaultShift;
    }

    final storedShift = _box.read<String>(_keySelectedShift);
    final storedSetAtStr =
        _box.read<String>(_keyShiftSetAt) ?? _box.read<String>(_keySetAt);
    if (storedShift == null || storedSetAtStr == null) {
      return defaultShift;
    }

    final setAt = DateTime.tryParse(storedSetAtStr);
    if (setAt == null) {
      clearCustomShift();
      return defaultShift;
    }

    final cutoff = calculateShiftCutoffTime(setAt);
    if (currentTime.isAfter(cutoff) || currentTime.isAtSameMomentAs(cutoff)) {
      clearCustomShift();
      return defaultShift;
    }

    return storedShift;
  }

  /// Mendapatkan tanggal aktif yang harus digunakan untuk form Daily Check.
  /// Jika syarat eligible terpenuhi dan custom date belum melewati cutoff jam 06:00,
  /// mengembalikan custom date. Jika tidak ada custom date, mengembalikan tanggal operasional shift.
  DateTime getActiveDate({
    required String companyId,
    required String siteId,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    if (!isEligible(companyId, siteId)) {
      return currentTime;
    }

    final defaultDate = getOperationalDate(currentTime);

    final storedCompanyId = _box.read<String>(_keyCompanyId) ?? '';
    final storedSiteId = _box.read<String>(_keySiteId) ?? '';
    if (storedCompanyId != companyId.trim() || storedSiteId != siteId.trim()) {
      return defaultDate;
    }

    final storedDateStr = _box.read<String>(_keySelectedDate);
    final storedSetAtStr =
        _box.read<String>(_keyDateSetAt) ?? _box.read<String>(_keySetAt);
    if (storedDateStr == null || storedSetAtStr == null) {
      return defaultDate;
    }

    final setAt = DateTime.tryParse(storedSetAtStr);
    final selectedDate = DateTime.tryParse(storedDateStr);
    if (setAt == null || selectedDate == null) {
      clearCustomDate();
      return defaultDate;
    }

    final cutoff = calculateCutoffTime(setAt);
    if (currentTime.isAfter(cutoff) || currentTime.isAtSameMomentAs(cutoff)) {
      // Sudah melewati batas jam 06:00 -> auto reset ke tanggal operasional
      clearCustomDate();
      return defaultDate;
    }

    return selectedDate;
  }

  /// Menghitung waktu cutoff pergantian shift berikutnya setelah waktu [setAt].
  /// - Shift 1 (06:00 - 17:59): cutoff jam 18:00 hari yang sama (pergantian ke Shift 2).
  /// - Shift 2 malam (18:00 - 23:59): cutoff jam 06:00 keesokan harinya (pergantian ke Shift 1).
  /// - Shift 2 dini hari (00:00 - 05:59): cutoff jam 06:00 hari yang sama (pergantian ke Shift 1).
  DateTime calculateShiftCutoffTime(DateTime setAt) {
    if (setAt.hour >= 6 && setAt.hour < 18) {
      return DateTime(setAt.year, setAt.month, setAt.day, 18, 0, 0);
    } else if (setAt.hour >= 18) {
      final nextDay = setAt.add(const Duration(days: 1));
      return DateTime(nextDay.year, nextDay.month, nextDay.day, 6, 0, 0);
    } else {
      return DateTime(setAt.year, setAt.month, setAt.day, 6, 0, 0);
    }
  }

  /// Menghitung waktu cutoff jam 06:00 setelah waktu [setAt].
  /// - Jika diset sebelum jam 06:00 (misal 01:00 pada tgl D), cutoff adalah tgl D jam 06:00:00.
  /// - Jika diset pada/setelah jam 06:00 (misal 21:00 pada tgl D), cutoff adalah tgl D+1 jam 06:00:00.
  DateTime calculateCutoffTime(DateTime setAt) {
    if (setAt.hour < 6) {
      return DateTime(setAt.year, setAt.month, setAt.day, 6, 0, 0);
    } else {
      final nextDay = setAt.add(const Duration(days: 1));
      return DateTime(nextDay.year, nextDay.month, nextDay.day, 6, 0, 0);
    }
  }

  /// Menyimpan tanggal kustom yang dipilih tireman.
  void setCustomDate(
    DateTime date, {
    required String companyId,
    required String siteId,
    DateTime? now,
  }) {
    if (!isEligible(companyId, siteId)) return;

    final currentTime = now ?? DateTime.now();
    final dateOnlyString = DateFormat('yyyy-MM-dd').format(date);

    _box.write(_keySelectedDate, dateOnlyString);
    _box.write(_keyDateSetAt, currentTime.toIso8601String());
    _box.write(_keySetAt, currentTime.toIso8601String());
    _box.write(_keyCompanyId, companyId.trim());
    _box.write(_keySiteId, siteId.trim());
  }

  /// Menyimpan shift kustom yang dipilih tireman.
  void setCustomShift(
    String shift, {
    required String companyId,
    required String siteId,
    DateTime? now,
  }) {
    if (!isEligible(companyId, siteId)) return;

    final currentTime = now ?? DateTime.now();

    _box.write(_keySelectedShift, shift.trim());
    _box.write(_keyShiftSetAt, currentTime.toIso8601String());
    _box.write(_keySetAt, currentTime.toIso8601String());
    _box.write(_keyCompanyId, companyId.trim());
    _box.write(_keySiteId, siteId.trim());
  }

  /// Menghapus tanggal kustom dan mengembalikan ke default.
  void clearCustomDate() {
    _box.remove(_keySelectedDate);
    _box.remove(_keyDateSetAt);
    if (!_box.hasData(_keySelectedShift)) {
      _box.remove(_keySetAt);
      _box.remove(_keyCompanyId);
      _box.remove(_keySiteId);
    }
  }

  /// Menghapus shift kustom dan mengembalikan ke default.
  void clearCustomShift() {
    _box.remove(_keySelectedShift);
    _box.remove(_keyShiftSetAt);
    if (!_box.hasData(_keySelectedDate)) {
      _box.remove(_keySetAt);
      _box.remove(_keyCompanyId);
      _box.remove(_keySiteId);
    }
  }

  /// Menghapus semua tanggal dan shift kustom dan mengembalikan ke default.
  void clearAllCustom() {
    _box.remove(_keySelectedDate);
    _box.remove(_keyDateSetAt);
    _box.remove(_keySelectedShift);
    _box.remove(_keyShiftSetAt);
    _box.remove(_keySetAt);
    _box.remove(_keyCompanyId);
    _box.remove(_keySiteId);
  }
}
