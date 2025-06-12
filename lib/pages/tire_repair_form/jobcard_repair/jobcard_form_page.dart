import 'dart:convert';

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
    final map =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final tireDetail = map['tireDetail'];
    final processRepairCountBefore = map['processRepairCount'];

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
            Tab(text: 'Process Repair'),
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
              processRepairCountBefore: processRepairCountBefore,
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessRepair extends StatefulWidget {
  final Map<String, dynamic> tireDetail;
  final String processRepairCountBefore;

  const ProcessRepair(
      {super.key,
      required this.tireDetail,
      required this.processRepairCountBefore});

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

  final TextEditingController LController = TextEditingController();
  final TextEditingController WController = TextEditingController();
  final TextEditingController PController = TextEditingController();
  final TextEditingController TController = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    context.read<ProcessJobcardBloc>().add(FetchMaterialListEvent());
    injuriesController.text = widget.tireDetail['remarks'];

    if (widget
        .tireDetail['jobcard${widget.processRepairCountBefore}'].isEmpty) {
      existingJob = 'Skiving';
    } else {
      final lastName = widget
          .tireDetail['jobcard${widget.processRepairCountBefore}'].last['name'];

      final jobList = JobcardRepair.jobName;
      final currentIndex = jobList.indexWhere((job) => job['name'] == lastName);

      existingJob = widget
          .tireDetail['jobcard${widget.processRepairCountBefore}'].last['name'];
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('existing job : ${existingJob}');
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
        GestureDetector(
          onTap: () => _selectDate(
            context,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                right: 24.0, left: 24.0, top: 15, bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              selectedDate == null
                  ? 'Select Date'
                  : '${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}',
              style: const TextStyle(color: Colors.black),
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
                            controller: LController,
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
                            controller: WController,
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
                            controller: PController,
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
                            controller: TController,
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
        if (existingJob != 'Install Patch' &&
            existingJob != 'Painting' &&
            existingJob != 'Dimensi Luka')
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
                        .toList()
                      ..sort(
                          (a, b) => a.materialName.compareTo(b.materialName));

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
                              isScrollControlled: true,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setModalState) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Choose Materials & Input Qty',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(height: 12),
                                          Flexible(
                                            child: ListView(
                                              shrinkWrap: true,
                                              children: filteredMaterials
                                                  .map((material) {
                                                final isSelected = selectedMaterials
                                                    .any((element) =>
                                                        element['id_matstock'] ==
                                                            material
                                                                .idMatstock &&
                                                        element['name'] ==
                                                            material
                                                                .materialName);

                                                final currentQty =
                                                    selectedMaterials
                                                        .firstWhere(
                                                  (element) =>
                                                      element['id_matstock'] ==
                                                          material.idMatstock &&
                                                      element['name'] ==
                                                          material.materialName,
                                                  orElse: () => {'qty': ''},
                                                )['qty'];

                                                return CheckboxListTile(
                                                  title: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(material
                                                          .materialName),
                                                      if (isSelected)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 8.0),
                                                          child: TextFormField(
                                                            initialValue:
                                                                currentQty,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            decoration:
                                                                const InputDecoration(
                                                              labelText: 'Qty',
                                                              border:
                                                                  OutlineInputBorder(),
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          12),
                                                            ),
                                                            onChanged: (value) {
                                                              setModalState(() {
                                                                final index =
                                                                    selectedMaterials
                                                                        .indexWhere(
                                                                  (element) =>
                                                                      element['id_matstock'] ==
                                                                          material
                                                                              .idMatstock &&
                                                                      element['name'] ==
                                                                          material
                                                                              .materialName,
                                                                );
                                                                if (index !=
                                                                    -1) {
                                                                  selectedMaterials[
                                                                          index]
                                                                      [
                                                                      'qty'] = value;
                                                                }
                                                              });
                                                              setState(() {});
                                                            },
                                                          ),
                                                        ),
                                                      const Divider(
                                                        color: black,
                                                        thickness: 1.5,
                                                      ),
                                                    ],
                                                  ),
                                                  value: isSelected,
                                                  onChanged: (bool? selected) {
                                                    setModalState(() {
                                                      if (selected == true) {
                                                        selectedMaterials.add({
                                                          'id_matstock':
                                                              material
                                                                  .idMatstock,
                                                          'name': material
                                                              .materialName,
                                                          'qty': '',
                                                        });
                                                      } else {
                                                        selectedMaterials
                                                            .removeWhere(
                                                          (element) =>
                                                              element['id_matstock'] ==
                                                                  material
                                                                      .idMatstock &&
                                                              element['name'] ==
                                                                  material
                                                                      .materialName,
                                                        );
                                                      }
                                                    });

                                                    // Update tampilan utama juga
                                                    setState(() {});
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              final hasEmptyQty =
                                                  selectedMaterials.any(
                                                      (item) =>
                                                          item['qty'] == null ||
                                                          item['qty']
                                                              .toString()
                                                              .trim()
                                                              .isEmpty);

                                              if (hasEmptyQty) {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Qty belum diisi'),
                                                    content: const Text(
                                                        'Please input QTY.'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              } else {
                                                Navigator.pop(context);
                                              }
                                            },
                                            icon: const Icon(Icons.check),
                                            label: const Text('Selesai'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green[700],
                                              foregroundColor: Colors.white,
                                              minimumSize:
                                                  const Size.fromHeight(48),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: Container(
                            width: double.infinity,
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
                                      .map((e) =>
                                          '${e['name']} (QTY : ${e['qty']})')
                                      .join(',\n'),
                              style: getBlackTextStyle(),
                            ),
                          ),
                        )
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
          mainAxisAlignment: MainAxisAlignment.center,
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
                BlocConsumer<ProcessJobcardBloc, ProcessJobcardState>(
                  listener: (context, state) {
                    if (state is SubmitSuccessState) {
                      Navigator.pop(context);
                    } else if (state is SubmitErrorState) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menyimpan data')),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is SubmitLoadingState) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (state is SubmitErrorState) {
                      return Text(
                        'Error, please try again',
                        style: getWhiteTextStyle(),
                      );
                    } else if (state is SubmitSuccessState) {
                      return Text(
                        'Save',
                        style: getWhiteTextStyle(),
                      );
                    } else {
                      return Text(
                        'Save',
                        style: getWhiteTextStyle(),
                      );
                    }
                  },
                ),
              ],
            ),
            function: () async {
              final oldData = await firestore
                  .collection('tire_repair_inspection_report_trial')
                  .where('id', isEqualTo: widget.tireDetail['id'])
                  .get();

              final processRepairCount =
                  oldData.docs.first['process_repair_count'];

              if (selectedMaterials.isEmpty) {
                selectedMaterials.add({
                  'id_matstock': '',
                  'name': '',
                  'qty': '',
                });
              }

              final jobcardData = {
                'name': existingJob,
                'fulldate': selectedDate?.toIso8601String(),
                'date': DateFormat('dd-MM-yyyy').format(selectedDate!),
                'material': selectedMaterials,
                'hours': hoursController.text,
                'minutes': minutesController.text,
                'bywhom': repairmanController.text,
                'remarks': injuriesController.text,
                'process_repair_count': processRepairCount,
                'id_wo': widget.tireDetail['id'],
                'dimensi':
                    'L${LController.text},W${WController.text},P${PController.text},T${TController.text}',
                'created_at': DateTime.now().toIso8601String(),
              };

              print('format json jobcard : ${jsonEncode(jobcardData)}');

              // Simpan ke Firestore
              await oldData.docs[0].reference.update({
                'jobcard': FieldValue.arrayUnion([jobcardData]),
              });

              context
                  .read<ProcessJobcardBloc>()
                  .add(SubmitJobcardEvent(jobcard: jobcardData));

              // await oldData.docs[0].reference.update({
              //   'jobcard': FieldValue.arrayUnion([
              //     {
              //       'name': existingJob,
              //       'fulldate': DateTime.now().toIso8601String(),
              //       'date': DateFormat('dd-MM-yyyy').format(DateTime.now()),
              //       'material': selectedMaterials,
              //       'qty': qtyController.text,
              //       'hours': hoursController.text,
              //       'minutes': minutesController.text,
              //       'bywhom': repairmanController.text,
              //       'remarks': injuriesController.text,
              //       'dimensi':
              //           '${LController.text},${WController.text},${PController.text}, ${TController.text}'
              //     }
              //   ])
              // });
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
