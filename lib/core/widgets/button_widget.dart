// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    Key? key,
    required this.name,
    required this.function,
    this.color = black,
  }) : super(key: key);

  final Widget name;
  final VoidCallback? function;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
          onPressed: function,
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15), child: name)),
    );
  }
}
