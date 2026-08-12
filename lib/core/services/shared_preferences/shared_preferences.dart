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

String _unitListApiLoadKey({
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

/// Mengembalikan true jika list ini belum pernah berhasil memuat unit dari
/// API untuk site terkait pada tanggal lokal hari ini.
Future<bool> shouldLoadUnitListFromApiToday({
  required String listType,
  required String idSite,
}) async {
  if (idSite.trim().isEmpty) return true;

  try {
    final prefs = await getSharedPreferences();
    final lastApiLoad = prefs.getString(
      _unitListApiLoadKey(
        listType: listType,
        idSite: idSite,
      ),
    );

    return lastApiLoad != _localDateKey(DateTime.now());
  } catch (e) {
    log('Error membaca tanggal load API unit: $e');
    return true;
  }
}

/// Dipanggil hanya setelah API unit benar-benar berhasil. Daily Check dan
/// Tire Inspection memakai key terpisah agar masing-masing refresh sekali
/// dalam sehari.
Future<void> saveUnitListApiLoadedToday({
  required String listType,
  required String idSite,
}) async {
  if (idSite.trim().isEmpty) return;

  try {
    final prefs = await getSharedPreferences();
    await prefs.setString(
      _unitListApiLoadKey(
        listType: listType,
        idSite: idSite,
      ),
      _localDateKey(DateTime.now()),
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
