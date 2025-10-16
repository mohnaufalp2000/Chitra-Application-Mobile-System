import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import '../../services/api_service.dart';
import '../../services/model/site.dart';
import '../../services/shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import '../../services/model/unit_tire.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tire_condition_event.dart';
part 'tire_condition_state.dart';

class TireConditionBloc extends Bloc<TireConditionEvent, TireConditionState> {
  TireConditionBloc() : super(TireConditionInitial()) {
    on<GetTireConditionEvent>((event, emit) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      final idSite = await getIdSitePreferences();

      if (connectivityResult == ConnectivityResult.none) {
        if (idSite == '1' || idSite == '2') {
          emit(TireConditionErrorState(message: 'Please Try Again!'));
          return;
        } else {
          final prefs = await SharedPreferences.getInstance();
          final cachedData = prefs.getString('tire_condition');

          // jika belum pernah buka dan tidak ada koneksi
          if (cachedData == null) {
            emit(TireConditionErrorState(message: 'Please Try Again!'));
            return;
          }

          final decodedData =
              jsonDecode(cachedData ?? '') as Map<String, dynamic>;
          emit(TireConditionLoadedState(
              listSize: (decodedData['resultList'] as List<dynamic>)
                  .cast<Map<String, dynamic>>(),
              mapRating: decodedData['allRatingResult']));
        }
      }

      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.ethernet ||
          connectivityResult == ConnectivityResult.wifi) {
        try {
          emit(TireConditionLoadingState());
          Site site = await ApiService.getSite(event.idSite);
          log('site running condition : $site');

          final listSize = await ApiService.getTireCondition(site.idSite ?? '');

          List<UnitTire> fixData = [];
          List<String> allRating = [];

          // mengambil daftar size tire yang ada di site tersebut
          listSize.forEach((unit) {
            // mengambil data rating dari semua size
            allRating.add(unit.rating ?? '');

            if (fixData.any((item) => item.size == unit.size)) {
              return;
            }
            fixData.add(unit);
          });

          // mengelompokkan data size dengan ratingnya
          List<Map<String, dynamic>> ratings = [];
          for (int i = 0; i < fixData.length; i++) {
            listSize.forEach((tire) {
              if (tire.size == fixData[i].size) {
                ratings.add({
                  tire.size ?? '': tire.rating,
                });
              }
            });
          }

          List<Map<String, dynamic>> resultList = [];

          for (var item in ratings) {
            String key = item.keys.first;
            String value = item.values.first;

            bool found = false;
            for (var resultItem in resultList) {
              if (resultItem.containsKey(key)) {
                resultItem[key].add(value);
                found = true;
                break;
              }
            }

            if (!found) {
              resultList.add({
                key: [value]
              });
            }
          }

          int ratingCountA = 0;
          int ratingCountB = 0;
          int ratingCountC = 0;
          int ratingCountX = 0;

          // mendapatkan jumlah masing-masing rating
          allRating.forEach((rating) {
            switch (rating) {
              case "A":
                ratingCountA++;
                break;
              case "B":
                ratingCountB++;
                break;
              case "C":
                ratingCountC++;
                break;
              case "X":
                ratingCountX++;
                break;
            }
          });

          final allRatingResult = {
            "A": ratingCountA,
            "B": ratingCountB,
            "C": ratingCountC,
            "X": ratingCountX,
          };

          // save to local
          final prefs = await SharedPreferences.getInstance();
          final jsonData = jsonEncode(
              {'resultList': resultList, 'allRatingResult': allRatingResult});
          await prefs.setString('tire_condition', jsonData);

          emit(TireConditionLoadedState(
              listSize: resultList, mapRating: allRatingResult));
        } catch (e) {}
      }
    });
  }
}
