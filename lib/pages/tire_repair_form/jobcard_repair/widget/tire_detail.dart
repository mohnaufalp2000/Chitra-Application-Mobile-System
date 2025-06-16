import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TireDetail extends StatelessWidget {
  final Map<String, dynamic> tireDetail;
  final String wo;
  final String woDate;

  const TireDetail(
      {super.key,
      required this.tireDetail,
      required this.wo,
      required this.woDate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ReadOnlyBox(title: 'Customer', value: tireDetail['customer']),
          ReadOnlyBox(
              title: 'Repair Location', value: tireDetail['repair_location']),
          const Divider(color: grey8391A1),
          ReadOnlyBox(title: 'W/O #', value: wo),
          ReadOnlyBox(
              title: 'W/O # Date',
              value: DateFormat('dd-MM-yyyy')
                  .format(DateTime.parse(woDate))), // Isi kalau ada tanggal
          const Divider(color: grey8391A1),
          ReadOnlyBox(title: 'Tire Size', value: tireDetail['tire_size']),
          ReadOnlyBox(title: 'Brand', value: tireDetail['brand']),
          ReadOnlyBox(title: 'Serial Number', value: tireDetail['sn']),
          ReadOnlyBox(title: 'Pattern', value: tireDetail['pattern']),
          ReadOnlyBox(
              title: 'Tire Construction',
              value: tireDetail['type_construction']),
        ],
      ),
    );
  }
}

class ReadOnlyBox extends StatelessWidget {
  final String title;
  final String value;
  final double height;

  const ReadOnlyBox({
    super.key,
    required this.title,
    required this.value,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: getBlackTextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Container(
            height: height,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: grey8391A1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.isNotEmpty ? value : '-',
              style: getBlackTextStyle(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
