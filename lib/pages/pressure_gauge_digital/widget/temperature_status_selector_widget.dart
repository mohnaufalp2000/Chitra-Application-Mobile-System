import 'package:flutter/material.dart';

class TemperatureStatusSelectorWidget extends StatelessWidget {
  final String selectedStatus;
  final Function(String value) onChanged;

  const TemperatureStatusSelectorWidget({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildItem(
            label: 'HOT',
            icon: Icons.local_fire_department,
            activeColor: Colors.red,
            isActive: selectedStatus == 'HOT',
            onTap: () => onChanged('HOT'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildItem(
            label: 'COLD',
            icon: Icons.ac_unit,
            activeColor: Colors.lightBlueAccent,
            isActive: selectedStatus == 'COLD',
            onTap: () => onChanged('COLD'),
          ),
        ),
      ],
    );
  }

  Widget _buildItem({
    required String label,
    required IconData icon,
    required Color activeColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
