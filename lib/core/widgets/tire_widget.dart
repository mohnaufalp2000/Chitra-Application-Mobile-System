import '../styles/asset_path.dart';
import 'package:flutter/material.dart';

class TireWidget extends StatelessWidget {
  const TireWidget({
    super.key,
    this.height = 90,
    this.width = 25,
  });
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      child: Image.asset('${imagePath}/tire_image.png', fit: BoxFit.cover),
    );
  }
}
