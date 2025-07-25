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

        final responseQuery = await firestore
            .collection('url_spm')
            .where('id_company', isEqualTo: idCompany)
            .get();

        if (responseQuery.docs.isEmpty) {
          emit(SpmLoadedState(listSpm: [], isShowMore: []));
          return;
        }

        final urlSpm = responseQuery.docs.first.data()['url'];

        // --- MULAI PERUBAHAN LOGIKA UTAMA ---

        // 1. Panggil API ban (getTireCondition) dan API TPMS (getApiSpm) secara bersamaan
        final results = await Future.wait([
          ApiService.getTireCondition(event.idSite),
          ApiService.getApiSpm(event.idSite, urlSpm),
        ]);

        final List<UnitTire> dataUnits = results[0] as List<UnitTire>;
        final List<Spm> apiListSpm = results[1] as List<Spm>;

        // 2. Buat "kamus" atau Map dengan KUNCI KOMPOSIT (contoh: "CO4202-1")
        final ratingMap = <String, String>{};
        for (final unit in dataUnits) {
          // Pastikan unitNumber dan posisi tidak null sebelum membuat kunci
          if (unit.unitNumber!.isNotEmpty && unit.posisi!.isNotEmpty) {
            final key = '${unit.unitNumber}-${unit.posisi}';
            ratingMap[key] = unit.rating ?? '';
          }
        }

        // 3. Gabungkan data: Tambahkan 'rating' ke setiap item SPM sesuai posisinya
        final List<Spm> enrichedList = apiListSpm.map((spm) {
          final deviceName = spm.devicename;

          // Buat objek Spm baru dengan tambahan data rating untuk setiap posisi
          return spm.copyWith(
            rating1: ratingMap['$deviceName-1'],
            rating2: ratingMap['$deviceName-2'],
            rating3: ratingMap['$deviceName-3'],
            rating4: ratingMap['$deviceName-4'],
            rating5: ratingMap['$deviceName-5'],
            rating6: ratingMap['$deviceName-6'],
          );
        }).toList();

        // Filter akhir jika diperlukan (logika ini sudah ada sebelumnya)
        List<Spm> list =
            enrichedList.where((spm) => spm.idSite == event.idSite).toList();

        log('Unit SPM with 6 ratings: $list');

        List<bool> isShowMore = List.generate(list.length, (index) => false);
        emit(SpmLoadedState(listSpm: list, isShowMore: isShowMore));
      } catch (e, stackTrace) {
        // Tambahkan stackTrace untuk debugging lebih detail
        log('Error in SpmBloc: $e', stackTrace: stackTrace);
      }
    });
  }
}
