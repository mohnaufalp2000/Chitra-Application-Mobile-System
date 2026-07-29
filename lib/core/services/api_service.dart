import 'dart:convert';
import 'dart:developer';

import 'package:camos/core/services/model/auto_tapping_model.dart';
import 'package:camos/core/services/model/send_tire_inspection.dart';
import 'package:camos/core/services/model/tire_damage_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'model/daily_press.dart';
import 'model/material_repair_model.dart';
import 'model/recc_press.dart';
import 'model/site.dart';
import 'model/tire_spec.dart';
import 'model/unit_tire.dart';
import 'shared_preferences/shared_preferences.dart';
import '../utils/data/spm.dart';
import '../utils/data/spm_jam7.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String url =
      'https://cts-chitraparatama.co.id/ChitraTireMngr/product/api_get.php?function=';
  static const String postUrl =
      'https://cts-chitraparatama.co.id/ChitraTireMngr/product/getdatacamos.php?function=';

  static Future<String?> _getFieldFromFirestore(
    String collection,
    String docId,
    String fieldName,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .get();

      if (!doc.exists) {
        log('❌ Dokumen $docId tidak ditemukan di Firestore.');
        return null;
      }

      final value = doc.data()?[fieldName];

      if (value == null || value.toString().isEmpty) {
        log('⚠️ Field $fieldName kosong di dokumen $docId.');
        return null;
      }

      return value.toString();
    } catch (e) {
      log('🔥 Error mengambil $fieldName Firestore ($docId): $e');
      return null;
    }
  }

  static Future<String> selectedParam1(String api) async {
    final user = await getUserPreferences();

    if (api != 'get_tire_running') {
      return '';
    }

    if (user['id_company'] == '1') {
      return await _getFieldFromFirestore(
            'url_sis',
            'get_tire_running',
            'param1',
          ) ??
          '&date=';
    }

    return '&date=';
  }

  static Future<String?> selectedUrl(String api) async {
    final user = await getUserPreferences();

    log('selected url user : ${user}');

    if (user['id_company'] == '1') {
      print('id company if');
      switch (api) {
        case 'post_tire_inspection':
          return await _getUrlFromFirestore(
                  'url_sis', 'post_tire_inspection') ??
              '';
        case 'post_daily_pressure':
          return await _getUrlFromFirestore('url_sis', 'post_daily_pressure') ??
              '';
        case 'get_site':
          return await _getUrlFromFirestore('url_sis', 'get_site') ?? '';
        case 'get_tire_running':
          return await _getUrlFromFirestore('url_sis', 'get_tire_running') ??
              '';
      }
      '';
    } else {
      print('id company else');
      switch (api) {
        case 'post_tire_inspection':
          return '${postUrl}post_inspect';
        case 'post_daily_pressure':
          return '${postUrl}post_daily';
        case 'get_site':
          return '${url}get_site';
        case 'get_tire_running':
          return '${url}get_tire_running&idsite=';
      }
    }
    return '';
  }

  /// 🔹 Ambil URL dari Firestore
  static Future<String?> _getUrlFromFirestore(
      String collection, String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .get();

      if (!doc.exists) {
        log('❌ Dokumen $docId tidak ditemukan di Firestore.');
        return null;
      }

      final url = doc.data()?['url'];
      if (url == null || url.isEmpty) {
        log('⚠️ URL kosong di dokumen $docId.');
        return null;
      }

      return url;
    } catch (e) {
      log('🔥 Error ambil URL Firestore ($docId): $e');
      return null;
    }
  }

  static Future<String?> _getKeyFromFirestore(
      String collection, String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .get();

      if (!doc.exists) {
        log('❌ Dokumen $docId tidak ditemukan di Firestore.');
        return null;
      }

      final key = doc.data()?['key'];
      if (key == null || key.isEmpty) {
        log('⚠️ key kosong di dokumen $docId.');
        return null;
      }

      return key;
    } catch (e) {
      log('🔥 Error ambil Key Firestore ($docId): $e');
      return null;
    }
  }

  // GET: Auto Tapping SPM
  static Future<List<AutoTappingModel>> getAutoTappingSPM() async {
    final urll = await _getUrlFromFirestore('url_camos', 'get_auto_tapping');
    if (urll == null) return [];
    print('auto tapping url : $urll');

    try {
      final response = await http.get(Uri.parse(urll));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        log('result auto tapping (${result['data']} )');

        final List<AutoTappingModel> autoTappingList =
            List<AutoTappingModel>.from(
          result['data'].map((e) => AutoTappingModel.fromMap(e)),
        );
        log('✅ Berhasil ambil auto tapping (${autoTappingList} item)');
        return autoTappingList;
      } else {
        throw Exception('Gagal load data: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error ambil auto tapping : $e');
      return [];
    }
  }

  /// 🔹 POST: Send Data Tire Inspection
  static Future<void> sendTireInspection(
    SendTireInspectionRequest request,
  ) async {
    try {
      final url = await selectedUrl('post_tire_inspection') ?? '';

      if (url.isEmpty) {
        throw Exception('URL post_tire_inspection tidak ditemukan');
      }

      final body = request.toJson();

      log('=== SEND TIRE INSPECTION ===');
      log('URL : $url');
      log('Payload : ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      log('=== RESPONSE TIRE INSPECTION ===');
      log('URL : ${response.request?.url}');
      log('Status Code : ${response.statusCode}');
      log('Headers : ${response.headers}');
      log('Body : ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Gagal send tire inspection. '
          'Status: ${response.statusCode}, '
          'Body: ${response.body}',
        );
      }

      log('Successful send tire inspection');
    } catch (e, stackTrace) {
      log(
        'Error send tire inspection : $e',
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  /// 🔹 POST: Predict Image AI
  static Future<TireDamageAi?> postPredictImageAI(
    String token,
    String base64Image,
  ) async {
    final url =
        await _getUrlFromFirestore('url_tire_damage_ai', 'predict-image');
    if (url == null) return null;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'image': base64Image,
          "visualize": false,
        }),
      );

      log("RESPONSE AI CODE API: ${response.statusCode}");
      log("RESPONSE AI BODY API: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = TireDamageAi.fromJson(response.body);

        log("RESPONSE AI RESULT API: ${result}");

        return result;
      } else {
        log("ERROR API: ${response.statusCode}");
        log("BODY: ${response.body}");
        return null;
      }
    } catch (e) {
      log("ERROR EXCEPTION: $e");
      return null;
    }
  }

  static String? _token;
  static DateTime? _expiredAt;
  static Future<String> getValidToken() async {
    final now = DateTime.now();

    // cek apakah token masih valid (kasih buffer 5 menit)
    if (_token != null &&
        _expiredAt != null &&
        now.isBefore(_expiredAt!.subtract(Duration(minutes: 5)))) {
      return _token!;
    }

    // kalau expired / belum ada → ambil baru
    final newToken = await getTokenAI();

    if (newToken.isNotEmpty) {
      _token = newToken;
      _expiredAt = now.add(Duration(minutes: 60));
    }
    log('token : $_token');

    return _token ?? '';
  }

  static Future<String> getTokenAI() async {
    final url = await _getUrlFromFirestore('url_tire_damage_ai', 'get-token');
    if (url == null) return '';

    final apiKey = await _getKeyFromFirestore('url_tire_damage_ai', 'api-key');
    print('apiKey : $apiKey');
    final secretKey =
        await _getKeyFromFirestore('url_tire_damage_ai', 'secret-key');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
          {
            'api_key': apiKey,
            'secret_key': secretKey,
          },
        ),
      );

      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];

      log('✅ Berhasil Get Token AI');
      log('Response status: ${response.statusCode}');
      log('Response body: ${accessToken}');

      return accessToken;
    } catch (e) {
      log('❌ Error Get Token AI : $e');
    }
    return '';
  }

  /// 🔹 POST: Jobcard Repair
  static Future<void> postJobJobcardRepair(Map<String, dynamic> jobcard) async {
    final url =
        await _getUrlFromFirestore('url_tire_repair', 'post-jobcard-repair');
    if (url == null) return;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jobcard),
      );
      log('✅ Berhasil kirim Jobcard Repair');
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');
    } catch (e) {
      log('❌ Error kirim Jobcard Repair: $e');
    }
  }

  /// 🔹 EDIT: Jobcard Repair
  static Future<void> editJobJobcardRepair(Map<String, dynamic> jobcard) async {
    final url =
        await _getUrlFromFirestore('url_tire_repair', 'edit-jobcard-repair');
    if (url == null) return;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jobcard),
      );
      log('✅ Berhasil edit Jobcard Repair');
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');
    } catch (e) {
      log('❌ Error edit Jobcard Repair: $e');
    }
  }

  /// 🔹 GET: Material Repair List
  static Future<List<MaterialRepair>> getMaterialRepairList() async {
    final url = await _getUrlFromFirestore(
        'url_tire_repair', 'get-material-list-repair');
    if (url == null) return [];

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<MaterialRepair> materialList = List<MaterialRepair>.from(
          result['data'].map((e) => MaterialRepair.fromJson(e)),
        );
        log('✅ Berhasil ambil Material Repair (${materialList.length} item)');
        return materialList;
      } else {
        throw Exception('Gagal load data: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error ambil Material Repair: $e');
      return [];
    }
  }

  /// 🔹 GET: WO Jobcard List
  static Future<List<Map<String, dynamic>>> getWOJobcardList() async {
    final url =
        await _getUrlFromFirestore('url_tire_repair', 'wo-jobcard-repair');
    if (url == null) return [];

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final dataList = result['data'] as List<dynamic>;

        final woList = dataList.map((item) {
          return {
            'id_wo': item['id_wo'],
            'wo': item['wo'],
            'wo_date': item['wo_date'],
          };
        }).toList();

        log('✅ Berhasil ambil WO Jobcard (${woList.length} data)');
        return woList;
      } else {
        throw Exception('Gagal load data: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error ambil WO Jobcard: $e');
      return [];
    }
  }

  /// 🔹 POST: New Tire Repair
  static Future<void> postNewTireRepair(Map<String, dynamic> newTireMap) async {
    final url =
        await _getUrlFromFirestore('url_tire_repair', 'post-new-tire-repair');
    if (url == null) return;

    try {
      final response = await http.post(
        Uri.parse(url.trim()),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(newTireMap),
      );
      log('✅ Berhasil kirim New Tire Repair');
      log('Response new tire post URL : ${url.trim()}');
      log('Response new tire post status: ${response.statusCode}');
      log('Response new tire post bodu: ${response.body}');
      log('Response new tire postHeaders: ${response.headers}');
      log('Response new tire post Redirect Location: ${response.headers['location'] ?? ''}');
    } catch (e) {
      log('❌ Error kirim New Tire Repair: $e');
    }
  }

  /// 🔹 POST: Edit Tire Repair
  static Future<void> editNewTireRepair(
      Map<String, dynamic> editTireMap) async {
    final url =
        await _getUrlFromFirestore('url_tire_repair', 'edit-new-tire-repair');
    if (url == null) return;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(editTireMap),
      );
      log('✅ Edit Tire Repair berhasil');
      log('Response status: ${response.statusCode}');
    } catch (e) {
      log('❌ Error edit Tire Repair: $e');
    }
  }

  // POST data daily check pressure
  static Future<void> postDailyCheckPressure(
      List<Map<String, dynamic>> data1,
      List<Map<String, dynamic>> data2,
      List<Map<String, dynamic>> data3) async {
    try {
      // Filter URL Customer
      final url = await selectedUrl('post_daily_pressure') ?? '';

      log('send daily url : $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "data1": data1,
          "data2": data2,
          "data3": data3,
        }),
      );
      log('body send data : ${{
        "data1": data1,
        "data2": data2,
        "data3": data3,
      }}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('send data success : ${response}');
      } else {
        // Gagal
        print('Gagal mengirim data. Status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error saat mengirim data: $e');
    }
  }

  // Mendapatkan daftar unit di salah satu site.
  static Future<List<UnitTire>> getUnits(String site) async {
    try {
      // final String baseUrl = await selectedUrl('get_tire_running') ?? '';
      final baseUrl = await selectedUrl('get_tire_running');
      final param1 = await selectedParam1('get_tire_running');

      if (baseUrl == null || baseUrl.isEmpty) {
        log('URL get_tire_running kosong');
        return [];
      }

      final now = DateTime.now();

      final String date = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final finalUrl = '$baseUrl$site$param1$date';

      if (baseUrl.trim().isEmpty) {
        throw Exception('URL get_tire_running kosong');
      }

      // final Uri requestUrl = Uri.parse('$baseUrl$site');
      final Uri requestUrl = Uri.parse('$finalUrl');

      log('URL get tire running: $requestUrl');

      final response = await http.get(requestUrl);

      log('Status get tire running: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          'Get tire running gagal. '
          'Status: ${response.statusCode}, '
          'Body: ${response.body}',
        );
      }

      final dynamic decodedResult = jsonDecode(response.body);

      if (decodedResult is! Map) {
        throw Exception(
          'Format response get_tire_running tidak valid',
        );
      }

      final Map<String, dynamic> result =
          Map<String, dynamic>.from(decodedResult);

      log('Result new get tire running diterima');

      /*
     * ==========================================================
     * PARSE DATA TIRE
     * ==========================================================
     */

      final List<dynamic> rawData = result['data'] is List
          ? List<dynamic>.from(result['data'])
          : <dynamic>[];

      final List<UnitTire> listUnitTire = rawData
          .whereType<Map>()
          .map(
            (dynamic unit) => UnitTire.fromJson(
              Map<String, dynamic>.from(unit as Map),
            ),
          )
          .toList();

      /*
     * ==========================================================
     * PARSE RECOMMENDED PRESSURE
     * ==========================================================
     */

      final List<Map<String, dynamic>> recommendedPressure =
          _parseListOfMaps(result['recc_press']);

      /*
     * ==========================================================
     * PARSE TARGET AREA
     *
     * Format API:
     * [
     *   {"Central": "6"},
     *   {"North West": "6"}
     * ]
     *
     * Hasil:
     * {
     *   "Central": 6,
     *   "North West": 6
     * }
     * ==========================================================
     */

      final Map<String, int> targetArea =
          _parseTargetArea(result['target_area']);

      /*
     * ==========================================================
     * PARSE TOTAL ROW
     *
     * Mendukung:
     * "total row": 72
     * "total row": "72"
     * "total row": [72]
     * "total row": ["72"]
     * ==========================================================
     */

      final int countAllTire = _parseTotalRow(result['total row']);

      /*
     * ==========================================================
     * MEMBUAT LIST UNIT UNIK
     * ==========================================================
     */

      final List<UnitTire> uniqueUnits = <UnitTire>[];
      final Set<String> seenUnitNumbers = <String>{};

      /*
     * ==========================================================
     * HITUNG UKURAN BAN
     * ==========================================================
     */

      final Map<String, int> sizeCount = <String, int>{};
      final Set<String> sizes = <String>{};

      for (final UnitTire unit in listUnitTire) {
        final String unitNumber = (unit.unitNumber ?? '').trim();

        if (unitNumber.isNotEmpty && seenUnitNumbers.add(unitNumber)) {
          uniqueUnits.add(unit);
        }

        final String tireSize = (unit.size ?? '').trim();

        if (tireSize.isNotEmpty) {
          sizes.add(tireSize);

          sizeCount[tireSize] = (sizeCount[tireSize] ?? 0) + 1;
        }
      }

      log('Total tire data: ${listUnitTire.length}');
      log('Total unique units: ${uniqueUnits.length}');
      log('Total row API: $countAllTire');
      log('Target area: $targetArea');
      log('Tire sizes: $sizeCount');

      /*
     * ==========================================================
     * SIMPAN CACHE
     * ==========================================================
     */

      /// Seluruh data ban.
      /// Field area, schedule_type, dan schedule_date ikut tersimpan.
      await cacheUnits(listUnitTire, site);

      /// Total seluruh ban.
      await cacheCountAllTire(
        countAllTire,
        site,
      );

      /// Recommended pressure.
      await cacheReccPress(
        recommendedPressure,
      );

      /// Ukuran ban dan jumlah per ukuran.
      await cacheTireSize(
        sizeCount,
        sizes.toList(),
        site,
      );

      /// Target dan daftar area berdasarkan site.
      await cacheTargetArea(
        targetArea,
        site,
      );

      /// Penanda cache bulan dan tahun.
      await saveMonthYear(DateTime.now());

      return uniqueUnits;
    } catch (e, st) {
      log('Error getUnits: $e');
      log('$st');

      rethrow;
    }
  }

  static List<Map<String, dynamic>> _parseListOfMaps(
    dynamic rawValue,
  ) {
    if (rawValue is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawValue
        .whereType<Map>()
        .map(
          (dynamic item) => Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  static int _parseTotalRow(dynamic rawValue) {
    if (rawValue == null) {
      return 0;
    }

    if (rawValue is int) {
      return rawValue;
    }

    if (rawValue is num) {
      return rawValue.toInt();
    }

    if (rawValue is List) {
      if (rawValue.isEmpty) {
        return 0;
      }

      return int.tryParse(
            rawValue.first.toString(),
          ) ??
          0;
    }

    return int.tryParse(
          rawValue.toString(),
        ) ??
        0;
  }

  static Map<String, int> _parseTargetArea(
    dynamic rawTargetArea,
  ) {
    final Map<String, int> result = <String, int>{};

    if (rawTargetArea is Map) {
      rawTargetArea.forEach((dynamic key, dynamic value) {
        final String areaName = key.toString().trim();

        if (areaName.isEmpty) {
          return;
        }

        result[areaName] = int.tryParse(value.toString()) ?? 0;
      });

      return result;
    }

    if (rawTargetArea is! List) {
      return result;
    }

    for (final dynamic item in rawTargetArea) {
      if (item is! Map) {
        continue;
      }

      item.forEach((dynamic key, dynamic value) {
        final String areaName = key.toString().trim();

        if (areaName.isEmpty) {
          return;
        }

        result[areaName] = int.tryParse(value.toString()) ?? 0;
      });
    }

    return result;
  }

  static Future<void> cacheTargetArea(
    Map<String, int> targetArea,
    String idSite,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String cacheKey = 'cached_target_area_$idSite';

      final String updatedAtKey = 'cached_target_area_updated_at_$idSite';

      await prefs.setString(
        cacheKey,
        jsonEncode(targetArea),
      );

      await prefs.setString(
        updatedAtKey,
        DateTime.now().toIso8601String(),
      );

      log(
        'Cache target area berhasil '
        '| site: $idSite '
        '| data: $targetArea',
      );
    } catch (e) {
      throw Exception(
        'Gagal menyimpan cache target area: $e',
      );
    }
  }

  static Future<Map<String, int>> getCachedTargetArea({
    String idSite = '',
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String cacheKey = 'cached_target_area_$idSite';

      final String? cachedData = prefs.getString(cacheKey);

      if (cachedData == null || cachedData.trim().isEmpty) {
        return <String, int>{};
      }

      final dynamic decodedData = jsonDecode(cachedData);

      if (decodedData is! Map) {
        return <String, int>{};
      }

      final Map<String, int> result = <String, int>{};

      decodedData.forEach(
        (dynamic key, dynamic value) {
          result[key.toString()] = int.tryParse(value.toString()) ?? 0;
        },
      );

      log(
        'Cache target area '
        '| site: $idSite '
        '| data: $result',
      );

      return result;
    } catch (e) {
      log('Error mengambil cache target area: $e');
      return <String, int>{};
    }
  }

  static Future<List<String>> getCachedAreaNames({
    String idSite = '',
  }) async {
    final Map<String, int> targetArea = await getCachedTargetArea(
      idSite: idSite,
    );

    final List<String> areas = targetArea.keys.toList();

    areas.sort(
      (String a, String b) => a.toLowerCase().compareTo(
            b.toLowerCase(),
          ),
    );

    return areas;
  }

  static Future<DateTime?> getCachedTargetAreaUpdatedAt({
    String idSite = '',
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String updatedAtKey = 'cached_target_area_updated_at_$idSite';

    final String? value = prefs.getString(updatedAtKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  // mendapatkan daftar unit di salah satu site
//   static Future<List<UnitTire>> getUnits(String site) async {
//     final urll = await selectedUrl('get_tire_running');
//     log('url get tire running : $urll$site');
//     final response = await http.get(Uri.parse('$urll$site'));

//     // try {
//     final body = response.body;
//     final result = jsonDecode(body);

//     log('result new get tire running : $result');

//     List<Map<String, dynamic>> recommendPressure =
//         List<Map<String, dynamic>>.from(result['recc_press']);

//     List<UnitTire> listUnitTire = List<UnitTire>.from(result['data'].map(
//       (unit) => UnitTire.fromJson(unit),
//     ));
//     final totalRow = result['total row'];

//     int countAllTire = 0;

//     if (totalRow is List && totalRow.isNotEmpty) {
//       countAllTire = int.tryParse(totalRow[0].toString()) ?? 0;
//     } else {
//       countAllTire = int.tryParse(totalRow.toString()) ?? 0;
//     }
//     // int countAllTire = result['total row'][0];
//     // log('ban all : ${result['total row']}');

//     List<UnitTire> fixData = [];

//     Set<String> seenUnitNumbers = {}; // Untuk menyimpan unitNumber unik
//     Map<String, int> sizeCount = {};
//     Set<String> sizes = {};

//     for (var unit in listUnitTire) {
//       // Gunakan Set untuk pengecekan unitNumber agar lebih cepat
//       if (seenUnitNumbers.add(unit.unitNumber ?? '')) {
//         fixData.add(unit); // Tambahkan hanya jika unitNumber belum ada
//       }

//       String size = unit.size ?? '';
//       if (size.isNotEmpty) {
//         sizes.add(size); // Simpan ukuran unik

//         // Hitung sizeCount untuk SEMUA data, tanpa tergantung fixData
//         sizeCount[size] = (sizeCount[size] ?? 0) + 1;
//       }
//     }
// // Buat struktur data baru
//     Map<String, dynamic> sizeResult = {
//       "sizes": sizes.toList(), // Konversi Set ke List
//       "sizeCount": sizeCount
//     };

//     // save unit
//     await cacheUnits(listUnitTire, site);
//     // save all tire count
//     await cacheCountAllTire(countAllTire, site);
//     // save recommendation pressure
//     await cacheReccPress(recommendPressure);
//     // save size tire with quantity
//     await cacheTireSize(sizeCount, sizes.toList(), site);

//     // for check data unit monthly
//     await saveMonthYear(DateTime.now());
//     return fixData;
//     // } catch (e) {
//     //   throw Exception(e.toString());
//     // }
//   }

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
    final urll = await selectedUrl('get_tire_running');
    final response = await http.get(Uri.parse('$urll$site'));

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
    final urll = await selectedUrl('get_tire_running');
    final response = await http.get(Uri.parse('$urll$site'));

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
        final avgLifetime = result['Avg_lifetime'];
        final total = result['Total'];

        tireSpecCount =
            '${(avgLifetime is num ? avgLifetime.round() : 0)}|${total ?? 0}';
      } else {
        tireSpecCount = result['Total']?.toString() ?? '0';
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
    final urll = await selectedUrl('get_site') ?? '';

    log('url get all site : $urll');

    final response = await http.get(Uri.parse(urll));

    try {
      final body = response.body;
      final result = jsonDecode(body);

      log('response all site : $result');

      List<Site> listSite = List<Site>.from(result['data'].map(
        (site) => Site.fromJson(site),
      ));

      log('response list site : $result');

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

  static Future<List<SpmJam7>> getJam7SPM(String idSite) async {
    final response = await http.get(Uri.parse(
        'https://cts-chitraparatama.co.id/ChitraTireMngr/product/api_get.php?function=get_tpms_jam7&idsite=$idSite'));

    try {
      final body = response.body;

      final result = jsonDecode(body);

      List<SpmJam7> listSpm = List<SpmJam7>.from(result['data'].map((pressure) {
        return SpmJam7.fromJson(pressure);
      }));

      log('spm kim : $listSpm');

      return listSpm;
    } catch (e) {
      log('error spm : $e');

      throw Exception(e.toString());
    }
  }
}
