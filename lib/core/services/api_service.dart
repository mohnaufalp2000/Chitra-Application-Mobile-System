import 'dart:convert';
import 'dart:developer';

import 'package:camos/core/services/model/daily_press.dart';
import 'package:camos/core/services/model/recc_press.dart';
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
  static const String postUrl =
      'https://cts-chitraparatama.co.id/ChitraTireMngr/product/getdatacamos.php?function=';

  // POST data daily check pressure
  static Future<void> postDailyCheckPressure(
      List<Map<String, dynamic>> data1,
      List<Map<String, dynamic>> data2,
      List<Map<String, dynamic>> data3) async {
    log('daily check api service : ${data3}');

    try {
      final response = await http.post(
        Uri.parse('${postUrl}post_daily'),
        headers: {"Content-Type": "application/json"},
        // body: jsonEncode({
        //   "data1": [
        //     {
        //       "target_daily": summaryData["target_daily"],
        //       "checked": summaryData["checked"],
        //       "low": summaryData["low"],
        //       "id_site": '2',
        //       "tgl_daily": dailyCheck[0].hari
        //     }
        //   ],
        //   "data2": dailyCheck
        //       .expand((daily) => daily.posisi
        //           .map((pos) => {
        //                 "id_daily": pos.idDaily,
        //                 "id_unit_site": pos.idUnit,
        //                 "pos": pos.pos,
        //                 "inv": pos.idInventory,
        //                 "tanggal_daily": daily.hari,
        //                 "press": pos.pressure,
        //                 "kondisi": pos.kondisi,
        //                 "id_site": "2",
        //                 "adj": "0"
        //               })
        //           .toList())
        //       .toList(),
        //   "data3": unitData,
        // }),
        body: jsonEncode({
          "data1": data1,
          "data2": data2,
          "data3": data3,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Berhasil
        // final body = jsonDecode(response.body);
        print('Raw response: ${response.body}');

        // print(
        //     'Raw response: ${body['status']}'); // Tambahkan ini untuk cek response asliS
      } else {
        // Gagal
        print('Gagal mengirim data. Status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error saat mengirim data: $e');
    }
  }

  // mendapatkan daftar unit di salah satu site
  static Future<List<UnitTire>> getUnits(String site) async {
    log('id site from daily : $site');
    final response =
        await http.get(Uri.parse('${url}get_tire_running&idsite=$site'));

    // try {
    final body = response.body;
    final result = jsonDecode(body);

    List<Map<String, dynamic>> recommendPressure =
        List<Map<String, dynamic>>.from(result['recc_press']);

    List<UnitTire> listUnitTire = List<UnitTire>.from(result['data'].map(
      (unit) => UnitTire.fromJson(unit),
    ));
    int countAllTire = result['total row'][0];
    // log('ban all : ${result['total row']}');

    List<UnitTire> fixData = [];

    listUnitTire.forEach((unit) {
      if (fixData.any((item) => item.unitNumber == unit.unitNumber)) {
        return;
      }
      fixData.add(unit);
    });

    // save unit
    await cacheUnits(listUnitTire, site);
    // save all tire count
    await cacheCountAllTire(countAllTire, site);
    // save recommendation pressure
    await cacheReccPress(recommendPressure);

    // for check data unit monthly
    await saveMonthYear(DateTime.now());
    return fixData;
    // } catch (e) {
    //   throw Exception(e.toString());
    // }
  }

  // static Future<void> cacheUnits(List<UnitTire> units) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final unitsJson = units.map((unit) => unit.toJson()).toList();
  //     final unitsJsonString = jsonEncode(unitsJson);
  //     await prefs.setString('cached_units', unitsJsonString);
  //   } catch (e) {
  //     // Handle error jika gagal menyimpan data.
  //     throw Exception('Gagal menyimpan data ke penyimpanan lokal: $e');
  //   }
  // }

  static Future<void> cacheReccPress(
      List<Map<String, dynamic>> reccPress) async {
    final prefs = await SharedPreferences.getInstance();

    final cacheKey = 'cache_recc_press';

    final reccPressJsonString = jsonEncode(reccPress);
    await prefs.setString(cacheKey, reccPressJsonString);
  }

  static Future<void> cacheUnits(List<UnitTire> units, String idSite) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Key unik berdasarkan idSite
      final cacheKey = 'cached_units_$idSite';

      final unitsJson = units.map((unit) => unit.toJson()).toList();
      final unitsJsonString = jsonEncode(unitsJson);
      await prefs.setString(cacheKey, unitsJsonString);
    } catch (e) {
      // Handle error jika gagal menyimpan data.
      throw Exception('Gagal menyimpan data ke penyimpanan lokal: $e');
    }
  }

  static Future<void> cacheCountAllTire(int countAllTire, String idSite) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Key unik berdasarkan idSite
      final cacheKey = 'cached_count_all_tire_$idSite';

      await prefs.setString(cacheKey, countAllTire.toString());
    } catch (e) {
      // Handle error jika gagal menyimpan data.
      throw Exception('Gagal menyimpan data ke penyimpanan lokal: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCachedReccPress() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cache_recc_press';

    final reccPressJsonString = prefs.getString(cacheKey);

    if (reccPressJsonString != null) {
      // Decode the JSON string back into a List<Map<String, dynamic>>
      final List<dynamic> decodedJson = jsonDecode(reccPressJsonString);
      return List<Map<String, dynamic>>.from(decodedJson);
    }

    // Return an empty list if no data is cached
    return [];
  }

  static Future<int> getCachedCountAllTire({String idSite = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_count_all_tire_$idSite';

    final countAllTire = int.tryParse(prefs.getString(cacheKey) ?? '');
    log('count all tire $countAllTire');

    if (countAllTire != null) {
      return countAllTire;
    }

    // Return an empty list if no data is cached
    return 0;
  }

  static Future<List<UnitTire>> getCachedUnits(
      {String unitNumber = '', String idSite = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cacheKey = 'cached_units_$idSite';

      final cachedData = prefs.getString(cacheKey);
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
      log('error inventory : ${e}');
      throw Exception(e.toString());
    }
  }

  // mendapatkan detail tire inventory
  static Future<List<TireSpec>> getDetailInventory(
      String status, String offset, String site) async {
    final response = await http.get(Uri.parse(
        '${url}get_tire&limit=10&offset=$offset&idsite=$site&status=$status'));

    log('error detail inventory body' + site);

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
      log('error detail inventory' + e.toString());
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

  // mendapatkan data salah satu site
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
