import 'package:flutter/material.dart';

class TemperatureStatusBadgeWidget extends StatelessWidget {
  final String status;

  const TemperatureStatusBadgeWidget({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHot = status == 'HOT';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHot ? Icons.local_fire_department : Icons.ac_unit,
            size: 12,
            color: isHot ? Colors.red : Colors.lightBlueAccent,
          ),
          const SizedBox(width: 3),
          Text(
            status,
            style: TextStyle(
              color: isHot ? Colors.red : Colors.lightBlueAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
