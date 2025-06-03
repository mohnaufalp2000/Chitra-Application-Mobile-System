import 'package:camos/core/blocs/process_jobcard/process_jobcard_bloc.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/jobcard_repair.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/widget/tire_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class JobcardFormPage extends StatefulWidget {
  static const routeName = '/jobcard-form-page';
  const JobcardFormPage({super.key});

  @override
  State<JobcardFormPage> createState() => _JobcardFormPageState();
}

class _JobcardFormPageState extends State<JobcardFormPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tireDetail =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jobcard Repair (${JobcardRepair.jobName[0]['name']})',
          style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
        ),
        backgroundColor: green359B7B,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: white,
          tabs: const [
            Tab(text: 'Tire Detail'),
            Tab(text: 'Process Repair (1)'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            TireDetail(tireDetail: tireDetail),
            ProcessRepair(
              tireDetail: tireDetail,
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessRepair extends StatefulWidget {
  final Map<String, dynamic> tireDetail;

  const ProcessRepair({super.key, required this.tireDetail});

  @override
  State<ProcessRepair> createState() => _ProcessRepairState();
}

class _ProcessRepairState extends State<ProcessRepair> {
  // String? selectedMaterial;
  List<Map<String, dynamic>> selectedMaterials = [];
  String existingJob = '';
  final TextEditingController injuriesController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  final TextEditingController minutesController = TextEditingController();
  final TextEditingController repairmanController = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    context.read<ProcessJobcardBloc>().add(FetchMaterialListEvent());
    injuriesController.text = widget.tireDetail['remarks'];

    if (widget.tireDetail['jobcard'].isEmpty) {
      existingJob = 'Skiving';
    } else {
      final lastName = widget.tireDetail['jobcard'].last['name'];

      final jobList = JobcardRepair.jobName;
      final currentIndex = jobList.indexWhere((job) => job['name'] == lastName);

      existingJob = widget.tireDetail['jobcard'].last['name'];
      if (currentIndex != -1 && currentIndex < jobList.length - 1) {
        existingJob = jobList[currentIndex + 1]['name'];
      } else {
        // Kalau tidak ketemu atau sudah di akhir list, tetap pakai lastName
        existingJob = lastName;
      }
    }
  }

  @override
  void dispose() {
    injuriesController.dispose();
    dateController.dispose();
    qtyController.dispose();
    hoursController.dispose();
    minutesController.dispose();
    repairmanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FormTitle(title: 'Injuries'),
        const SizedBox(
          height: 12,
        ),
        Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: injuriesController,
              maxLines: null,
              minLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.only(left: 20, top: 40),
              ),
            )),
        const SizedBox(
          height: 12,
        ),
        const FormTitle(title: 'Date'),
        const SizedBox(
          height: 12,
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: dateController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: EdgeInsets.only(left: 20),
            ),
          ),
        ),
        if (existingJob == 'Dimensi Luka')
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const FormTitle(title: 'L'),
                        const SizedBox(
                          height: 12,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: dateController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              contentPadding: EdgeInsets.only(left: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const FormTitle(title: 'W'),
                        const SizedBox(
                          height: 12,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: dateController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              contentPadding: EdgeInsets.only(left: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const FormTitle(title: 'P'),
                        const SizedBox(
                          height: 12,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: dateController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              contentPadding: EdgeInsets.only(left: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const FormTitle(title: 'T'),
                        const SizedBox(
                          height: 12,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: dateController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              contentPadding: EdgeInsets.only(left: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          )
        else
          Container(),
        if (existingJob != 'Install Patch' || existingJob != 'Painting')
          Column(
            children: [
              BlocConsumer<ProcessJobcardBloc, ProcessJobcardState>(
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is MaterialLoadingState) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (state is MaterialLoadedState) {
                    final filteredMaterials = state.materials
                        .where(
                          (material) =>
                              JobcardRepair.jobName.firstWhere((element) =>
                                  element['name'] ==
                                  existingJob)['type_material'] ==
                              material.category.name,
                        )
                        .toList();
                    // if (!filteredMaterials
                    //     .any((e) => e.idMatstock == selectedMaterial)) {
                    //   selectedMaterial = null;
                    // }

                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        const FormTitle(title: 'Material'),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setModalState) {
                                    return ListView(
                                      children:
                                          filteredMaterials.map((material) {
                                        final isSelected =
                                            selectedMaterials.any((element) =>
                                                element['id_matstock'] ==
                                                    material.idMatstock &&
                                                element['name'] ==
                                                    material.materialName);

                                        return CheckboxListTile(
                                          title: Text(material.materialName),
                                          value: isSelected,
                                          onChanged: (bool? selected) {
                                            setModalState(() {
                                              if (selected == true) {
                                                selectedMaterials.add({
                                                  'id_matstock':
                                                      material.idMatstock,
                                                  'name': material.materialName
                                                });
                                              } else {
                                                selectedMaterials.removeWhere(
                                                    (element) =>
                                                        element['id_matstock'] ==
                                                            material
                                                                .idMatstock &&
                                                        element['name'] ==
                                                            material
                                                                .materialName);
                                              }
                                            });

                                            // Update state di widget utama juga, supaya tampilan luar ikut berubah saat modal ditutup
                                            setState(() {});
                                          },
                                        );
                                      }).toList(),
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedMaterials.isEmpty
                                  ? 'Choose Materials'
                                  : selectedMaterials
                                      .map((e) => e['name'])
                                      .join(', '),
                              style: getBlackTextStyle(),
                            ),
                          ),
                        ),

                        // Container(
                        //   decoration: BoxDecoration(
                        //     border: Border.all(color: Colors.grey),
                        //     color: Colors.white,
                        //     borderRadius: BorderRadius.circular(30),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: Colors.grey.withOpacity(0.5),
                        //         spreadRadius: 2,
                        //         blurRadius: 5,
                        //         offset: Offset(0, 3),
                        //       ),
                        //     ],
                        //   ),
                        //   child: DropdownButton<String>(
                        //     isExpanded: true,
                        //     padding: EdgeInsets.symmetric(horizontal: 24),
                        //     value: selectedMaterial,
                        //     hint: const Text('Choose Material'),
                        //     items: filteredMaterials
                        //         .map((e) => DropdownMenuItem<String>(
                        //               value: e.idMatstock,
                        //               child: Text(
                        //                 e.materialName,
                        //                 style: getBlackTextStyle(),
                        //               ),
                        //             ))
                        //         .toList(),
                        //     onChanged: (newValue) {
                        //       setState(() {
                        //         selectedMaterial = newValue ?? '';
                        //       });
                        //     },
                        //   ),
                        // ),
                      ],
                    );
                  } else if (state is MaterialErrorState) {
                    return const Center(
                      child: Text('Error'),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          )
        else
          Container(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormTitle(title: 'QTY'),
                const SizedBox(
                  height: 12,
                ),
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: qtyController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: EdgeInsets.only(left: 20),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    const FormTitle(title: 'Hours'),
                    const SizedBox(
                      height: 12,
                    ),
                    Container(
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: hoursController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: EdgeInsets.only(left: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  ' : ',
                  style: getBlackTextStyle(fontSize: 32),
                ),
                Column(
                  children: [
                    const FormTitle(title: 'Minutes'),
                    const SizedBox(
                      height: 12,
                    ),
                    Container(
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: minutesController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: EdgeInsets.only(left: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        const FormTitle(title: 'By Whom'),
        const SizedBox(
          height: 12,
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: repairmanController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: EdgeInsets.only(left: 20),
            ),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        ButtonWidget(
            color: green359B7B,
            name: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.save,
                  color: white,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  'Save',
                  style: getWhiteTextStyle(),
                ),
              ],
            ),
            function: () async {
              final oldData = await firestore
                  .collection('tire_repair_inspection_report_trial')
                  .where('id', isEqualTo: widget.tireDetail['id'])
                  .get();

              await oldData.docs[0].reference.update({
                'jobcard': FieldValue.arrayUnion([
                  {
                    'name': existingJob,
                    'fulldate': DateTime.now().toIso8601String(),
                    'date': DateFormat('dd-MM-yyyy').format(DateTime.now()),
                    'material': FieldValue.arrayUnion(selectedMaterials),
                    'qty': qtyController.text,
                    'hours': hoursController.text,
                    'minutes': minutesController.text,
                    'bywhom': repairmanController.text,
                    'remarks': injuriesController.text,
                  }
                ])
              });
            })
      ]),
    );
  }
}

class FormTitle extends StatelessWidget {
  final String title;

  const FormTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(title,
          style: getBlackTextStyle(
            fontSize: 18,
            fontWeight: w700,
          )),
    );
  }
}

class BoxFormProcess extends StatefulWidget {
  bool isLargeInput;
  String title;
  final TextEditingController controller;

  BoxFormProcess({
    super.key,
    this.isLargeInput = false,
    required this.title,
    required this.controller,
  });

  @override
  State<BoxFormProcess> createState() => _BoxFormProcessState();
}

class _BoxFormProcessState extends State<BoxFormProcess> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(widget.title,
              style: getBlackTextStyle(
                fontSize: 18,
                fontWeight: w700,
              )),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: (widget.isLargeInput)
              ? TextField(
                  controller: TextEditingController(),
                  maxLines: null,
                  minLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: EdgeInsets.only(left: 20, top: 40),
                  ),
                )
              : TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: EdgeInsets.only(left: 20),
                  ),
                ),
        ),
      ],
    );
  }
}
