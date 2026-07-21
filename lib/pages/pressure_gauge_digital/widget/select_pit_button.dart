// import '../../../core/styles/text_manager.dart';
// import 'package:flutter/material.dart';

// // Widget yang bisa digunakan kembali
// class SelectPitButton extends StatelessWidget {
//   final List<String> pit;
//   final int selectedPit;
//   final ValueChanged<int> onSelectedPitChanged;

//   const SelectPitButton({
//     Key? key,
//     required this.pit,
//     required this.selectedPit,
//     required this.onSelectedPitChanged,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Jika pit kosong, tampilkan pesan atau widget default
//     if (pit.isEmpty) {
//       return Container();
//     }

//     return Center(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Wrap(
//             spacing: 4.0, // Jarak horizontal antar tombol
//             children: pit.asMap().entries.map((entry) {
//               final int index = entry.key;
//               final String label = entry.value;

//               return Container(
//                 width: index == 0 ? double.infinity : null,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: (selectedPit == index)
//                         ? Colors.orange
//                         : Colors.grey[300],
//                   ),
//                   onPressed: () => onSelectedPitChanged(index),
//                   child: Text(
//                     index == 0 ? 'All' : label,
//                     style: (selectedPit == index)
//                         ? getWhiteTextStyle()
//                         : getBlackTextStyle(),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }

import '../../../core/styles/text_manager.dart';
import 'package:flutter/material.dart';

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

  void _showAllPit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.70,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Garis indikator
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pilih PIT',
                      style: getBlackTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(bottomSheetContext);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const Divider(),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pit.length,
                  separatorBuilder: (context, index) {
                    return const Divider(height: 1);
                  },
                  itemBuilder: (context, index) {
                    final bool isSelected = selectedPit == index;
                    final String label = pit[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          index == 0
                              ? Icons.select_all_rounded
                              : Icons.location_on_outlined,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                      title: Text(
                        label,
                        style: isSelected
                            ? getBlackTextStyle(
                                fontWeight: FontWeight.w700,
                              )
                            : getBlackTextStyle(),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.orange,
                            )
                          : const Icon(
                              Icons.radio_button_unchecked,
                              color: Colors.grey,
                            ),
                      onTap: () {
                        onSelectedPitChanged(index);
                        Navigator.pop(bottomSheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pit.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // List PIT yang bisa digeser kanan-kiri
        Expanded(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 2,
                right: 8,
              ),
              itemCount: pit.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (context, index) {
                final bool isSelected = selectedPit == index;
                final String label = pit[index];

                return ElevatedButton(
                  onPressed: () {
                    onSelectedPitChanged(index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? Colors.orange : Colors.grey[300],
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                    elevation: isSelected ? 2 : 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    style:
                        isSelected ? getWhiteTextStyle() : getBlackTextStyle(),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Tombol filter tetap di sebelah kanan
        Material(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              _showAllPit(context);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: const Icon(
                Icons.filter_alt_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
