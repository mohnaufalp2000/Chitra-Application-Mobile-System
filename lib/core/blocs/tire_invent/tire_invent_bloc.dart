import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/tire_spec.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:connection_network_type/connection_network_type.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tire_invent_event.dart';
part 'tire_invent_state.dart';

class TireInventBloc extends Bloc<TireInventEvent, TireInventState> {
  TireInventBloc() : super(TireInventInitial()) {
    on<GetTireInventEvent>((event, emit) async {
      final connectivityResult = await Connectivity().checkConnectivity();

      // tidak ada koneksi
      if (connectivityResult == ConnectivityResult.none) {
        log('tidak ada koneksi');
        if (await getIdSitePreferences() == '1' ||
            await getIdSitePreferences() == '2') {
          log('no koneksi satu');
          emit(TireInventErrorState(message: 'Please Try Again!'));
          return;
        } else {
          log('no koneksi dua');
          final prefs = await SharedPreferences.getInstance();
          final cachedData = prefs.getString('tire_spec');
          // jika belum pernah buka dan tidak ada koneksi
          if (cachedData == null) {
            emit(TireInventErrorState(message: 'Please Try Again!'));
            return;
          }
          final decodedData =
              jsonDecode(cachedData ?? '') as Map<String, dynamic>;
          emit(TireInventLoadedState(
              tireBlocData: (decodedData['count'] as List<dynamic>)
                  .cast<Map<String, dynamic>>(),
              site: {
                'idSite': decodedData['idSite'] as String,
                'siteName': decodedData['siteName'] as String
              }));
        }
      }
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.ethernet ||
          connectivityResult == ConnectivityResult.wifi) {
        log('ada koneksi');
        if (Platform.isAndroid) {
          await Permission.phone.request();
        }
        final checkNetworkType =
            await ConnectionNetworkType().currentNetworkStatus();

        if (checkNetworkType == NetworkStatus.otherMobile) {
          final prefs = await SharedPreferences.getInstance();
          final cachedData = prefs.getString('tire_spec');
          // jika belum pernah buka dan tidak ada koneksi
          if (cachedData == null) {
            emit(TireInventErrorState(message: 'Please Try Again!'));
            return;
          }
          log('ada koneksi edge');
          final decodedData =
              jsonDecode(cachedData ?? '') as Map<String, dynamic>;
          emit(TireInventLoadedState(
              tireBlocData: (decodedData['count'] as List<dynamic>)
                  .cast<Map<String, dynamic>>(),
              site: {
                'idSite': decodedData['idSite'] as String,
                'siteName': decodedData['siteName'] as String
              }));
          return;
        }

        emit(TireInventLoadingState(percentage: 0));
        final prefs = await SharedPreferences.getInstance();

        // sudah buka aplikasi
        log('pertama kali buka aplikasi');
        try {
          log('id site bloc : ${event.idSite}');
          emit(TireInventLoadingState(percentage: 0));
          final site = await ApiService.getSite(event.idSite);

          // mendapatkan total ban dari setiap status
          final total0 = await ApiService.getTireSpecCount(
              site.idSite ?? '', event.status[0]);
          final total1 = await ApiService.getTireSpecCount(
              site.idSite ?? '', event.status[1]);
          final total2 = await ApiService.getTireSpecCount(
              site.idSite ?? '', event.status[2]);
          final total3 = await ApiService.getTireSpecCount(
              site.idSite ?? '', event.status[3]);

          // mengelompokkan status dengan jumlah bannya
          final count = [
            {
              'status': event.status[0],
              'total': total0,
            },
            {
              'status': event.status[1],
              'total': total1,
            },
            {
              'status': event.status[2],
              'total': total2,
            },
            {
              'status': event.status[3],
              'total': total3,
            },
          ];

          log('berjalan 1');

          // selain user office yaitu manpower di site, simpan data di lokal
          if (await getIdSitePreferences() != '1' &&
              await getIdSitePreferences() != '2') {
            // menyimpan data count ke penyimpanan lokal
            final jsonData = jsonEncode(
                {'count': count, 'idSite': site.idSite, 'siteName': site.site});
            await prefs.setString('tire_spec', jsonData);

            log('berjalan 2');

            // menyimpan data detail tire inventory ke penyimpanan local
            // cek dulu apakah sudah ada data detail tire invetory di local?
            // jika tidak ada, eksekusi pengambilan data dari api
            List<TireSpec> listNewInvent = [];
            List<TireSpec> listRepairInvent = [];
            List<TireSpec> listSpareInvent = [];
            List<TireSpec> listScrapInvent = [];

            int parseTotal0 = int.parse(total0);
            int parseTotal1 = int.parse(total1);
            int parseTotal2 = int.parse(total2);
            // karena datanya (124 Pcs| 1150 Avg Lifetime), maka datanya di split
            int parseTotal3 = int.parse(total3.split('|')[1]);

            log('berjalan 3');

            String idSite = event.idSite;

            // apakah user office?
            // jika ya
            if (idSite == '1') {
              idSite = site.idSite ?? '';
            }

            // apakah user all ck?
            // jika ya
            if (idSite == '2') {
              idSite = site.idSite ?? '';
            }

            // NEW
            // Gathering data from api
            if (parseTotal0 < 10) {
              // jika tire berjumlah 0
              if (parseTotal0 == 0) {
                listNewInvent = [];
              } else {
                listNewInvent.addAll(await ApiService.getDetailInventory(
                    event.status[0], '0', idSite));
              }
            } else {
              // jika tire lebih dari 10
              for (var i = 0; i < parseTotal0; i += 10) {
                listNewInvent.addAll(await ApiService.getDetailInventory(
                    event.status[0], i.toString(), idSite));
              }
            }

            log('berjalan 4');

            // REPAIR
            // Gathering data from api
            if (parseTotal1 < 10) {
              // jika tire berjumlah 0
              if (parseTotal1 == 0) {
                listRepairInvent = [];
              } else {
                listRepairInvent.addAll(await ApiService.getDetailInventory(
                    event.status[1], '0', idSite));
              }
            } else {
              // jika tire lebih dari 10
              for (var i = 0; i < parseTotal1; i += 10) {
                listRepairInvent.addAll(await ApiService.getDetailInventory(
                    event.status[1], i.toString(), idSite));
              }
            }

            log('berjalan 5');

            // SPARE
            // Gathering data from api
            if (parseTotal2 < 10) {
              // jika tire berjumlah 0
              if (parseTotal2 == 0) {
                listSpareInvent = [];
              } else {
                listSpareInvent.addAll(await ApiService.getDetailInventory(
                    event.status[2], '0', idSite));
              }
            } else {
              // jika tire lebih dari 10
              for (var i = 0; i < parseTotal2; i += 10) {
                listSpareInvent.addAll(await ApiService.getDetailInventory(
                    event.status[2], i.toString(), idSite));
              }
            }

            log('berjalan 6');

            // SCRAP
            // Gathering data from api
            if (parseTotal3 < 10) {
              // jika tire berjumlah 0
              if (parseTotal3 == 0) {
                listScrapInvent = [];
              } else {
                listScrapInvent.addAll(await ApiService.getDetailInventory(
                    event.status[3], '0', idSite));
              }
            } else {
              // jika tire lebih dari 10
              for (var i = 0; i < parseTotal3; i += 10) {
                listScrapInvent.addAll(await ApiService.getDetailInventory(
                    event.status[3], i.toString(), idSite));
              }
            }

            log('berjalan 7');

            // SCRAP
            Map<String, Map<String, Map<String, List<TireSpec>>>> groupedData =
                {};
            Map<String, Map<String, Map<String, Map<String, int>>>>
                resultScrap = {};

            for (var invent in listScrapInvent) {
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
                  int totalLifetime = tires.fold(
                      0, (acc, tire) => acc + int.parse(tire.lifetime ?? '0'));
                  int averageLifetime =
                      quantity > 0 ? totalLifetime ~/ quantity : 0;

                  resultScrap[size]![brand]![pattern] = {
                    'Quantity': quantity,
                    'Lifetime Avg': averageLifetime,
                  };
                });
              });
            });

            // SPARE
            Map<String, dynamic> resultSpare = {};

            Map<String, Map<String, dynamic>> sizeCount = {};

            for (var tire in listSpareInvent) {
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

            // REPAIR
            Map<String, dynamic> resultRepair = {};

            List<String?> uniqueSizes =
                listRepairInvent.map((tire) => tire.size).toSet().toList();

            Map<String, dynamic> repairMap = {};

            uniqueSizes.forEach((size) {
              final listTire =
                  listRepairInvent.where((tire) => tire.size == size).toList();

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
              log('reapirMap : $repairMap');
            });

            resultRepair = repairMap;

            // NEW
            Map<String, dynamic> resultNew = {};
            Map<String, Map<String, dynamic>> sizeCountNew = {};

            for (var tire in listNewInvent) {
              final size = tire.size ?? "Unknown";
              final brand = tire.brand ?? "Unknown";
              final pattern = tire.pattern ?? "Unknown";
              final sn = tire.sn ?? "Unknown";
              final lifetime = tire.lifetime ?? "Unknown";

              final quantity =
                  (sizeCountNew[size]?.containsKey('quantity') ?? false)
                      ? sizeCountNew[size]!['quantity']! + 1
                      : 1;

              if (!sizeCountNew.containsKey(size)) {
                sizeCountNew[size] = {'quantity': quantity, 'listTire': []};
              }

              sizeCountNew[size]!['listTire'].add({
                'brand': brand,
                'pattern': pattern,
                'sn': sn,
                'lifetime': lifetime,
              });

              sizeCountNew[size]!['quantity'] = quantity;
            }
            resultNew = sizeCountNew;

            // simpan data detail tire inventory di local
            final detailJsonData = jsonEncode({
              'new': resultNew,
              'repair': resultRepair,
              'spare': resultSpare,
              'scrap': resultScrap
            });
            log('detailJsonData : $detailJsonData');

            await prefs.setString('detail_tire_spec', detailJsonData);
          }

          emit(TireInventLoadedState(
              tireBlocData: count,
              site: {'idSite': site.idSite, 'siteName': site.site}));
        } catch (e) {
          log('message error : $e');
          // if (await getIdSitePreferences() == '1' ||
          //     await getIdSitePreferences() == '2') {
          //   emit(TireInventErrorState(message: 'Please Try Again!'));
          // }
        }
        // }
      }
    });
  }
}
