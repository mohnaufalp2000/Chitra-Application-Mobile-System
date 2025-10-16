import '../../../core/styles/text_manager.dart';
import 'package:flutter/material.dart';

// Widget yang bisa digunakan kembali
class SelectPitButton extends StatelessWidget {
  final List<String> pit;
  final int selectedPit;
  final ValueChanged<int> onSelectedPitChanged;

  const SelectPitButton({
    Key? key,
    required this.pit,
    required this.selectedPit,
    required this.onSelectedPitChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Jika pit kosong, tampilkan pesan atau widget default
    if (pit.isEmpty) {
      return Container();
    }

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            spacing: 4.0, // Jarak horizontal antar tombol
            children: pit.asMap().entries.map((entry) {
              final int index = entry.key;
              final String label = entry.value;

              return Container(
                width: index == 0 ? double.infinity : null,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (selectedPit == index)
                        ? Colors.orange
                        : Colors.grey[300],
                  ),
                  onPressed: () => onSelectedPitChanged(index),
                  child: Text(
                    index == 0 ? 'All' : label,
                    style: (selectedPit == index)
                        ? getWhiteTextStyle()
                        : getBlackTextStyle(),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
