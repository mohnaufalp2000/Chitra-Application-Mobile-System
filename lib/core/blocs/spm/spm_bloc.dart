// import 'dart:developer';

// import 'package:bloc/bloc.dart';
// import 'package:camos/core/services/api_service.dart';
// import 'package:camos/core/services/model/site.dart';
// import 'package:camos/core/services/model/unit_tire.dart';
// import 'package:camos/core/utils/data/spm.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:equatable/equatable.dart';

// part 'spm_event.dart';
// part 'spm_state.dart';

// class SpmBloc extends Bloc<SpmEvent, SpmState> {
//   SpmBloc() : super(SpmInitial()) {
//     FirebaseFirestore firestore = FirebaseFirestore.instance;
//     on<GetListSpmEvent>((event, emit) async {
//       emit(SpmLoadingState());
//       List<Site> allSites = await ApiService.getCachedAllSites();

//       if (allSites.isEmpty || allSites == null) {
//         allSites = await ApiService.getAllSite();
//       }

//       List<UnitTire> dataUnits =
//           await ApiService.getTireCondition(event.idSite);

//       final idCompany = allSites
//           .firstWhere((site) => site.idSite == event.idSite,
//               orElse: () => Site(idSite: '', idCompany: ''))
//           .idCompany;

//       if (idCompany!.isEmpty) {
//         emit(SpmLoadedState(listSpm: [], isShowMore: []));
//         return;
//       }

//       final responseQuery = await firestore
//           .collection('url_spm')
//           .where('id_company', isEqualTo: idCompany)
//           .get();

//       final response = responseQuery.docs.first.data()['url'];

//       final apiListSpm = await ApiService.getApiSpm(event.idSite, response);

//       // final apiListSpm = await ApiService.getApiSpm(event.idSite,
//       //     'https://cts-chitraparatama.co.id/ChitraTireMngr/product/api_get.php?function=get_tpms&idsite=');
//       List<Spm> actualList = apiListSpm;

//       List<Spm> list =
//           actualList.where((spm) => spm.idSite == event.idSite).toList();

//       List<bool> isShowMore = List.generate(list.length, (index) => false);
//       emit(SpmLoadedState(listSpm: list, isShowMore: isShowMore));
//     });
//   }
// }

import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:camos/core/utils/data/spm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

part 'spm_event.dart';
part 'spm_state.dart';

class SpmBloc extends Bloc<SpmEvent, SpmState> {
  SpmBloc() : super(SpmInitial()) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    on<GetListSpmEvent>((event, emit) async {
      emit(SpmLoadingState());

      try {
        // --- Bagian Awal Tetap Sama ---
        List<Site> allSites = await ApiService.getCachedAllSites();
        if (allSites.isEmpty) {
          allSites = await ApiService.getAllSite();
        }

        final idCompany = allSites
            .firstWhere((site) => site.idSite == event.idSite,
                orElse: () => Site(idSite: '', idCompany: ''))
            .idCompany;

        if (idCompany!.isEmpty) {
          emit(SpmLoadedState(listSpm: [], isShowMore: []));
          return;
        }

        final isCts = allSites
            .firstWhere((site) => site.idSite == event.idSite,
                orElse: () => Site(idSite: '', idCompany: ''))
            .cts;

        final responseQuery = await firestore
            .collection('url_spm')
            .where('id_company', isEqualTo: idCompany)
            .get();

        if (responseQuery.docs.isEmpty) {
          emit(SpmLoadedState(listSpm: [], isShowMore: []));
          return;
        }

        final urlSpm = responseQuery.docs.first.data()['url'];

        // --- LOGIKA UTAMA DENGAN PERCABANGAN ---

        List<Spm> enrichedList;

        if (isCts == '0') {
          // JALUR 1: Jika isCts adalah '0', tidak perlu ambil data rating
          log('Menjalankan proses tanpa penggabungan rating (isCts == "0")');

          // Hanya panggil API TPMS
          enrichedList = await ApiService.getApiSpm(event.idSite, urlSpm);
        } else {
          // JALUR 2: Jika isCts bukan '0', jalankan logika penggabungan data
          log('Menjalankan proses DENGAN penggabungan rating (isCts != "1")');

          // Panggil kedua API secara bersamaan
          final results = await Future.wait([
            ApiService.getTireCondition(event.idSite),
            ApiService.getApiSpm(event.idSite, urlSpm),
          ]);

          final List<UnitTire> dataUnits = results[0] as List<UnitTire>;
          final List<Spm> apiListSpm = results[1] as List<Spm>;

          /// melihat data rating dari cts
          List<UnitTire> unitsss = dataUnits
              .where((element) => element.unitNumber == 'CO4202')
              .toList();
          log('unit spm rating bloc 1 : $unitsss'); // aman
          // [UnitTire(unitNumber: CO4202, posisi: 1, model: CAT 777, status: Active, hm: 17021, brand: Goodyear, size: 27.00R49, pattern: RT-4A+, otd: 75, rtd: 63, lifetime: 3188, hmOnJob: 13833, lifeOnJob: 0, date: 2024-11-02 12:00:00, rating: A, site: CK-BMB Sitarum, sn: 0923JCL78, kunciUnit: 42852428, kunciTire: 2051522051, idInventory: 2051, idUnit: 428), UnitTire(unitNumber: CO4202, posisi: 2, model: CAT 777, status: Active, hm: 17021, brand: Goodyear, size: 27.00R49, pattern: RT-4A+, otd: 75, rtd: 66, lifetime: 3188, hmOnJob: 13833, lifeOnJob: 0, date: 2024-11-02 13:30:00, rating: A, site: CK-BMB Sitarum, sn: 1123JCM11, kunciUnit: 42852428, kunciTire: 2052522052, idInventory: 2052, idUnit: 428), UnitTire(unitNumber: CO4202, posisi: 3, model: CAT 777, status: Active, hm: 17021, brand: Michelin, size: 27.00R49, pattern: XD-Grip, otd: 80, rtd: 50, lifetime: 9842, hmOnJob: 14375, lifeOnJob: 7196, date: 2024-12-29 13:30:00, rating: B, site: CK-BMB Sitarum, sn: ICO1059S3A, kunciUnit: 42852428, kunciTire: 1243521243, idInventory: 1243, idUnit: 428), UnitTire(unitNumber: CO4202, posisi: 4, model: CAT 777, status: Active, hm: 17021, brand: Michelin, size: 27.00R49, pattern: XD-Grip, otd: 80, rtd: 44, lifetime: 8726, hmOnJob: 14375, lifeOnJob: 6080, date: 2024-12-29 13:00:00, rating: X, site: CK-BMB Sitarum, sn: FPY0750M0B, kunciUnit: 42852428, kunciTire: 1331521331, idInventory: 1331, idUnit: 428), UnitTire(unitNumber: CO4202, posisi: 5, model: CAT 777, status: Active, hm: 17021, brand: Bridgestone, size: 27.00R49, pattern: VMTP(X), otd: 76, rtd: 38, lifetime: 8388, hmOnJob: 17021, lifeOnJob: 8388, date: 2025-07-22 10:00:00, rating: X, site: CK-BMB Sitarum, sn: A2U000823, kunciUnit: 42852428, kunciTire: 1499521499, idInventory: 1499, idUnit: 428), UnitTire(unitNumber: CO4202, posisi: 6, model: CAT 777, status: Active, hm: 17021, brand: Bridgestone, size: 27.00R49, pattern: VMTP, otd: 76, rtd: 37, lifetime: 8388, hmOnJob: 17021, lifeOnJob: 8388, date: 2025-07-22 10:30:00, rating: C, site: CK-BMB Sitarum, sn: B2M000957, kunciUnit: 42852428, kunciTire: 1500521500, idInventory: 1500, idUnit: 428)

          /// melihat data rating dari cts

          // Buat "kamus" rating dengan kunci komposit
          final ratingMap = <String, String>{};
          for (final unit in dataUnits) {
            if (unit.unitNumber!.isNotEmpty && unit.posisi!.isNotEmpty) {
              final key = '${unit.unitNumber}-${unit.posisi}';
              ratingMap[key] = unit.rating ?? '';
            }
          }

          log('unit spm rating bloc 2 : $ratingMap'); // aman
          // CO4202-1: A
          // CO4202-2: A
          // CO4202-3: B
          // CO4202-4: X
          // CO4202-5: X
          // CO4202-6: C

          // Gabungkan data
          enrichedList = apiListSpm.map((spm) {
            final deviceName = spm.devicename;
            return spm.copyWith(
              rating1: ratingMap['$deviceName-1'],
              rating2: ratingMap['$deviceName-2'],
              rating3: ratingMap['$deviceName-3'],
              rating4: ratingMap['$deviceName-4'],
              rating5: ratingMap['$deviceName-5'],
              rating6: ratingMap['$deviceName-6'],
            );
          }).toList();

          log('unit spm rating bloc 3 : $enrichedList');
          // Spm(5464854, 2025-08-22 16:13:24, CO4202, 0, 0, 0, 128, 124, 122, 112, 120, 118, 46, 40, 45, 43, 41, 38, 1, 1, 1, 1, 1, 1, 724.3747177124023, 6, 52, A, A, B, X, X, C),
        }

        // --- Bagian Akhir Tetap Sama ---

        // Filter akhir berdasarkan idSite
        List<Spm> list =
            enrichedList.where((spm) => spm.idSite == event.idSite).toList();

        List<bool> isShowMore = List.generate(list.length, (index) => false);
        emit(SpmLoadedState(listSpm: list, isShowMore: isShowMore));
      } catch (e, stackTrace) {
        // Tambahkan stackTrace untuk debugging lebih detail
        log('Error in SpmBloc: $e', stackTrace: stackTrace);
      }
    });
  }
}
