// import 'dart:developer';

// import '../../core/blocs/detail_tire_invent/detail_tire_invent_bloc.dart';
// import '../../core/blocs/tire_invent/tire_invent_bloc.dart';
// import '../../core/services/api_service.dart';
// import '../../core/services/model/site.dart';
// import '../../core/styles/color.dart';
// import '../../core/styles/text_manager.dart';
// import '../../core/widgets/appbar_widget.dart';
// import '../../core/widgets/custom_error_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class TireInventoryPage extends StatefulWidget {
//   static const routeName = 'tire-inventory-page';
//   const TireInventoryPage({super.key});

//   @override
//   State<TireInventoryPage> createState() => _TireInventoryPageState();
// }

// class _TireInventoryPageState extends State<TireInventoryPage> {
//   @override
//   Widget build(BuildContext context) {
//     Map<String, dynamic> status =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

//     context.read<DetailTireInventBloc>().add(GetDetailTireInventEvent(
//         total: status['total'],
//         idSite: status['idSite'],
//         status: status['status']));

//     return Scaffold(
//       appBar: appBarWidget('Tire Inventory (${status['status']})', context),
//       body: SafeArea(child: SingleChildScrollView(
//         child: BlocBuilder<DetailTireInventBloc, DetailTireInventState>(
//           builder: (context, state) {
//             if (state is DetailTireInventLoadingState) {
//               return Center(
//                 child: CircularProgressIndicator(),
//               );
//             }

//             if (state is DetailTireInventErrorState) {
//               return CustomErrorWidget(
//                   errorMessage: 'Please Try Again',
//                   onRefresh: () {
//                     context.read<DetailTireInventBloc>().add(
//                         GetDetailTireInventEvent(
//                             total: status['total'],
//                             idSite: status['idSite'],
//                             status: status['status']));
//                   });
//             }

//             if (state is DetailTireInventLoadedState) {
//               final map = state.mapSizeInvent;
//               Map<String, dynamic> typeInventory = {};
//               switch (status['status']) {
//                 case 'New':
//                   typeInventory = map['New'] ?? {};
//                   log('Data New : ${map['New']}');
//                   break;
//                 case 'Repair':
//                   typeInventory = map['Repair'] ?? {};
//                   log('Data Repair : ${map['Repair']}');
//                   break;
//                 case 'Spare':
//                   typeInventory = map['Spare'] ?? {};
//                   log('Data Spare : ${map['Spare']}');
//                   break;
//                 case 'Scrap':
//                   typeInventory = map['Scrap'] ?? {};
//                   log('Data Scrap : ${map['Scrap']}');
//                   break;
//               }
//               log('detail tire invent : $map');
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                 child: Column(
//                   children: [
//                     const SizedBox(
//                       height: 24,
//                     ),
//                     (typeInventory.isNotEmpty && typeInventory.length > 0)
//                         ? Column(
//                             children: typeInventory.entries.map<Widget>((data) {
//                               if (status['status'] == 'Scrap') {
//                                 return Card(
//                                   elevation: 2,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Container(
//                                     width: double.infinity,
//                                     padding: EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(colors: [
//                                         green00968A,
//                                         blue344BEF,
//                                       ]),
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: ExpansionTile(
//                                       tilePadding: EdgeInsets.zero,
//                                       childrenPadding: EdgeInsets.all(0),
//                                       title: Row(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.center,
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceEvenly,
//                                         children: [
//                                           Text(
//                                             'Tire of ${data.key}',
//                                             style: getWhiteTextStyle(
//                                                 fontWeight: w700, fontSize: 20),
//                                           ),
//                                         ],
//                                       ),
//                                       trailing: Container(
//                                           height: 100,
//                                           child: Icon(
//                                             Icons.arrow_drop_down,
//                                             size: 32,
//                                             color: white,
//                                           )),
//                                       children: [
//                                         ListView.builder(
//                                           shrinkWrap: true,
//                                           physics:
//                                               NeverScrollableScrollPhysics(),
//                                           itemCount: data.value.entries.length,
//                                           itemBuilder: (context, index) {
//                                             var brandData = data.value.entries
//                                                 .elementAt(index);
//                                             var brandName = brandData.key;
//                                             Map<String, dynamic> brandDetails =
//                                                 brandData.value;

//                                             Map<String, dynamic> valuesMap =
//                                                 brandDetails.values.first;

//                                             int quantity =
//                                                 valuesMap['Quantity'];
//                                             int lifetimeAvg =
//                                                 valuesMap['Lifetime Avg'];

//                                             return Card(
//                                               elevation: 2,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               ),
//                                               child: Container(
//                                                 padding: EdgeInsets.all(12),
//                                                 width: double.infinity,
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     Text(
//                                                       brandName,
//                                                       style: getBlackTextStyle(
//                                                         fontWeight: w700,
//                                                       ),
//                                                     ),
//                                                     Text(
//                                                       brandDetails.keys
//                                                           .first, // Pattern
//                                                       style:
//                                                           getBlackTextStyle(),
//                                                     ),
//                                                     Text(
//                                                       'Quantity: $quantity',
//                                                       style:
//                                                           getBlackTextStyle(),
//                                                     ),
//                                                     Text(
//                                                       'Lifetime Avg: $lifetimeAvg',
//                                                       style:
//                                                           getBlackTextStyle(),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               } else if (status['status'] == 'Spare') {
//                                 log('data spare : $data');
//                                 return Card(
//                                   elevation: 2,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Container(
//                                     width: double.infinity,
//                                     padding: EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(colors: [
//                                         green00968A,
//                                         blue344BEF,
//                                       ]),
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: ExpansionTile(
//                                       title: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Text(
//                                             'Tire of ${data.key}',
//                                             style: getWhiteTextStyle(
//                                                 fontWeight: w700, fontSize: 20),
//                                           ),
//                                           Text(
//                                             '${data.value['quantity']}',
//                                             style: getWhiteTextStyle(
//                                                 fontWeight: w700, fontSize: 20),
//                                           )
//                                         ],
//                                       ),
//                                       trailing: Container(
//                                           height: 100,
//                                           child: Icon(
//                                             Icons.arrow_drop_down,
//                                             size: 32,
//                                             color: white,
//                                           )),
//                                       children: [
//                                         ListView.builder(
//                                             shrinkWrap: true,
//                                             physics:
//                                                 NeverScrollableScrollPhysics(),
//                                             itemCount:
//                                                 data.value['listTire'].length,
//                                             itemBuilder: (context, index) {
//                                               // return Text(
//                                               //     data.value[index]['sn']);
//                                               return Card(
//                                                 elevation: 2,
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                 ),
//                                                 child: Container(
//                                                   padding: EdgeInsets.all(12),
//                                                   width: double.infinity,
//                                                   child: Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment
//                                                             .start,
//                                                     children: [
//                                                       Text(
//                                                         '' +
//                                                             data.value[
//                                                                     'listTire'][
//                                                                 index]['brand'],
//                                                         style:
//                                                             getBlackTextStyle(
//                                                                 fontSize: 18,
//                                                                 fontWeight:
//                                                                     w700),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 12,
//                                                       ),
//                                                       Text(
//                                                         '' +
//                                                             data.value['listTire']
//                                                                     [index]
//                                                                 ['pattern'],
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 12,
//                                                       ),
//                                                       Text(
//                                                         'SN : ' +
//                                                             data.value[
//                                                                     'listTire']
//                                                                 [index]['sn'],
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 12,
//                                                       ),
//                                                       Text(
//                                                         'Lifetime : ' +
//                                                             data.value['listTire']
//                                                                     [index][
//                                                                 'lifetime'], // Pattern
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               );
//                                             })
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               } else if (status['status'] == 'Repair') {
//                                 return Card(
//                                   elevation: 2,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Container(
//                                     width: double.infinity,
//                                     padding: EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(colors: [
//                                         green00968A,
//                                         blue344BEF,
//                                       ]),
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: ExpansionTile(
//                                       tilePadding: EdgeInsets.zero,
//                                       childrenPadding: EdgeInsets.all(0),
//                                       title: Row(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.center,
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceEvenly,
//                                         children: [
//                                           Text(
//                                             'Tire of ${data.key}',
//                                             style: getWhiteTextStyle(
//                                                 fontWeight: w700, fontSize: 20),
//                                           ),
//                                         ],
//                                       ),
//                                       trailing: Container(
//                                           height: 100,
//                                           child: Icon(
//                                             Icons.arrow_drop_down,
//                                             size: 32,
//                                             color: white,
//                                           )),
//                                       children: [
//                                         ListView.builder(
//                                             shrinkWrap: true,
//                                             physics:
//                                                 NeverScrollableScrollPhysics(),
//                                             itemCount: data.value.length as int,
//                                             itemBuilder: (context, index) {
//                                               // return Text(
//                                               //     data.value[index]['sn']);
//                                               return Card(
//                                                 elevation: 2,
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                 ),
//                                                 child: Container(
//                                                   padding: EdgeInsets.all(12),
//                                                   width: double.infinity,
//                                                   child: Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment
//                                                             .start,
//                                                     children: [
//                                                       Text(
//                                                         '' +
//                                                             data.value[index]
//                                                                 ['brand'],
//                                                         style:
//                                                             getBlackTextStyle(
//                                                                 fontSize: 18,
//                                                                 fontWeight:
//                                                                     w700),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 12,
//                                                       ),
//                                                       Text(
//                                                         '' +
//                                                             data.value[index]
//                                                                 ['pattern'],
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 12,
//                                                       ),
//                                                       Text(
//                                                         'SN : ' +
//                                                             data.value[index]
//                                                                 ['sn'],
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 12,
//                                                       ),
//                                                       Text(
//                                                         'Lifetime : ' +
//                                                             data.value[index][
//                                                                 'lifetime'], // Pattern
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               );
//                                             })
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               } else {
//                                 log('data new : ${data.value}');
//                                 return Card(
//                                   elevation: 2,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Container(
//                                     width: double.infinity,
//                                     padding: EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(colors: [
//                                         green00968A,
//                                         blue344BEF,
//                                       ]),
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: ExpansionTile(
//                                       title: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Text(
//                                             'Tire of ${data.key}',
//                                             style: getWhiteTextStyle(
//                                                 fontWeight: w700, fontSize: 20),
//                                           ),
//                                           Text(
//                                             '${data.value['quantity']}',
//                                             style: getWhiteTextStyle(
//                                                 fontWeight: w700, fontSize: 20),
//                                           )
//                                         ],
//                                       ),
//                                       trailing: Container(
//                                           height: 100,
//                                           child: Icon(
//                                             Icons.arrow_drop_down,
//                                             size: 32,
//                                             color: white,
//                                           )),
//                                       children: [
//                                         ListView.builder(
//                                             shrinkWrap: true,
//                                             physics:
//                                                 NeverScrollableScrollPhysics(),
//                                             itemCount:
//                                                 data.value['listTire'].length,
//                                             itemBuilder: (context, index) {
//                                               // return Text(
//                                               //     data.value[index]['sn']);
//                                               return Card(
//                                                 elevation: 2,
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                 ),
//                                                 child: Container(
//                                                   padding: EdgeInsets.all(12),
//                                                   width: double.infinity,
//                                                   child: Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment
//                                                             .start,
//                                                     children: [
//                                                       Text(
//                                                         '' +
//                                                             data.value[
//                                                                     'listTire'][
//                                                                 index]['brand'],
//                                                         style:
//                                                             getBlackTextStyle(
//                                                                 fontSize: 18,
//                                                                 fontWeight:
//                                                                     w700),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 12,
//                                                       ),
//                                                       Text(
//                                                         '' +
//                                                             data.value['listTire']
//                                                                     [index]
//                                                                 ['pattern'],
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 12,
//                                                       ),
//                                                       Text(
//                                                         'SN : ' +
//                                                             data.value[
//                                                                     'listTire']
//                                                                 [index]['sn'],
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 12,
//                                                       ),
//                                                       Text(
//                                                         'Lifetime : ' +
//                                                             data.value['listTire']
//                                                                     [index][
//                                                                 'lifetime'], // Pattern
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               );
//                                             })
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               }
//                               return Container();
//                             }).toList(),
//                           )
//                         : Center(
//                             child: Text(
//                               'Empty',
//                               style: getBlackTextStyle(fontSize: 24),
//                             ),
//                           )
//                   ],
//                 ),
//               );
//             }

//             return Container();
//           },
//         ),
//       )),
//     );
//   }
// }

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/custom_error_widget.dart';
import '../home/home_state.dart';
import 'tire_inventory_state.dart';

class TireInventoryPage extends StatelessWidget {
  static const routeName = '/tire-inventory-page';

  TireInventoryPage({super.key});

  final homeState = Get.find<HomeState>();
  final tireInventoryState = Get.put(TireInventoryState());

  @override
  Widget build(BuildContext context) {
    final status = homeState.selectedInventoryStatus.value;
    final total = homeState.selectedInventoryTotal.value;
    final idSite = homeState.selectedInventoryIdSite.value;

    // 🔹 Panggil API di awal
    tireInventoryState.getDetailTireInvent(
      total: total,
      idSite: idSite,
      status: status,
    );

    log('📦 Inventory Data => total: $total, idSite: $idSite, status: $status');

    return Scaffold(
      appBar: appBarWidget('Tire Inventory ($status)', context),
      body: SafeArea(
        child: Obx(() {
          if (tireInventoryState.isLoading.value) {
            return Center(
                child: Column(
              children: [
                CircularProgressIndicator(),
                Text('${tireInventoryState.loadingPercent.value}')
              ],
            ));
          }

          if (tireInventoryState.hasError.value) {
            return CustomErrorWidget(
              errorMessage: tireInventoryState.errorMessage.value,
              onRefresh: () {
                tireInventoryState.getDetailTireInvent(
                  total: total,
                  idSite: idSite,
                  status: status,
                );
              },
            );
          }

          final map = tireInventoryState.mapSizeInvent;
          Map<String, dynamic> typeInventory = {};

          switch (status) {
            case 'New':
              typeInventory = map['New'] ?? {};
              log('🆕 Data New: ${map['New']}');
              break;
            case 'Repair':
              typeInventory = map['Repair'] ?? {};
              log('🧰 Data Repair: ${map['Repair']}');
              break;
            case 'Spare':
              typeInventory = map['Spare'] ?? {};
              log('📦 Data Spare: ${map['Spare']}');
              break;
            case 'Scrap':
              typeInventory = map['Scrap'] ?? {};
              log('♻️ Data Scrap: ${map['Scrap']}');
              break;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                (typeInventory.isNotEmpty)
                    ? Column(
                        children: typeInventory.entries
                            .map((data) => _buildInventoryCard(status, data))
                            .toList(),
                      )
                    : Center(
                        child: Text(
                          'Empty',
                          style: getBlackTextStyle(fontSize: 24),
                        ),
                      ),
                const SizedBox(height: 24),
                Text(
                  tireInventoryState.lastSyncInvent.value,
                  style: getBlackTextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 🔹 Widget card tiap kategori (New, Repair, Spare, Scrap)
  Widget _buildInventoryCard(String status, MapEntry data) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [green00968A, blue344BEF]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          title: Text(
            '${data.key}',
            style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
          ),
          children: [
            if (status == 'Scrap') ..._buildScrapList(data),
            if (status == 'New' || status == 'Spare')
              ..._buildNewOrSpareList(data),
            if (status == 'Repair') ..._buildRepairList(data),
          ],
        ),
      ),
    );
  }

  /// 🧱 Scrap (Grouped)
  List<Widget> _buildScrapList(MapEntry data) {
    final brands = data.value as Map<String, dynamic>;
    return brands.entries.map((brandEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: brandEntry.value.entries.map<Widget>((patternEntry) {
          final info = patternEntry.value as Map<String, dynamic>;
          return ListTile(
            title: Text(
              '${brandEntry.key} - ${patternEntry.key}',
              style: getWhiteTextStyle(fontWeight: w600),
            ),
            subtitle: Text(
              'Qty: ${info['Quantity']} | Avg Life: ${info['Lifetime Avg']}',
              style: getWhiteTextStyle(fontSize: 13),
            ),
          );
        }).toList(),
      );
    }).toList();
  }

  /// 🆕 New / Spare
  List<Widget> _buildNewOrSpareList(MapEntry data) {
    final value = data.value as Map<String, dynamic>;
    final list = value['listTire'] ?? [];
    return list.map<Widget>((tire) {
      return ListTile(
        title: Text(
          '${tire['brand']} - ${tire['pattern']}',
          style: getWhiteTextStyle(fontWeight: w600),
        ),
        subtitle: Text(
          'SN: ${tire['sn']} | Life: ${tire['lifetime']}',
          style: getWhiteTextStyle(fontSize: 13),
        ),
      );
    }).toList();
  }

  /// 🔧 Repair
  List<Widget> _buildRepairList(MapEntry data) {
    final list = data.value as List<dynamic>;
    return list.map<Widget>((tire) {
      return ListTile(
        title: Text(
          '${tire['brand']} - ${tire['pattern']}',
          style: getWhiteTextStyle(fontWeight: w600),
        ),
        subtitle: Text(
          'SN: ${tire['sn']} | Life: ${tire['lifetime']}',
          style: getWhiteTextStyle(fontSize: 13),
        ),
      );
    }).toList();
  }
}
