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

/// Pilihan Area/PIT yang mendukung lebih dari satu area.
///
/// Index 0 adalah opsi "All" dan selalu eksklusif dengan area lainnya.
class MultiSelectPitButton extends StatelessWidget {
  final List<String> pit;
  final Set<int> selectedPits;
  final ValueChanged<Set<int>> onSelectedPitsChanged;

  const MultiSelectPitButton({
    Key? key,
    required this.pit,
    required this.selectedPits,
    required this.onSelectedPitsChanged,
  }) : super(key: key);

  Set<int> _normalizeSelection(Set<int> selection) {
    final result =
        selection.where((index) => index >= 0 && index < pit.length).toSet();

    if (result.isEmpty || result.contains(0)) {
      return <int>{0};
    }

    return result;
  }

  Set<int> _toggleSelection(Set<int> selection, int index) {
    if (index == 0) return <int>{0};

    final result = _normalizeSelection(selection)..remove(0);
    if (!result.add(index)) {
      result.remove(index);
    }

    return result.isEmpty ? <int>{0} : result;
  }

  void _showAllPit(BuildContext context) {
    Set<int> draftSelection = _normalizeSelection(selectedPits);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                          'Pilih Area / PIT',
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Anda dapat memilih lebih dari satu area.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: pit.length,
                      separatorBuilder: (context, index) {
                        return const Divider(height: 1);
                      },
                      itemBuilder: (context, index) {
                        final isSelected = draftSelection.contains(index);
                        final label = pit[index];

                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          value: isSelected,
                          activeColor: Colors.orange,
                          controlAffinity: ListTileControlAffinity.trailing,
                          secondary: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.orange : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              index == 0
                                  ? Icons.select_all_rounded
                                  : Icons.location_on_outlined,
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          title: Text(
                            label,
                            style: getBlackTextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          onChanged: (_) {
                            setModalState(() {
                              draftSelection =
                                  _toggleSelection(draftSelection, index);
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              draftSelection = <int>{0};
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            onSelectedPitsChanged(
                              _normalizeSelection(draftSelection),
                            );
                            Navigator.pop(bottomSheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text(
                            'Terapkan',
                            style: getWhiteTextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pit.isEmpty) return const SizedBox.shrink();

    final activeSelection = _normalizeSelection(selectedPits);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 2, right: 8),
              itemCount: pit.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (context, index) {
                final isSelected = activeSelection.contains(index);

                return ElevatedButton(
                  onPressed: () {
                    onSelectedPitsChanged(
                      _toggleSelection(activeSelection, index),
                    );
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
                    pit[index],
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
        Material(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _showAllPit(context),
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.filter_alt_rounded,
                    color: Colors.white,
                  ),
                ),
                if (!activeSelection.contains(0))
                  Positioned(
                    right: -4,
                    top: -5,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '${activeSelection.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
