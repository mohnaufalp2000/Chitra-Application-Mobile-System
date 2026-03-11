import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/pre_assembly_tire_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
              kondisiDropdown("rim_condition", "1. Kondisi RIM",
                  'Periksa semua bagian RIM (Wheel Base)', [
                "Normal",
                "Berkarat",
                "Crack Back Section",
                "Crack Center Section",
                "Crack Gutter Section"
              ]),

              inputField("lock_ring_gap", "2. Lock Ring Groove Gap (mm)"),

              inputField("oring_gap", "3. O Ring Groove Gap (mm)"),

              yesNo("hole_stud", "4. Hole Stud Oval?"),

              kondisiDropdown("bead_seat", "5. Bead Seat Band Condition", 'a',
                  ["Normal", "Berkarat", "Crack", "Oval", "Dented", "Deform"]),

              kondisiDropdown("flange", "6. Flange Condition", 'a',
                  ["Normal", "Berkarat", "Crack", "Oval", "Dented", "Deform"]),

              inputField("lock_ring_distance", "7. Lock Ring Distance (mm)"),

              yesNo("lock_driver", "8. Lock Driver Shape Change?"),

              yesNo("oring", "9. O-Ring Masih Bulat?"),

              inputField("valve_hole", "10. Valve Hole Condition"),

              yesNo("valve_protector", "11. Valve Stem Protector Dented?"),

              yesNo("valve_stem", "12. Valve Stem Bengkok?"),

              yesNo("valve_core", "13. Valve Core Condition OK?"),
              const SizedBox(height: 20),

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

              ElevatedButton(
                onPressed: () {
                  print(controller.formData);
                },
                child: const Text("Submit"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
