// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class TextButtonWidget extends StatelessWidget {
  const TextButtonWidget({
    Key? key,
    required this.name,
    required this.style,
    required this.function,
  }) : super(key: key);

  final String name;
  final TextStyle style;
  final VoidCallback function;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: function,
        child: Text(
          name,
          style: style,
        ));
  }
}
