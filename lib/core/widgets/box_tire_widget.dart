// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:developer';

import 'package:camos/core/services/model/tire_spec.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:flutter/material.dart';

import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';

class BoxTireWidget extends StatelessWidget {
  const BoxTireWidget({
    Key? key,
    required this.tire,
  }) : super(key: key);

  final Map<String, dynamic> tire;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.17,
        height: MediaQuery.of(context).size.height * 0.12,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              double fontSize = constraints.maxWidth * 0.25;
              String initialScrapAvg = tire['total'];
              final scrapAvg = initialScrapAvg.split('|');
              return Text(
                (tire['status'] == 'Scrap')
                    ? '${scrapAvg[0]}'
                    : '${tire['total']} Pcs',
                style: getBlackTextStyle(fontSize: fontSize, fontWeight: w700),
              );
            }),
            LayoutBuilder(builder: (context, constraints) {
              double fontSize = constraints.maxWidth * 0.2;
              log(fontSize.toString());
              return Text(
                (tire['status'] != 'Scrap')
                    ? tire['status'] + ' Tire'
                    : 'Average Lifetime Scrap',
                textAlign: TextAlign.center,
                style: getBlackTextStyle(
                  fontSize: fontSize,
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
