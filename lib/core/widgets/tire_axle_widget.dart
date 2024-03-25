// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/utils/data/tire.dart';

class TireAxleWidget extends StatefulWidget {
  const TireAxleWidget({
    Key? key,
    required this.leftTire,
    required this.rightTire,
  }) : super(key: key);

  final List<Widget> leftTire;
  final List<Widget> rightTire;

  @override
  State<TireAxleWidget> createState() => _TireAxleWidgetState();
}

class _TireAxleWidgetState extends State<TireAxleWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: widget.leftTire.map((tire) {
            return tire;
          }).toList(),
        ),
        Expanded(
          child: Container(
            width: 10,
            height: 10,
            color: Colors.yellow,
          ),
        ),
        Row(
          children: widget.rightTire.map((tire) {
            return tire;
          }).toList(),
        ),
      ],
    );
  }
}
