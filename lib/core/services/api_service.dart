import 'dart:convert';
import 'dart:developer';

import 'package:camos/core/services/model/daily_press.dart';
import 'package:camos/core/services/model/material_repair_model.dart';
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
  static const String tirePostUrl =
      'https://chitraparatama.co.id/ICS/product/push_data.php?function=';
  static const String jobcardUrl =
      'https://chitraparatama.co.id/ICS/product/get_api.php?function=';

  // Post job jobcard repair
  static Future<void> postJobJobcardRepair(Map<String, dynamic> jobcard) async {
    try {
      final response = await http.post(Uri.parse('${tirePostUrl}new_job'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(jobcard));
      log('success kirim data');
      log('Response status: ${response.statusCode}');
    } catch (e) {
      print('Error saat mengirim data jobcard repair: $e');
    }
  }

  // Get Material Repair
  static Future<List<MaterialRepair>> getMaterialRepairList() async {
    try {
      final response =
          await http.get(Uri.parse('${jobcardUrl}repair_material'));
      if (response.statusCode == 200) {
        final body = response.body;
        final result = jsonDecode(body);

        print('material data : $result');

        final List<MaterialRepair> materialList = List<MaterialRepair>.from(
            result['data']
                .map((material) => MaterialRepair.fromJson(material)));

        return materialList;
      } else {
        throw Exception(
            'Failed to load data, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error Get Material Repair : $e');
      return [];
    }
  }

  // GET data WO Jobcard
  static Future<List<Map<String, dynamic>>> getWOJobcardList() async {
    try {
      final response = await http.get(Uri.parse('${jobcardUrl}wo_repair'));

      print('status code : ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body;
        final result = jsonDecode(body);
        final List<dynamic> dataList = result['data'];

        final List<Map<String, dynamic>> woList = dataList.map((item) {
          return {
            'id_wo': item['id_wo'],
            'wo': item['wo'],
            'wo_date': item['wo_date']
          };
        }).toList();

        return woList;
      } else {
        throw Exception(
            'Failed to load data, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saat mendapatkan data wo jobcard repair: $e');
      return [];
    }
  }

  // POST data new tire repair
  static Future<void> postNewTireRepair(Map<String, dynamic> newTireMap) async {
    try {
      final response = await http.post(
          Uri.parse('${tirePostUrl}new_tire_repair'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(newTireMap));
      log('success kirim data');
      log('Response status: ${response.statusCode}');
    } catch (e) {
      print('Error saat mengirim data new tire repair: $e');
    }
  }

  // EDIT data new tire repair
  static Future<void> editNewTireRepair(
      Map<String, dynamic> editTireMap) async {
    log('body edit : $editTireMap');
    try {
      final response = await http.post(Uri.parse('${tirePostUrl}inspect'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(editTireMap));
      log('Response status: ${response.statusCode}');
    } catch (e) {
      print('Error saat edit data new tire repair: $e');
    }
  }

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

    // listUnitTire.forEach((unit) {
    //   if (fixData.any((item) => item.unitNumber == unit.unitNumber)) {
    //     return;
    //   }
    //   fixData.add(unit);
    // });

    Set<String> seenUnitNumbers = {}; // Untuk menyimpan unitNumber unik
    Map<String, int> sizeCount = {};
    Set<String> sizes = {};

    for (var unit in listUnitTire) {
      // Gunakan Set untuk pengecekan unitNumber agar lebih cepat
      if (seenUnitNumbers.add(unit.unitNumber ?? '')) {
        fixData.add(unit); // Tambahkan hanya jika unitNumber belum ada
      }

      String size = unit.size ?? '';
      if (size.isNotEmpty) {
        sizes.add(size); // Simpan ukuran unik

        // Hitung sizeCount untuk SEMUA data, tanpa tergantung fixData
        sizeCount[size] = (sizeCount[size] ?? 0) + 1;
      }
    }
// Buat struktur data baru
    Map<String, dynamic> sizeResult = {
      "sizes": sizes.toList(), // Konversi Set ke List
      "sizeCount": sizeCount
    };

    // save unit
    await cacheUnits(listUnitTire, site);
    // save all tire count
    await cacheCountAllTire(countAllTire, site);
    // save recommendation pressure
    await cacheReccPress(recommendPressure);
    // save size tire with quantity
    await cacheTireSize(sizeCount, sizes.toList(), site);

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

  static Future<void> cacheTireSize(
      Map<String, int> sizeCount, List<String> sizes, String idSite) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Konversi sizeCount (Map) ke String JSON
    String sizeCountJson = jsonEncode(sizeCount);

    // Simpan daftar ukuran ban (sizes)
    await prefs.setStringList("tire_sizes_$idSite", sizes);

    // Simpan sizeCount sebagai JSON String
    await prefs.setString("size_count_$idSite", sizeCountJson);
  }

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

  static Future<Map<String, dynamic>> getCachedTireSize(
      {String idSite = ''}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Ambil daftar ukuran ban
    List<String> sizes = prefs.getStringList("tire_sizes_$idSite") ?? [];

    // Ambil sizeCount (konversi kembali dari JSON ke Map)
    String? sizeCountJson = prefs.getString("size_count_$idSite");
    Map<String, int> sizeCount = sizeCountJson != null
        ? Map<String, int>.from(jsonDecode(sizeCountJson))
        : {};

    print("Data berhasil diambil dari SharedPreferences!");

    return {
      "sizes": sizes,
      "sizeCount": sizeCount,
    };
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
      await cachedAllSites(listSite);
      return listSite;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> cachedAllSites(List<Site> listSite) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData =
        jsonEncode(listSite.map((site) => site.toJson()).toList());
    await prefs.setString('cached_sites', jsonData);
  }

  // Fungsi untuk membaca listSite dari SharedPreferences
  static Future<List<Site>> getCachedAllSites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString('cached_sites');

    if (jsonData == null) return [];

    final List<dynamic> decodedData = jsonDecode(jsonData);
    return decodedData.map((e) => Site.fromJson(e)).toList();
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
  static Future<List<Spm>> getApiSpm(String idSite, String res) async {
    final response = await http.get(Uri.parse('$res$idSite'));

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
