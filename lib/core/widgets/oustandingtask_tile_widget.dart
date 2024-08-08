// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
import 'package:camos/core/services/model/outstanding_task.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:flutter/material.dart';

import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/oustanding_task.dart';

class OustandingTileWidget extends StatelessWidget {
  const OustandingTileWidget({
    Key? key,
    required this.task,
  }) : super(key: key);

  // final List<Map<String, dynamic>> task;
  final OutstandingTask task;

  @override
  Widget build(BuildContext context) {
    // task.sort((a, b) {
    //   final first = (a['position']).toString();
    //   final second = (b['position']).toString();

    //   return first.compareTo(second);
    // });

    // return Card(
    //     elevation: 2,
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(12),
    //     ),
    //     color: green00968A,
    //     child: Container(
    //       width: double.infinity,
    //       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
    //       decoration: BoxDecoration(
    //         color: green00968A,
    //         borderRadius: BorderRadius.circular(12),
    //       ),
    //       child: ExpansionTile(
    //         tilePadding: EdgeInsets.zero,
    //         childrenPadding: EdgeInsets.all(0),
    //         title: Row(
    //           children: [
    //             Icon(
    //               Icons.task,
    //               color: white,
    //               size: 36,
    //             ),
    //             const SizedBox(
    //               width: 12,
    //             ),
    //             // Text(
    //             //   dailyMap['unit'] +
    //             //       '${((dailyMap['pit'] != 'Default') ? ' - ' + dailyMap['pit'] : '')}',
    //             //   style: getWhiteTextStyle(
    //             //       fontWeight: w700,
    //             //       fontSize: 18),
    //             // )
    //             Text(
    //               task[0]['unit'],
    //               style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
    //             )
    //           ],
    //         ),
    //         trailing: SizedBox(
    //           width: 90,
    //           child: Icon(Icons.arrow_drop_down),
    //         ),
    //         children: [
    //           const SizedBox(
    //             height: 12,
    //           ),
    //           Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //             children: [
    //               Text(
    //                 'Name',
    //                 style: getWhiteTextStyle(fontSize: 18),
    //               ),
    //               Container(
    //                 width: 250,
    //                 child: Text(
    //                   task[0]['user'],
    //                   textAlign: TextAlign.end,
    //                   style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
    //                 ),
    //               ),
    //             ],
    //           ),
    //           const SizedBox(
    //             height: 12,
    //           ),
    //           Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //             children: [
    //               Text(
    //                 'Tanggal',
    //                 style: getWhiteTextStyle(fontSize: 18),
    //               ),
    //               Text(
    //                 task[0]['last_update'].split('T')[0],
    //                 style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
    //               ),
    //             ],
    //           ),
    //           const SizedBox(
    //             height: 12,
    //           ),
    //           Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //             children: [
    //               Text(
    //                 'Waktu',
    //                 style: getWhiteTextStyle(fontSize: 18),
    //               ),
    //               Text(
    //                 task[0]['last_update'].split('T')[1].substring(0, 5),
    //                 style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
    //               ),
    //             ],
    //           ),
    //           const SizedBox(
    //             height: 12,
    //           ),
    //           Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //             children: [
    //               Text(
    //                 'HM Unit',
    //                 style: getWhiteTextStyle(fontSize: 18),
    //               ),
    //               Text(
    //                 ' dailyMap[hm]',
    //                 style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
    //               ),
    //             ],
    //           ),
    //           const SizedBox(
    //             height: 12,
    //           ),
    //           // Row(
    //           //   mainAxisAlignment:
    //           //       MainAxisAlignment.spaceBetween,
    //           //   children: [
    //           //     Text(
    //           //       'Pit',
    //           //       style: getWhiteTextStyle(
    //           //           fontSize: 18),
    //           //     ),
    //           //     Text(
    //           //       dailyMap['pit'],
    //           //       style: getWhiteTextStyle(
    //           //           fontWeight: w700,
    //           //           fontSize: 18),
    //           //     ),
    //           //   ],
    //           // ),
    //           // const SizedBox(
    //           //   height: 12,
    //           // ),
    //           Column(
    //             children: task.map((pl) {
    //               List<dynamic> luka = [];

    //               if (pl['tire_damage'] != null &&
    //                   pl['tire_damage'] is! String) {
    //                 luka = pl['tire_damage'] as List<dynamic>;
    //               }

    //               return Column(
    //                 children: [
    //                   Row(
    //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                     crossAxisAlignment: CrossAxisAlignment.center,
    //                     children: [
    //                       Text(
    //                         'Pos. ${pl['position']}',
    //                         style: getWhiteTextStyle(fontSize: 18),
    //                       ),
    //                       Column(
    //                         crossAxisAlignment: CrossAxisAlignment.end,
    //                         mainAxisAlignment: MainAxisAlignment.center,
    //                         children: [
    //                           Column(
    //                             crossAxisAlignment: CrossAxisAlignment.end,
    //                             children: [
    //                               Text(
    //                                 '${(pl['pressure'] == '' || pl['pressure'] == null) ? '0' : (pl['pressure']).toString()} Psi',
    //                                 style: getWhiteTextStyle(
    //                                     fontWeight: w700, fontSize: 18),
    //                               ),
    //                               // (pl['adjusmentPressure'] != null &&
    //                               //         pl['adjusmentPressure'] !=
    //                               //             '0' &&
    //                               //         pl['adjusmentPressure'] !=
    //                               //             '')
    //                               //     ? Text(
    //                               //         '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
    //                               //         style: getWhiteTextStyle(
    //                               //             fontWeight:
    //                               //                 w700,
    //                               //             fontSize:
    //                               //                 18),
    //                               //       )
    //                               //     : Container(),
    //                             ],
    //                           ),
    //                           (luka.isEmpty || luka == null)
    //                               ? Container()
    //                               : Text(
    //                                   pl['tire_damage'].join('\n'),
    //                                   textAlign: TextAlign.end,
    //                                   style: getWhiteTextStyle(
    //                                       fontWeight: w700, fontSize: 18),
    //                                 ),
    //                           const SizedBox(
    //                             height: 12,
    //                           ),
    //                         ],
    //                       ),
    //                     ],
    //                   ),
    //                   Divider(
    //                     color: white,
    //                     thickness: 1.5,
    //                   ),
    //                 ],
    //               );
    //             }).toList(),
    //           ),
    //           // Column(
    //           //   children: positionList.map((pl) {
    //           //     final plIndex =
    //           //         positionList.indexOf(pl);
    //           //     List<dynamic> luka = [];

    //           //     if (pl['luka'] != null &&
    //           //         pl['luka'] is! String) {
    //           //       luka =
    //           //           pl['luka'] as List<dynamic>;
    //           //     }

    //           //     return Column(
    //           //       children: [
    //           //         Row(
    //           //           mainAxisAlignment:
    //           //               MainAxisAlignment
    //           //                   .spaceBetween,
    //           //           crossAxisAlignment:
    //           //               CrossAxisAlignment
    //           //                   .center,
    //           //           children: [
    //           //             Text(
    //           //               'Pos. ${pl['pos']}',
    //           //               style:
    //           //                   getWhiteTextStyle(
    //           //                       fontSize: 18),
    //           //             ),
    //           //             Column(
    //           //               crossAxisAlignment:
    //           //                   CrossAxisAlignment
    //           //                       .end,
    //           //               mainAxisAlignment:
    //           //                   MainAxisAlignment
    //           //                       .center,
    //           //               children: [
    //           //                 Column(
    //           //                   crossAxisAlignment:
    //           //                       CrossAxisAlignment
    //           //                           .end,
    //           //                   children: [
    //           //                     Text(
    //           //                       '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
    //           //                       style: getWhiteTextStyle(
    //           //                           fontWeight:
    //           //                               w700,
    //           //                           fontSize:
    //           //                               18),
    //           //                     ),
    //           //                     (pl['adjusmentPressure'] != null &&
    //           //                             pl['adjusmentPressure'] !=
    //           //                                 '0' &&
    //           //                             pl['adjusmentPressure'] !=
    //           //                                 '')
    //           //                         ? Text(
    //           //                             '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
    //           //                             style: getWhiteTextStyle(
    //           //                                 fontWeight:
    //           //                                     w700,
    //           //                                 fontSize:
    //           //                                     18),
    //           //                           )
    //           //                         : Container(),
    //           //                   ],
    //           //                 ),
    //           //                 (luka.isEmpty ||
    //           //                         luka == null)
    //           //                     ? Container()
    //           //                     : Text(
    //           //                         pl['luka']
    //           //                             .join(
    //           //                                 '\n'),
    //           //                         textAlign:
    //           //                             TextAlign
    //           //                                 .end,
    //           //                         style: getWhiteTextStyle(
    //           //                             fontWeight:
    //           //                                 w700,
    //           //                             fontSize:
    //           //                                 18),
    //           //                       ),
    //           //                 const SizedBox(
    //           //                   height: 12,
    //           //                 ),
    //           //               ],
    //           //             ),
    //           //           ],
    //           //         ),
    //           //         Divider(
    //           //           color: white,
    //           //           thickness: 1.5,
    //           //         ),
    //           //       ],
    //           //     );
    //           //   }).toList(),
    //           // ),
    //         ],
    //       ),
    //     ));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: green00968A,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        decoration: BoxDecoration(
          color: green00968A,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.all(0),
          title: Row(
            children: [
              Icon(
                Icons.task,
                color: white,
                size: 36,
              ),
              const SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.brand,
                    style: getWhiteTextStyle(),
                  ),
                  Text(
                    task.unit,
                    style: getWhiteTextStyle(
                      fontSize: 18,
                      fontWeight: w700,
                    ),
                  )
                ],
              )
            ],
          ),
          trailing: SizedBox(
            width: 90,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Position',
                      style: getWhiteTextStyle(),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      task.position.toString(),
                      style: getWhiteTextStyle(fontWeight: w700),
                    )
                  ],
                ),
                const SizedBox(
                  width: 4,
                ),
                Icon(Icons.arrow_drop_down)
              ],
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Inspector',
                  style: getWhiteTextStyle(),
                ),
                Text(
                  task.user,
                  style: getWhiteTextStyle(
                    fontWeight: w700,
                  ),
                ),
                (task.userEmail != '' || task.userEmail != null)
                    ? Text(
                        task.userEmail,
                        style: getWhiteTextStyle(
                          fontWeight: w700,
                        ),
                      )
                    : Container()
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unit',
                  style: getWhiteTextStyle(),
                ),
                Text(
                  task.unit,
                  style: getWhiteTextStyle(
                    fontWeight: w700,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SN',
                  style: getWhiteTextStyle(),
                ),
                Text(
                  task.sn,
                  style: getWhiteTextStyle(
                    fontWeight: w700,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pressure',
                  style: getWhiteTextStyle(),
                ),
                Text(
                  '${task.pressure} Psi',
                  style: getWhiteTextStyle(
                    fontWeight: w700,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            (task.adjusmentPressure != '' || task.adjusmentPressure != null)
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Adjusment Pressure',
                            style: getWhiteTextStyle(),
                          ),
                          Text(
                            '${task.adjusmentPressure} Psi',
                            style: getWhiteTextStyle(
                              fontWeight: w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  )
                : const SizedBox(
                    height: 12,
                  ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RTD',
                  style: getWhiteTextStyle(),
                ),
                Text(
                  '${task.rtd}',
                  style: getWhiteTextStyle(
                    fontWeight: w700,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tire Size',
                  style: getWhiteTextStyle(),
                ),
                Text(
                  task.tireSize,
                  style: getWhiteTextStyle(
                    fontWeight: w700,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tire Damage',
                  style: getWhiteTextStyle(),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Text(
                    task.tireDamage,
                    textAlign: TextAlign.end,
                    style: getWhiteTextStyle(
                      fontWeight: w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Condition',
                  style: getWhiteTextStyle(),
                ),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: (task.condition != null)
                        ? task.condition.map((item) {
                            return Text(
                              (task.condition.isEmpty ||
                                      task.condition.length == 0 ||
                                      task.condition == [])
                                  ? '-'
                                  : item,
                              style: getWhiteTextStyle(fontWeight: w700),
                            );
                          }).toList()
                        : []),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remarks',
                  style: getWhiteTextStyle(),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    '${task.remarks}',
                    textAlign: TextAlign.end,
                    style: getWhiteTextStyle(
                      fontWeight: w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created At',
                  style: getWhiteTextStyle(),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Text(
                    formatDateTime(DateTime.parse(task.lastUpdate)),
                    textAlign: TextAlign.end,
                    style: getWhiteTextStyle(
                      fontWeight: w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
