import 'dart:convert';
import 'dart:developer';

import '../model/site.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> getSharedPreferences() async {
  return await SharedPreferences.getInstance();
}

String savedSiteCode = 'saved_sites';
String savedUserDailyCode = 'saved_user_daily';
String savedPitDailyCode = 'saved_pit_daily';

const String dailyCheckUnitList = 'daily_check';
const String tireInspectionUnitList = 'tire_inspection';

String _unitListApiLoadKey({required String idSite}) {
  return 'unit_list_last_api_load_shared_${idSite.trim()}';
}

String _legacyUnitListApiLoadKey({
  required String listType,
  required String idSite,
}) {
  return 'unit_list_last_api_load_${listType}_${idSite.trim()}';
}

String _localDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Mengembalikan true jika cache unit bersama belum pernah berhasil diperbarui
/// dari API untuk site terkait pada tanggal lokal hari ini.
///
/// Daily Check dan Tire Inspection menggunakan data serta cache unit yang sama,
/// sehingga satu refresh API yang berhasil berlaku untuk kedua halaman.
Future<bool> shouldLoadUnitListFromApiToday({
  required String idSite,
}) async {
  if (idSite.trim().isEmpty) return true;

  try {
    final prefs = await getSharedPreferences();
    final today = _localDateKey(DateTime.now());
    final lastApiLoad = prefs.getString(
      _unitListApiLoadKey(idSite: idSite),
    );

    if (lastApiLoad == today) return false;

    // Migrasi lazy dari penanda lama agar update aplikasi tidak menyebabkan
    // pemanggilan API kedua pada hari yang sama.
    for (final listType in <String>[
      dailyCheckUnitList,
      tireInspectionUnitList,
    ]) {
      final legacyLastApiLoad = prefs.getString(
        _legacyUnitListApiLoadKey(
          listType: listType,
          idSite: idSite,
        ),
      );

      if (legacyLastApiLoad == today) {
        await prefs.setString(
          _unitListApiLoadKey(idSite: idSite),
          today,
        );
        return false;
      }
    }

    return true;
  } catch (e) {
    log('Error membaca tanggal load API unit: $e');
    return true;
  }
}

/// Dipanggil hanya setelah API unit dan seluruh cache pendukung berhasil
/// dimuat. Penanda bersama ini dipakai Daily Check dan Tire Inspection.
Future<void> saveUnitListApiLoadedToday({
  required String idSite,
}) async {
  if (idSite.trim().isEmpty) return;

  try {
    final prefs = await getSharedPreferences();
    final today = _localDateKey(DateTime.now());

    await prefs.setString(
      _unitListApiLoadKey(idSite: idSite),
      today,
    );

    // Tetap menulis key lama untuk kompatibilitas jika aplikasi perlu
    // diturunkan sementara ke versi sebelumnya.
    await Future.wait(
      <Future<bool>>[
        for (final listType in <String>[
          dailyCheckUnitList,
          tireInspectionUnitList,
        ])
          prefs.setString(
            _legacyUnitListApiLoadKey(
              listType: listType,
              idSite: idSite,
            ),
            today,
          ),
      ],
    );
  } catch (e) {
    log('Error menyimpan tanggal load API unit: $e');
  }
}

/**
 * 
 * USER
 * 
 */

void saveUserPreferences(Map<String, dynamic> user) async {
  SharedPreferences prefs = await getSharedPreferences();
  final encoded = jsonEncode(user);
  prefs.setString('user', encoded);
}

Future<Map<String, dynamic>> getUserPreferences() async {
  SharedPreferences prefs = await getSharedPreferences();
  final decoded = prefs.getString('user');

  if (decoded == null || decoded.trim().isEmpty) return {};

  try {
    final user = jsonDecode(decoded);
    if (user is Map<String, dynamic>) return user;
    if (user is Map) return Map<String, dynamic>.from(user);
  } catch (e) {
    log('Error membaca cache user: $e');
  }

  return {};
}

void removeUserPreferences() async {
  SharedPreferences prefs = await getSharedPreferences();
  prefs.remove('user');
}

/**
 * 
 * ID SITE PREFERENCES
 */

void saveIdSitePreferences(String idSite) async {
  SharedPreferences prefs = await getSharedPreferences();
  await prefs.setString('idSite', idSite);
}

Future<String> getIdSitePreferences() async {
  SharedPreferences prefs = await getSharedPreferences();
  return prefs.getString('idSite') ?? '';
}

void removeIdSitePreferences() async {
  SharedPreferences prefs = await getSharedPreferences();
  prefs.remove('idSite');
}

void saveSelectedIdSitePreferences(String idSite) async {
  SharedPreferences prefs = await getSharedPreferences();
  await prefs.setString('selectSite', idSite);
}

Future<String> getSelectedIdSitePreferences() async {
  SharedPreferences prefs = await getSharedPreferences();
  return prefs.getString('selectSite') ?? '';
}

/**
 * 
 * MANPOWER SHIFT PREFERENCES
 */

void saveManpowerShiftPreferences({String shift = 'morning'}) async {
  SharedPreferences prefs = await getSharedPreferences();
  await prefs.setString('shift', shift);
}

void updateManpowerShiftPreference(String newShift) async {
  SharedPreferences prefs = await getSharedPreferences();
  await prefs.setString('shift', newShift);
}

Future<String> getManpowerShiftPreferences() async {
  SharedPreferences prefs = await getSharedPreferences();
  return prefs.getString('shift') ?? '';
}

void removeIManpowerShiftPreferences() async {
  SharedPreferences prefs = await getSharedPreferences();
  prefs.remove('shift');
}

void removeTireSpecPreferences() async {
  SharedPreferences prefs = await getSharedPreferences();
  prefs.remove('tire_spec');
}

void removeTireConditionPreferences() async {
  SharedPreferences prefs = await getSharedPreferences();
  prefs.remove('tire_condition');
}

void saveNumberVersion(String number) async {
  SharedPreferences prefs = await getSharedPreferences();
  prefs.setString('version', number);
}

Future<String> getNumberVersion() async {
  SharedPreferences prefs = await getSharedPreferences();
  return prefs.getString('version') ?? '';
}

// Fungsi untuk menyimpan bulan dan tahun sebagai string
Future<void> saveMonthYear(DateTime dateTime) async {
  final prefs = await SharedPreferences.getInstance();
  String monthYearString = "${dateTime.year}-${dateTime.month}";
  await prefs.setString('saved_month_year', monthYearString);
}

// Fungsi untuk mengambil bulan dan tahun yang disimpan
Future<String?> getSavedMonthYear() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('saved_month_year');
}

// menyimpan data id site
Future<void> saveSiteToLocalPreferences(List<Site> listSite) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Convert listSite to a list of maps, then to JSON
  List<String> siteListJson = listSite.map((site) {
    return jsonEncode({
      'idSite': site.idSite,
      'site': site.site,
      'lastUpdate': site.lastUpdate,
    });
  }).toList();

  // Simpan ke SharedPreferences
  await prefs.setStringList(savedSiteCode, siteListJson);
}

// mendapatkan data id site
Future<List<Site>> getSiteFromLocalPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Ambil data yang disimpan
  List<String>? siteListJson = prefs.getStringList(savedSiteCode);

  // Jika data tidak ditemukan, kembalikan list kosong
  if (siteListJson == null) {
    return [];
  }

  // Convert JSON ke List<Site>
  return siteListJson.map((siteJson) {
    Map<String, dynamic> siteMap = jsonDecode(siteJson);
    return Site(
      idSite: siteMap['idSite'],
      site: siteMap['site'],
      lastUpdate: siteMap['lastUpdate'],
    );
  }).toList();
}

// Fungsi untuk menyimpan user  yang dipilih
Future<void> saveUserDaily(String username) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(savedUserDailyCode, username);
}

Future<String> getUserDaily() async {
  SharedPreferences prefs = await getSharedPreferences();
  return prefs.getString(savedUserDailyCode) ?? '';
}

String _inspectionUsernameKey(String accountId) {
  final encodedAccountId =
      base64Url.encode(utf8.encode(accountId.trim())).replaceAll('=', '');
  return 'inspection_username_$encodedAccountId';
}

/// Menyimpan nama inspector yang terakhir diinput untuk akun terkait.
/// Nilai kosong menghapus override sehingga form kembali memakai username akun.
Future<void> saveInspectionUsername({
  required String accountId,
  required String username,
}) async {
  if (accountId.trim().isEmpty) return;

  final prefs = await getSharedPreferences();
  final key = _inspectionUsernameKey(accountId);
  final normalizedUsername = username.trim();

  if (normalizedUsername.isEmpty) {
    await prefs.remove(key);
    return;
  }

  await prefs.setString(key, normalizedUsername);
}

Future<String> getInspectionUsername({required String accountId}) async {
  if (accountId.trim().isEmpty) return '';

  final prefs = await getSharedPreferences();
  return prefs.getString(_inspectionUsernameKey(accountId))?.trim() ?? '';
}

Future<void> saveListCustomer(
    List<Map<String, dynamic>> listCustPgDigitalData) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String encodedData = jsonEncode(listCustPgDigitalData);
  await prefs.setString('listCustPgDigitalData', encodedData);
}

Future<List<Map<String, dynamic>>> getListListCustomer() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? encodedData = prefs.getString('listCustPgDigitalData');

  if (encodedData != null) {
    List<dynamic> decodedList = jsonDecode(encodedData);
    return decodedList.map((e) => e as Map<String, dynamic>).toList();
  }
  return []; // Return list kosong jika tidak ada data
}
