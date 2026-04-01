import 'dart:io';

import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/pre_assembly_tire_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as p;
import 'package:path_provider/path_provider.dart';

class PreAssemblyTirePage extends StatelessWidget {
  static const routeName = '/pre-assembly-tire-page';

  PreAssemblyTirePage({super.key});

  final controller = Get.put(PreAssemblyTireState());

  Widget textField(String label, TextEditingController controllerText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controllerText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget yesNo(String key, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Obx(() => Row(
              children: [
                Radio(
                  value: "Ya",
                  groupValue: controller.formData[key],
                  onChanged: (val) => controller.setValue(key, val),
                ),
                const Text("Ya"),
                Radio(
                  value: "Tidak",
                  groupValue: controller.formData[key],
                  onChanged: (val) => controller.setValue(key, val),
                ),
                const Text("Tidak"),
              ],
            )),
        const SizedBox(height: 15)
      ],
    );
  }

  Widget kondisiDropdown(
      String key, String title, String subtitle, List<String> options) {
    /// set default value jika belum ada
    controller.formData.putIfAbsent(key, () => "Normal");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Obx(() => DropdownButtonFormField<String>(
              value: controller.formData[key],
              items: options
                  .map((e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (val) => controller.setValue(key, val),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            )),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget inputField(String key, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          onChanged: (val) => controller.setValue(key, val),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 15)
      ],
    );
  }

  Widget kondisiMulti(
      String key, String title, String subtitle, List<String> options) {
    controller.formData.putIfAbsent(key, () => <String>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        if (subtitle.isNotEmpty) Text(subtitle),
        const SizedBox(height: 6),
        Obx(() {
          final selected = (controller.formData[key] as List).cast<String>();

          return Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options.map((opt) {
              final isChecked = selected.contains(opt);

              return GestureDetector(
                onTap: () => controller.toggleMultiCondition(key, opt),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isChecked ? Colors.green : Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                    color: isChecked
                        ? Colors.green.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (_) =>
                            controller.toggleMultiCondition(key, opt),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opt,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
        const SizedBox(height: 15),
      ],
    );
  }

  // Widget kondisiMulti(
  //     String key, String title, String subtitle, List<String> options) {
  //   controller.formData.putIfAbsent(key, () => <String>[]);

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
  //       const SizedBox(height: 6),
  //       Text(subtitle),
  //       const SizedBox(height: 6),
  //       Obx(() {
  //         final selected = (controller.formData[key] as List).cast<String>();
  //         final isNormalSelected = selected.contains("Normal");

  //         return Wrap(
  //           spacing: 8,
  //           runSpacing: 6,
  //           children: options.map((opt) {
  //             final isChecked = selected.contains(opt);

  //             return GestureDetector(
  //               onTap: () => controller.toggleMultiCondition(key, opt),
  //               child: Container(
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  //                 decoration: BoxDecoration(
  //                   border: Border.all(
  //                       color: isChecked ? Colors.green : Colors.grey),
  //                   borderRadius: BorderRadius.circular(6),
  //                   color: isChecked
  //                       ? Colors.green.withOpacity(0.1)
  //                       : Colors.transparent,
  //                 ),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Checkbox(
  //                       value: isChecked,
  //                       onChanged: (_) =>
  //                           controller.toggleMultiCondition(key, opt),
  //                       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //                     ),
  //                     const SizedBox(width: 4),
  //                     Text(
  //                       opt,
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: (isNormalSelected && opt != "Normal")
  //                             ? Colors.grey
  //                             : Colors.black,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }).toList(),
  //         );
  //       }),
  //       const SizedBox(height: 15),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Pre-Assembly Tire', context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// HEADER
              textField("Rim Size", controller.rimSize),
              textField("Rim Brand", controller.rimBrand),
              textField("Serial No", controller.serialNo),

              const SizedBox(height: 20),

              /// CHECKLIST
              kondisiMulti(
                "rim_condition",
                "1. Kondisi RIM",
                'Periksa semua bagian RIM (Wheel Base)',
                [
                  "Normal",
                  "Berkarat",
                  "Crack Back Section",
                  "Crack Center Section",
                  "Crack Gutter Section"
                ],
              ),

              yesNo("lock_ring_gap",
                  "2. Periksa Lock Ring Groove, maks. gap 2 mm\n\n Ukur menggunakan Rim Groove Gauge, ada gap?"),

              yesNo("oring_gap",
                  "3. Periksa O Ring Groove Gap, maks. gap 2 mm\n\n Ukur menggunakan Rim Groove Gauge, ada gap?"),

              yesNo("hole_stud", "4. Periksa bagian Hole Stud?\n\n Oval?"),

              kondisiMulti(
                  "bead_seat",
                  "5. Periksa semua bagian Bead Seat Band",
                  '',
                  ["Normal", "Berkarat", "Crack", "Oval", "Dented", "Deform"]),

              kondisiMulti("flange", "6. Periksa semua bagian Flange", '',
                  ["Normal", "Berkarat", "Crack", "Oval", "Dented", "Deform"]),

              kondisiMulti(
                  "lock_ring_distance",
                  "7. Periksa semua bagian Lock Ring",
                  '',
                  ["Normal", "Berkarat", "Sprung"]),

              yesNo("lock_driver",
                  "8. Periksa bagian Lock Driver (Pada unit ADT, Loader).\n\n Apakah ada perubahan bentuk?"),

              yesNo("oring",
                  "9. Periksa semua bagian O-Ring?\n\nBentuk masih bulat tidak melar?"),
              yesNo("oring2", "Sambungan melekat sempurna?"),

              yesNo("valve_hole",
                  "10. Periksa bagian lubang valve\n\nKondisi ulir oval?"),

              yesNo(
                  "valve_protector", "11. Valve Stem Protector Dented(peyok)?"),

              yesNo("valve_stem", "12. Valve Stem Bengkot/Penyet?"),

              yesNo("valve_core", "13. Valve Core\n\nKondisi ulir valve core?"),
              const SizedBox(height: 20),

              inputField(
                "other_damage_note",
                "Catat jika ada kerusakan lain yang tidak ada dalam list",
              ),

              /// ACTION
              const Text("Action",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              Obx(() => Column(
                    children: [
                      RadioListTile(
                        title: const Text("Baik (Laik Operasi)"),
                        value: "baik",
                        groupValue: controller.action.value,
                        onChanged: (val) => controller.action.value = val!,
                      ),
                      RadioListTile(
                        title: const Text("Harus di Repair"),
                        value: "repair",
                        groupValue: controller.action.value,
                        onChanged: (val) => controller.action.value = val!,
                      ),
                      RadioListTile(
                        title: const Text("SCRAP"),
                        value: "scrap",
                        groupValue: controller.action.value,
                        onChanged: (val) => controller.action.value = val!,
                      ),
                    ],
                  )),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final pdf = p.Document();

                    final form = controller.formData;

                    pdf.addPage(
                      p.Page(
                        pageFormat: PdfPageFormat.a4.portrait,
                        margin: const p.EdgeInsets.all(15),
                        build: (context) {
                          final items = [
                            "Periksa semua bagian RIM (Wheel Base)",
                            "Periksa Lock ring groove, maks gap 2mm",
                            "Periksa O ring groove, maks gap 2mm",
                            "Periksa bagian hole stud",
                            "Periksa semua bagian Bead seat band",
                            "Periksa semua bagian Flange",
                            "Periksa semua bagian Lock Ring",
                            "Periksa bagian lock driver (pada unit ADT, Loader)",
                            "Periksa semua bagian O-Ring",
                            "Periksa bagian lubang valve",
                            "Valve stem protector",
                            "Valve stem",
                            "Valve core",
                          ];

                          return p.Column(
                            crossAxisAlignment: p.CrossAxisAlignment.start,
                            children: [
                              /// TITLE
                              p.Container(
                                width: double.infinity,
                                padding: const p.EdgeInsets.all(5),
                                color: PdfColors.grey300,
                                child: p.Text(
                                  "RIM & KOMPONEN",
                                  style: p.TextStyle(
                                      fontWeight: p.FontWeight.bold,
                                      fontSize: 8),
                                ),
                              ),

                              /// HEADER INFO
                              p.Container(
                                padding: const p.EdgeInsets.all(5),
                                child: p.Column(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Text(
                                        "Rim Size : ${controller.rimSize.text}",
                                        style: p.TextStyle(fontSize: 7)),
                                    p.Text(
                                        "Rim Brand : ${controller.rimBrand.text}",
                                        style: p.TextStyle(fontSize: 7)),
                                    p.Text(
                                        "Serial No : ${controller.serialNo.text}",
                                        style: p.TextStyle(fontSize: 7)),
                                  ],
                                ),
                              ),

                              /// TABLE
                              p.Table(
                                border: p.TableBorder.all(width: 0.5),
                                columnWidths: {
                                  0: const p.FixedColumnWidth(25),
                                  1: const p.FlexColumnWidth(),
                                  2: const p.FixedColumnWidth(120),
                                },
                                children: [
                                  /// HEADER
                                  p.TableRow(
                                    decoration: const p.BoxDecoration(
                                        color: PdfColors.grey300),
                                    children: [
                                      header('NO'),
                                      header('Check Fisik Rim dan Komponen'),
                                      header('Kondisi'),
                                    ],
                                  ),

                                  /// DATA
                                  ...List.generate(items.length, (index) {
                                    String condition = '';

                                    switch (index) {
                                      case 0:
                                        final selected =
                                            (form['rim_condition'] as List?)
                                                    ?.cast<String>() ??
                                                [];

                                        final options = [
                                          "Normal",
                                          "Berkarat",
                                          "Crack Back Section",
                                          "Crack Center Section",
                                          "Crack Gutter Section"
                                        ];

                                        return p.TableRow(
                                          children: [
                                            cell('1'),
                                            cell(items[index]),
                                            p.Container(
                                              padding:
                                                  const p.EdgeInsets.all(3),
                                              child: p.Column(
                                                crossAxisAlignment:
                                                    p.CrossAxisAlignment.start,
                                                children: options.map((opt) {
                                                  final isSelected =
                                                      selected.contains(opt);

                                                  return p.Padding(
                                                    padding:
                                                        const p.EdgeInsets.only(
                                                            bottom: 2),
                                                    child: p.Row(
                                                      mainAxisSize:
                                                          p.MainAxisSize.min,
                                                      children: [
                                                        p.Stack(
                                                          alignment: p.Alignment
                                                              .centerLeft,
                                                          children: [
                                                            p.Text(
                                                              opt,
                                                              style:
                                                                  p.TextStyle(
                                                                fontSize: 7,
                                                                fontWeight: p
                                                                    .FontWeight
                                                                    .bold,
                                                                color: isSelected
                                                                    ? PdfColors
                                                                        .black
                                                                    : PdfColors
                                                                        .grey600,
                                                              ),
                                                            ),
                                                            if (!isSelected)
                                                              p.Positioned(
                                                                left: 0,
                                                                right: 0,
                                                                top: 4,
                                                                child:
                                                                    p.Container(
                                                                  height: 0.8,
                                                                  color:
                                                                      PdfColors
                                                                          .red,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        );
                                      case 1:
                                        condition = form['lock_ring_gap'] ?? '';
                                        break;
                                      case 2:
                                        condition = form['oring_gap'] ?? '';
                                        break;
                                      case 3:
                                        condition = form['hole_stud'] ?? '';
                                        break;
                                      case 4:
                                        final selected =
                                            (form['bead_seat'] as List?)
                                                    ?.cast<String>() ??
                                                [];

                                        final options = [
                                          "Normal",
                                          "Berkarat",
                                          "Crack",
                                          "Oval",
                                          "Dented",
                                          "Deform"
                                        ];

                                        return p.TableRow(
                                          children: [
                                            cell('${index + 1}'),
                                            cell(items[index]),
                                            p.Container(
                                              padding:
                                                  const p.EdgeInsets.all(3),
                                              child: p.Column(
                                                crossAxisAlignment:
                                                    p.CrossAxisAlignment.start,
                                                children: options.map((opt) {
                                                  final isSelected =
                                                      selected.contains(opt);

                                                  return p.Padding(
                                                    padding:
                                                        const p.EdgeInsets.only(
                                                            bottom: 2),
                                                    child: p.Stack(
                                                      alignment: p
                                                          .Alignment.centerLeft,
                                                      children: [
                                                        p.Text(
                                                          opt,
                                                          style: p.TextStyle(
                                                            fontSize: 7,
                                                            fontWeight: p
                                                                .FontWeight
                                                                .bold,
                                                            color: isSelected
                                                                ? PdfColors
                                                                    .black
                                                                : PdfColors
                                                                    .grey600,
                                                          ),
                                                        ),
                                                        if (!isSelected)
                                                          p.Positioned(
                                                            left: 0,
                                                            right: 0,
                                                            top: 4,
                                                            child: p.Container(
                                                              height: 0.8,
                                                              color:
                                                                  PdfColors.red,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        );
                                      case 5:
                                        final selected =
                                            (form['flange'] as List?)
                                                    ?.cast<String>() ??
                                                [];

                                        final options = [
                                          "Normal",
                                          "Berkarat",
                                          "Crack",
                                          "Oval",
                                          "Dented",
                                          "Deform"
                                        ];

                                        return p.TableRow(
                                          children: [
                                            cell('${index + 1}'),
                                            cell(items[index]),
                                            p.Container(
                                              padding:
                                                  const p.EdgeInsets.all(3),
                                              child: p.Column(
                                                crossAxisAlignment:
                                                    p.CrossAxisAlignment.start,
                                                children: options.map((opt) {
                                                  final isSelected =
                                                      selected.contains(opt);

                                                  return p.Padding(
                                                    padding:
                                                        const p.EdgeInsets.only(
                                                            bottom: 2),
                                                    child: p.Stack(
                                                      alignment: p
                                                          .Alignment.centerLeft,
                                                      children: [
                                                        p.Text(
                                                          opt,
                                                          style: p.TextStyle(
                                                            fontSize: 7,
                                                            fontWeight: p
                                                                .FontWeight
                                                                .bold,
                                                            color: isSelected
                                                                ? PdfColors
                                                                    .black
                                                                : PdfColors
                                                                    .grey600,
                                                          ),
                                                        ),
                                                        if (!isSelected)
                                                          p.Positioned(
                                                            left: 0,
                                                            right: 0,
                                                            top: 4,
                                                            child: p.Container(
                                                              height: 0.8,
                                                              color:
                                                                  PdfColors.red,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        );
                                      case 6:
                                        final selected =
                                            (form['lock_ring_distance']
                                                        as List?)
                                                    ?.cast<String>() ??
                                                [];

                                        final options = [
                                          "Normal",
                                          "Berkarat",
                                          "Sprung"
                                        ];

                                        return p.TableRow(
                                          children: [
                                            cell('${index + 1}'),
                                            cell(items[index]),
                                            p.Container(
                                              padding:
                                                  const p.EdgeInsets.all(3),
                                              child: p.Column(
                                                crossAxisAlignment:
                                                    p.CrossAxisAlignment.start,
                                                children: options.map((opt) {
                                                  final isSelected =
                                                      selected.contains(opt);

                                                  return p.Padding(
                                                    padding:
                                                        const p.EdgeInsets.only(
                                                            bottom: 2),
                                                    child: p.Stack(
                                                      alignment: p
                                                          .Alignment.centerLeft,
                                                      children: [
                                                        p.Text(
                                                          opt,
                                                          style: p.TextStyle(
                                                            fontSize: 7,
                                                            fontWeight: p
                                                                .FontWeight
                                                                .bold,
                                                            color: isSelected
                                                                ? PdfColors
                                                                    .black
                                                                : PdfColors
                                                                    .grey600,
                                                          ),
                                                        ),
                                                        if (!isSelected)
                                                          p.Positioned(
                                                            left: 0,
                                                            right: 0,
                                                            top: 4,
                                                            child: p.Container(
                                                              height: 0.8,
                                                              color:
                                                                  PdfColors.red,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        );
                                      case 7:
                                        condition = form['lock_driver'] ?? '';
                                        break;
                                      case 8:
                                        condition = form['oring'] ?? '';
                                        break;
                                      case 9:
                                        condition = form['oring'] ?? '';
                                        break;
                                      case 10:
                                        condition = form['valve_hole'] ?? '';
                                        break;
                                      case 11:
                                        condition =
                                            form['valve_protector'] ?? '';
                                        break;
                                      case 12:
                                        condition = form['valve_stem'] ?? '';
                                        break;
                                      case 13:
                                        condition = form['valve_core'] ?? '';
                                        break;
                                    }

                                    return p.TableRow(
                                      children: [
                                        cell('${index + 1}'),
                                        cell(items[index]),
                                        p.Container(
                                          padding: const p.EdgeInsets.all(3),
                                          color: (condition == "Tidak" ||
                                                  condition
                                                          .toString()
                                                          .toLowerCase() ==
                                                      "crack" ||
                                                  condition
                                                          .toString()
                                                          .toLowerCase() ==
                                                      "berkarat")
                                              ? PdfColors.red100
                                              : PdfColors.green100,
                                          child: p.Text(
                                            condition.toString(),
                                            style:
                                                const p.TextStyle(fontSize: 7),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),

                              p.SizedBox(height: 8),

                              /// ACTION
                              p.Text(
                                "Action :",
                                style: p.TextStyle(
                                  fontSize: 8,
                                  fontWeight: p.FontWeight.bold,
                                ),
                              ),

                              p.Row(
                                children: List.generate(
                                    ["baik", "repair", "scrap"].length,
                                    (index) {
                                  final key =
                                      ["baik", "repair", "scrap"][index];
                                  final selected = controller.action.value;
                                  final isSelected = key == selected;

                                  final label = {
                                    "baik": "Baik (Laik Operasi)",
                                    "repair": "Harus di Repair",
                                    "scrap": "SCRAP",
                                  }[key]!;

                                  return p.Row(
                                    children: [
                                      /// TEXT + CORET
                                      p.Stack(
                                        alignment: p.Alignment.centerLeft,
                                        children: [
                                          p.Text(
                                            label,
                                            style: p.TextStyle(
                                              fontSize: 8,
                                              fontWeight: p.FontWeight.bold,
                                              color: isSelected
                                                  ? PdfColors.black
                                                  : PdfColors.grey600,
                                            ),
                                          ),
                                          if (!isSelected)
                                            p.Positioned(
                                              left: 0,
                                              right: 0,
                                              top: 5,
                                              child: p.Container(
                                                height: 1,
                                                color: PdfColors.red,
                                              ),
                                            ),
                                        ],
                                      ),

                                      /// 🔥 TAMBAH " / " (kecuali terakhir)
                                      if (index !=
                                          ["baik", "repair", "scrap"].length -
                                              1)
                                        p.Text(
                                          " / ",
                                          style: p.TextStyle(
                                            fontSize: 8,
                                            fontWeight: p.FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  );
                                }),
                              ),

                              p.SizedBox(height: 6),

                              /// NOTE
                              p.Text(
                                "Catat jika ada kerusakan lain yang tidak ada dalam list",
                                style: p.TextStyle(fontSize: 7),
                              ),

                              p.Container(
                                width: double.infinity,
                                padding: const p.EdgeInsets.all(5),
                                constraints:
                                    const p.BoxConstraints(minHeight: 40),
                                decoration: p.BoxDecoration(
                                  border: p.Border.all(width: 0.5),
                                ),
                                child: p.Text(
                                  form['other_damage_note'] ?? '',
                                  style: const p.TextStyle(fontSize: 7),
                                ),
                              ),
                              p.SizedBox(height: 20),

                              /// SIGNATURE
                              p.Row(
                                mainAxisAlignment:
                                    p.MainAxisAlignment.spaceBetween,
                                children: [
                                  p.Column(
                                    children: [
                                      p.Text("Di Inspeksi Oleh",
                                          style: p.TextStyle(fontSize: 7)),
                                      p.SizedBox(height: 40),
                                      p.Container(
                                          width: 100,
                                          height: 1,
                                          color: PdfColors.black),
                                      p.SizedBox(height: 4),
                                      p.Text("Nama & Ttd",
                                          style: p.TextStyle(fontSize: 6)),
                                    ],
                                  ),
                                  p.Column(
                                    children: [
                                      p.Text("Di Periksa Oleh",
                                          style: p.TextStyle(fontSize: 7)),
                                      p.SizedBox(height: 40),
                                      p.Container(
                                          width: 100,
                                          height: 1,
                                          color: PdfColors.black),
                                      p.SizedBox(height: 4),
                                      p.Text("Nama & Ttd",
                                          style: p.TextStyle(fontSize: 6)),
                                    ],
                                  ),
                                  p.Column(
                                    children: [
                                      p.Text("Di Ketahui Oleh",
                                          style: p.TextStyle(fontSize: 7)),
                                      p.SizedBox(height: 40),
                                      p.Container(
                                          width: 100,
                                          height: 1,
                                          color: PdfColors.black),
                                      p.SizedBox(height: 4),
                                      p.Text("Nama & Ttd",
                                          style: p.TextStyle(fontSize: 6)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    );

                    final output = await getTemporaryDirectory();
                    final file = File("${output.path}/rim_inspection.pdf");

                    await file.writeAsBytes(await pdf.save());

                    await OpenFile.open(file.path);
                  },
                  child: const Text("Submit"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  p.Widget header(String text) {
    return p.Container(
      alignment: p.Alignment.center,
      padding: const p.EdgeInsets.all(3),
      child: p.Text(
        text,
        textAlign: p.TextAlign.center,
        style: p.TextStyle(
          fontSize: 7,
          fontWeight: p.FontWeight.bold,
        ),
      ),
    );
  }

  p.Widget cell(String text) {
    return p.Container(
      alignment: p.Alignment.centerLeft,
      padding: const p.EdgeInsets.all(3),
      child: p.Text(
        text,
        textAlign: p.TextAlign.left,
        style: const p.TextStyle(fontSize: 7),
      ),
    );
  }
}
