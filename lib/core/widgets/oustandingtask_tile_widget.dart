// ignore_for_file: public_member_api_docs, sort_constructors_first
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

  final OutstandingTask task;

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   width: double.infinity,
    //   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
    //   decoration: BoxDecoration(
    //     color: Colors.grey.withOpacity(0.2),
    //     borderRadius: BorderRadius.circular(12),
    //   ),
    //   child: Row(
    //     children: [
    //       CircleAvatar(
    //         backgroundColor: Color(0xff447362),
    //         child: Icon(
    //           Icons.monetization_on,
    //           color: green39D2C0,
    //         ),
    //       ),
    //       const SizedBox(
    //         width: 12,
    //       ),
    //       Expanded(
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Container(
    //               width: 150,
    //               child: Text(
    //                 task.code,
    //                 style: getWhiteTextStyle(
    //                   fontSize: 18,
    //                   fontWeight: w700,
    //                 ),
    //               ),
    //             ),
    //             Text(
    //               task.status,
    //               style: getWhiteTextStyle(),
    //             ),
    //           ],
    //         ),
    //       ),
    //       Column(
    //         crossAxisAlignment: CrossAxisAlignment.end,
    //         children: [
    //           Text(
    //             task.tireSize,
    //             style: getWhiteTextStyle(
    //               fontSize: 12,
    //             ),
    //           ),
    //           Text(
    //             'Position ${task.position}',
    //             style: getWhiteTextStyle(
    //               fontSize: 12,
    //             ),
    //           ),
    //         ],
    //       )
    //     ],
    //   ),
    // );

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
