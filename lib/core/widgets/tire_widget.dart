import 'package:camos/core/styles/asset_path.dart';
import 'package:flutter/material.dart';

class TireWidget extends StatelessWidget {
  const TireWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: 25,
      child: Image.asset('${imagePath}/tire_image.png', fit: BoxFit.cover),
    );
  }
}
