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

        log('all sites spm : $allSites');

        final idCompany = allSites
            .firstWhere((site) => site.idSite == event.idSite,
                orElse: () => Site(idSite: '', idCompany: ''))
            .idCompany;

        print('id company : $idCompany');

        if (idCompany!.isEmpty) {
          emit(SpmLoadedState(listSpm: [], isShowMore: []));
          return;
        }
        // khusus ck tia dikecualikan
        // if (idCompany!.isEmpty && event.idSite != '15') {
        //   emit(SpmLoadedState(listSpm: [], isShowMore: []));
        //   return;
        // }

        // final isCts = '1';

        final isCts = allSites
            .firstWhere((site) => site.idSite == event.idSite,
                orElse: () => Site(idSite: '', idCompany: ''))
            .cts;

        // final responseQuery = await firestore
        //     .collection('url_spm')
        //     .where('id_company', isEqualTo: '2')
        //     .get();
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
          log('spm new : $enrichedList');
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
        log('message spm new : $list');
        emit(SpmLoadedState(listSpm: list, isShowMore: isShowMore));
      } catch (e, stackTrace) {
        // Tambahkan stackTrace untuk debugging lebih detail
        log('Error in SpmBloc: $e', stackTrace: stackTrace);
      }
    });
  }
}
