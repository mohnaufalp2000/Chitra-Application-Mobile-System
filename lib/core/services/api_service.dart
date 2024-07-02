import 'dart:convert';
import 'dart:developer';

import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/services/model/tire_spec.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/utils/data/spm.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String url =
      'https://cts-chitraparatama.co.id/ChitraTireMngr/product/api_get.php?function=';

  // mendapatkan daftar unit di salah satu site
  static Future<List<UnitTire>> getUnits(String site) async {
    final response =
        await http.get(Uri.parse('${url}get_tire_running&idsite=$site'));

    try {
      final body = response.body;
      final result = jsonDecode(body);

      List<UnitTire> listUnitTire = List<UnitTire>.from(result['data'].map(
        (unit) => UnitTire.fromJson(unit),
      ));

      List<UnitTire> fixData = [];

      listUnitTire.forEach((unit) {
        if (fixData.any((item) => item.unitNumber == unit.unitNumber)) {
          return;
        }
        fixData.add(unit);
      });

      await cacheUnits(listUnitTire);
      // for check data unit monthly
      await saveMonthYear(DateTime.now());
      return fixData;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> cacheUnits(List<UnitTire> units) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitsJson = units.map((unit) => unit.toJson()).toList();
      final unitsJsonString = jsonEncode(unitsJson);
      await prefs.setString('cached_units', unitsJsonString);
    } catch (e) {
      // Handle error jika gagal menyimpan data.
      throw Exception('Gagal menyimpan data ke penyimpanan lokal: $e');
    }
  }

  static Future<List<UnitTire>> getCachedUnits({String unitNumber = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_units');
      List<UnitTire> fixData = [];

      if (cachedData != null) {
        final cachedUnitsJson = jsonDecode(cachedData) as List<dynamic>;
        List<UnitTire> cachedUnits =
            cachedUnitsJson.map((json) => UnitTire.fromJson(json)).toList();

        // untuk detail pressure gauge
        if (unitNumber.isNotEmpty) {
          cachedUnits = cachedUnits
              .where((unit) => unit.unitNumber == unitNumber)
              .toList();
        } else {
          cachedUnits.forEach((unit) {
            if (fixData.any((item) => item.unitNumber == unit.unitNumber)) {
              return;
            }
            fixData.add(unit);
          });
          log('fixdata : ${fixData.length}');
          return fixData;
        }
        log('cachedUnits : ${cachedUnits.length}');
        return cachedUnits;
      }

      return [];
    } catch (e) {
      // Handle error jika gagal mengambil data.
      throw Exception('Gagal mengambil data dari penyimpanan lokal: $e');
    }
  }

  static Future<List<UnitTire>> getUniqueUnits(String site) async {
    final response =
        await http.get(Uri.parse('${url}get_tire_running&idsite=$site'));

    try {
      final body = response.body;
      final result = jsonDecode(body);

      List<UnitTire> listUnitTire = List<UnitTire>.from(result['data'].map(
        (unit) => UnitTire.fromJson(unit),
      ));

      // print('unitku ${fixData}');

      return listUnitTire;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // mendapatkan daftar tire di salah satu unit
  static Future<List<UnitTire>> getUnitTires(
      String site, String unitNumber) async {
    final response =
        await http.get(Uri.parse('${url}get_tire_running&idsite=$site'));

    try {
      final body = response.body;
      final result = jsonDecode(body);

      List<UnitTire> listUnitTire = List<UnitTire>.from(result['data'].map(
        (unit) => UnitTire.fromJson(unit),
      ));

      List<UnitTire> fixData = [];

      listUnitTire.forEach((unit) {
        if (unitNumber == unit.unitNumber) {
          fixData.add(unit);
        }
      });

      // print('unitku ${fixData}');
      await cacheUnitTires(fixData, unitNumber);

      return fixData;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> cacheUnitTires(
      List<UnitTire> units, String unitNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_units');

      List<Map<String, dynamic>> dataList = jsonDecode(cachedData ?? '');

      log('berubah : ${dataList.toString()}');

      // Map<String, dynamic> unitDataMap = {};

      // unitDataMap = jsonDecode(cachedData ?? '');

      // // Hapus entri lain yang memiliki unitNumber berbeda
      // unitDataMap.removeWhere((key, value) => key != unitNumber);

      // for (final unit in units) {
      //   final unitData = unit.toJson();

      //   if (!unitDataMap.containsKey(unitNumber)) {
      //     unitDataMap[unitNumber] = [unitData];
      //   } else {
      //     unitDataMap[unitNumber].add(unitData);
      //   }
      // }

      // await prefs.setString('cached_unit_tires', jsonEncode(unitDataMap));
      // final a = prefs.getString('cached_unit_tires');
    } catch (e) {
      // Handle error jika gagal menyimpan data.
      throw Exception('Gagal menyimpan data ke penyimpanan lokal: $e');
    }
  }

  static Future<List<UnitTire>> getCachedUnitTires(String unitNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_unit_tires');

      if (cachedData != null) {
        final cachedDataParsed = jsonDecode(cachedData);

        if (cachedDataParsed is Map<String, dynamic>) {
          if (cachedDataParsed.containsKey(unitNumber)) {
            final unitDataList = cachedDataParsed[unitNumber] as List<dynamic>;
            final units =
                unitDataList.map((data) => UnitTire.fromJson(data)).toList();
            return units;
          }
        } else if (cachedDataParsed is List<dynamic>) {
          // Iterate through the list and find matching entries
          final matchingUnits = <UnitTire>[];
          for (final unitData in cachedDataParsed) {
            final unit = UnitTire.fromJson(unitData);
            if (unit.unitNumber == unitNumber) {
              matchingUnits.add(unit);
            }
          }
          return matchingUnits;
        }
      }

      return []; // Return an empty list if no matching data found
    } catch (e) {
      // Handle error jika gagal mengambil data.
      throw Exception('Gagal mengambil data dari penyimpanan lokal: $e');
    }
  }

  // mendapatkan data tire condition di salah satu site
  static Future<List<UnitTire>> getTireCondition(String site) async {
    final response =
        await http.get(Uri.parse('${url}get_tire_running&idsite=$site'));

    try {
      final body = response.body;
      final result = jsonDecode(body);

      List<UnitTire> listUnitTire = List<UnitTire>.from(result['data'].map(
        (unit) => UnitTire.fromJson(unit),
      ));

      return listUnitTire;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // mendapatkan data gambar user dari firebase
  static Future<List<int>> fetchImageData(String firebaseStorageUrl) async {
    final response = await http.get(Uri.parse('${firebaseStorageUrl}'));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Gagal mengunduh gambar');
    }
  }

  // mendapatkan data tire inventory
  static Future<String> getTireSpecCount(String site, String status) async {
    final response = await http.get(Uri.parse(
        '${url}get_tire&limit=10&offset=10&idsite=$site&status=$status'));
    try {
      final body = response.body;
      final result = jsonDecode(body);
      String tireSpecCount = '';

      if (status == 'Scrap') {
        tireSpecCount =
            '${double.parse(result['Avg_lifetime']).round()}|${result['Total']}';
      } else {
        tireSpecCount = result['Total'] as String;
      }

      return tireSpecCount;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // mendapatkan detail tire inventory
  static Future<List<TireSpec>> getDetailInventory(
      String status, String offset, String site) async {
    final response = await http.get(Uri.parse(
        '${url}get_tire&limit=10&offset=$offset&idsite=$site&status=$status'));

    try {
      final body = response.body;
      // log(body.toString());

      final result = jsonDecode(body);

      List<TireSpec> listTireInvent =
          List<TireSpec>.from(result['data'].map((invent) {
        if (invent['size'] != null) {
          invent['size'] = invent['size'].replaceAll("-", "R");
        }
        return TireSpec.fromJson(invent);
      }));

      return listTireInvent;
    } catch (e) {
      log(e.toString());
      return [];
      // throw Exception(e.toString());
    }
  }

  // mendapatkan daftar site CK, PPA, Vale, Petrosea
  static Future<List<Site>> getAllSite() async {
    final response = await http.get(Uri.parse('${url}get_site'));

    try {
      final body = response.body;
      final result = jsonDecode(body);

      List<Site> listSite = List<Site>.from(result['data'].map(
        (site) => Site.fromJson(site),
      ));

      if (await getIdSitePreferences() == '2') {
        listSite = listSite
            .where((site) => site.site?.substring(0, 2) == 'CK')
            .toList();
      }
      return listSite;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // mendapatkan data salah satu site ck
  static Future<Site> getSite(String idSite) async {
    late Site site;
    final response = await http.get(Uri.parse('${url}get_site'));

    try {
      final body = response.body;

      final result = jsonDecode(body);

      List<Site> listSite = List<Site>.from(result['data'].map((site) {
        return Site.fromJson(site);
      }));

      if (idSite == '1') {
        site = listSite[1];
        saveSelectedIdSitePreferences(site.idSite ?? '');
      } else if (idSite == '2') {
        final ck =
            listSite.firstWhere((site) => site.site?.substring(0, 2) == 'CK');
        site = ck;
        saveSelectedIdSitePreferences(site.idSite ?? '');
      } else {
        site = listSite.firstWhere((site) => site.idSite == idSite);
      }
      return site;
    } catch (e) {
      log(e.toString());
      throw Exception(e.toString());
    }
  }

  // api TPMS
  static Future<List<Spm>> getApiSpm() async {
    final response = await http.get(Uri.parse('${url}get_tpms'));

    try {
      final body = response.body;

      final result = jsonDecode(body);

      log('hasilnya : $result');

      List<Spm> listSpm = List<Spm>.from(result['data'].map((pressure) {
        return Spm.fromJson(pressure);
      }));

      return listSpm;
    } catch (e) {
      log('error spm : $e');

      throw Exception(e.toString());
    }
  }
}
