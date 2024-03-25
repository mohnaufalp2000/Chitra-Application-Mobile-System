// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:camos/core/styles/color.dart';
import 'package:flutter/material.dart';

class OutlinedButtonWidget extends StatelessWidget {
  const OutlinedButtonWidget({
    Key? key,
    required this.name,
    required this.function,
  }) : super(key: key);

  final Widget name;
  final VoidCallback function;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
          onPressed: function,
          style: ElevatedButton.styleFrom(
              backgroundColor: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: black),
              )),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15), child: name)),
    );
  }
}
