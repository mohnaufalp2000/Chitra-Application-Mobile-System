import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/services/model/tire_spec.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'detail_tire_invent_event.dart';
part 'detail_tire_invent_state.dart';

class DetailTireInventBloc
    extends Bloc<DetailTireInventEvent, DetailTireInventState> {
  DetailTireInventBloc() : super(DetailTireInventInitial()) {
    on<GetDetailTireInventEvent>((event, emit) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (await getIdSitePreferences() == '1' ||
            await getIdSitePreferences() == '2') {
          emit(DetailTireInventErrorState());
        } else {
          log('gaada internet blas 1');
          final prefs = await SharedPreferences.getInstance();
          log('gaada internet blas 2');
          final cachedData = prefs.getString('detail_tire_spec');
          log('apa lho 1: ${prefs.containsKey('detail_tire_spec')}');
          log('apa lho 2: $cachedData');

          final decodedData =
              jsonDecode(cachedData ?? '') as Map<String, dynamic>;
          switch (event.status) {
            case 'New':
              log('statusku : ${decodedData['new']}');
              break;
            case 'Scrap':
              log('statusku : ${decodedData['scrap']}');
              break;
            case 'Repair':
              log('statusku : ${decodedData['repair']}');
              break;
            case 'Spare':
              log('statusku : ${decodedData['spare']}');
              break;
          }
          log('status terbaru : ${event.status}');
          // emit(DetailTireInventLoadedState(
          //     mapSizeInvent: (event.status == 'Scrap')
          //         ? decodedData['scrap']
          //         : (event.status == 'Repair')
          //             ? decodedData['repair']
          //             : (event.status == 'New')
          //                 ? decodedData['new']
          //                 : decodedData['spare']));
          emit(DetailTireInventLoadedState(mapSizeInvent: {
            'New': decodedData['new'],
            'Repair': decodedData['repair'],
            'Spare': decodedData['spare'],
            'Scrap': decodedData['scrap'],
          }));
        }
      } else {
        if (await getIdSitePreferences() == '1' ||
            await getIdSitePreferences() == '2') {
          try {
            emit(DetailTireInventLoadingState());

            List<TireSpec> listInvent = [];
            int total = int.parse(event.total);
            String idSite = event.idSite;

            log('eventku ${event.idSite} | ${event.status} | ${event.total}');

            if (idSite == '1') {
              Site site = await ApiService.getSite(idSite);
              idSite = site.idSite ?? '';
            }

            if (idSite == '2') {
              Site site = await ApiService.getSite(idSite);
              idSite = site.idSite ?? '';
            }

            // Gathering data from api
            if (total < 10) {
              // jika tire berjumlah 0
              if (total == 0) {
                emit(DetailTireInventLoadedState(
                  mapSizeInvent: {},
                ));
                return;
              } else {
                listInvent.addAll(await ApiService.getDetailInventory(
                    event.status, '0', idSite));
              }
            } else {
              // jika tire lebih dari 10
              for (var i = 0; i < total; i += 10) {
                listInvent.addAll(await ApiService.getDetailInventory(
                    event.status, i.toString(), idSite));
              }
            }

            // SCRAP
            Map<String, Map<String, Map<String, List<TireSpec>>>> groupedData =
                {};
            Map<String, Map<String, Map<String, Map<String, int>>>>
                resultScrap = {};

            // SPARE
            Map<String, dynamic> resultSpare = {};

            // REPAIR
            Map<String, dynamic> resultRepair = {};

            // NEW
            Map<String, dynamic> resultNew = {};

            switch (event.status) {
              case 'Scrap':
                for (var invent in listInvent) {
                  groupedData.putIfAbsent(invent.size ?? '', () => {});
                  groupedData[invent.size]!
                      .putIfAbsent(invent.brand ?? '', () => {});
                  groupedData[invent.size]![invent.brand]!
                      .putIfAbsent(invent.pattern ?? '', () => []);
                  groupedData[invent.size]![invent.brand]![invent.pattern]!
                      .add(invent);
                }

                groupedData.forEach((size, brands) {
                  resultScrap[size] = {};
                  brands.forEach((brand, patterns) {
                    resultScrap[size]![brand] = {};
                    patterns.forEach((pattern, tires) {
                      int quantity = tires.length;
                      int totalLifetime = tires.fold(0,
                          (acc, tire) => acc + int.parse(tire.lifetime ?? '0'));
                      int averageLifetime =
                          quantity > 0 ? totalLifetime ~/ quantity : 0;

                      resultScrap[size]![brand]![pattern] = {
                        'Quantity': quantity,
                        'Lifetime Avg': averageLifetime,
                      };
                    });
                  });
                });
                break;
              case 'Spare':
                Map<String, Map<String, dynamic>> sizeCount = {};

                for (var tire in listInvent) {
                  final size = tire.size ?? "Unknown";
                  final brand = tire.brand ?? "Unknown";
                  final pattern = tire.pattern ?? "Unknown";
                  final sn = tire.sn ?? "Unknown";
                  final lifetime = tire.lifetime ?? "Unknown";

                  final quantity =
                      (sizeCount[size]?.containsKey('quantity') ?? false)
                          ? sizeCount[size]!['quantity']! + 1
                          : 1;

                  if (!sizeCount.containsKey(size)) {
                    sizeCount[size] = {'quantity': quantity, 'listTire': []};
                  }

                  sizeCount[size]!['listTire'].add({
                    'brand': brand,
                    'pattern': pattern,
                    'sn': sn,
                    'lifetime': lifetime,
                  });

                  sizeCount[size]!['quantity'] = quantity;
                }

                log('data spare : $sizeCount');
                resultSpare = sizeCount;
                break;
              case 'New':
                Map<String, Map<String, dynamic>> sizeCount = {};

                for (var tire in listInvent) {
                  final size = tire.size ?? "Unknown";
                  final brand = tire.brand ?? "Unknown";
                  final pattern = tire.pattern ?? "Unknown";
                  final sn = tire.sn ?? "Unknown";
                  final lifetime = tire.lifetime ?? "Unknown";

                  final quantity =
                      (sizeCount[size]?.containsKey('quantity') ?? false)
                          ? sizeCount[size]!['quantity']! + 1
                          : 1;

                  if (!sizeCount.containsKey(size)) {
                    sizeCount[size] = {'quantity': quantity, 'listTire': []};
                  }

                  sizeCount[size]!['listTire'].add({
                    'brand': brand,
                    'pattern': pattern,
                    'sn': sn,
                    'lifetime': lifetime,
                  });

                  sizeCount[size]!['quantity'] = quantity;
                }

                log('data spare : $sizeCount');
                resultNew = sizeCount;
                break;
              case 'Repair':
                List<String?> uniqueSizes =
                    listInvent.map((tire) => tire.size).toSet().toList();

                Map<String, dynamic> repairMap = {};

                uniqueSizes.forEach((size) {
                  final listTire =
                      listInvent.where((tire) => tire.size == size).toList();

                  final listSn = [];
                  listTire.forEach((e) {
                    listSn.add({
                      'brand': e.brand,
                      'pattern': e.pattern,
                      'sn': e.sn,
                      'lifetime': e.lifetime,
                    });
                  });
                  repairMap[size ?? ''] = listSn;
                });

                resultRepair = repairMap;
                break;
            }

            // emit(DetailTireInventLoadedState(
            //   mapSizeInvent: (event.status == 'Scrap')
            //       ? resultScrap
            //       : (event.status == 'Repair')
            //           ? resultRepair
            //           : (event.status == 'New')
            //               ? resultNew
            //               : resultSpare,
            // ));
            emit(DetailTireInventLoadedState(mapSizeInvent: {
              'New': resultNew,
              'Repair': resultRepair,
              'Spare': resultSpare,
              'Scrap': resultScrap,
            }));
          } catch (e) {
            if (await getIdSitePreferences() == '1' ||
                await getIdSitePreferences() == '2') {
              emit(DetailTireInventErrorState());
            } else {
              final prefs = await SharedPreferences.getInstance();
              final cachedData = prefs.getString('detail_tire_spec');
              final decodedData =
                  jsonDecode(cachedData ?? '') as Map<String, dynamic>;
              log('statusku : ${event.status}');
              log('lapar : ${decodedData['new']}');
              // emit(DetailTireInventLoadedState(
              //     mapSizeInvent: (event.status == 'Scrap')
              //         ? decodedData['scrap']
              //         : (event.status == 'Repair')
              //             ? decodedData['repair']
              //             : (event.status == 'New')
              //                 ? decodedData['new']
              //                 : decodedData['spare']));
              emit(DetailTireInventLoadedState(mapSizeInvent: {
                'New': decodedData['new'],
                'Repair': decodedData['repair'],
                'Spare': decodedData['spare'],
                'Scrap': decodedData['scrap'],
              }));
            }
          }
        } else {
          final prefs = await SharedPreferences.getInstance();
          final cachedData = prefs.getString('detail_tire_spec');
          log('apa nich : $cachedData');
          final decodedData =
              jsonDecode(cachedData ?? '') as Map<String, dynamic>;
          switch (event.status) {
            case 'New':
              log('statusku : ${decodedData['new']}');
              break;
            case 'Scrap':
              log('statusku : ${decodedData['scrap']}');
              break;
            case 'Repair':
              log('statusku : ${decodedData['repair']}');
              break;
            case 'Spare':
              log('statusku : ${decodedData['spare']}');
              break;
          }
          log('status terbaru : ${event.status}');
          // emit(DetailTireInventLoadedState(
          //     mapSizeInvent: (event.status == 'Scrap')
          //         ? decodedData['scrap']
          //         : (event.status == 'Repair')
          //             ? decodedData['repair']
          //             : (event.status == 'New')
          //                 ? decodedData['new']
          //                 : decodedData['spare']));
          emit(DetailTireInventLoadedState(mapSizeInvent: {
            'New': decodedData['new'],
            'Repair': decodedData['repair'],
            'Spare': decodedData['spare'],
            'Scrap': decodedData['scrap'],
          }));
        }
      }
    });
  }
}
