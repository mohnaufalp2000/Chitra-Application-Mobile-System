import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> getSharedPreferences() async {
  return await SharedPreferences.getInstance();
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
  final Map<String, dynamic> user = jsonDecode(decoded ?? '');
  return user;
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
