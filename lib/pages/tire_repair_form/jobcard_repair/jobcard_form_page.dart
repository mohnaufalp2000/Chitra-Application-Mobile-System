import 'dart:convert';
import 'dart:developer';

import 'package:camos/pages/tire_repair_form/jobcard_repair/list_jobcard_repair_page.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/widget/decimal_text_input_formatter.dart';
import 'package:flutter/services.dart';

import '../../../core/blocs/process_jobcard/process_jobcard_bloc.dart';
import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/data/jobcard_repair.dart';
import '../../../core/utils/firebase_key/firebase_key.dart';
import '../../../core/widgets/button_widget.dart';
import 'widget/tire_detail.dart';
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
    final selectedJob = map['selectedJob'] ?? '';
    final wo = map['wo'];
    final woDate = map['woDate'];
    final processRepairCountBefore = 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jobcard Repair',
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
            Tab(text: 'Process Repair'),
            Tab(text: 'Tire Detail'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            ProcessRepair(
              tireDetail: tireDetail,
              processRepairCountBefore: '1',
              selectedJob: selectedJob,
            ),
            TireDetail(tireDetail: tireDetail, wo: wo, woDate: woDate),
          ],
        ),
      ),
    );
  }
}

class ProcessRepair extends StatefulWidget {
  final Map<String, dynamic> tireDetail;
  String selectedJob;
  final String processRepairCountBefore;

  ProcessRepair({
    super.key,
    required this.tireDetail,
    required this.processRepairCountBefore,
    this.selectedJob = '',
  });

  @override
  State<ProcessRepair> createState() => _ProcessRepairState();
}

class _ProcessRepairState extends State<ProcessRepair> {
  // String? selectedMaterial;
  List<Map<String, dynamic>> selectedMaterials = [];
  String existingJob = '';
  String existingDuration = '';
  final TextEditingController injuriesController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  final TextEditingController minutesController = TextEditingController();
  final TextEditingController repairmanController = TextEditingController();

  // final TextEditingController LController = TextEditingController();
  // final TextEditingController WController = TextEditingController();
  // final TextEditingController PController = TextEditingController();
  // final TextEditingController TController = TextEditingController();
  List<TextEditingController> LController = [];
  List<TextEditingController> WController = [];
  List<TextEditingController> PController = [];
  List<TextEditingController> TController = [];
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  DateTime? selectedDate;

  int dimensiLukaMax = 5;
  int visibleItemCountDimensi = 1;

  bool _isSameMaterial(
    Map<String, dynamic> item,
    dynamic idMatstock,
    String materialName,
  ) {
    return item['id_matstock']?.toString().trim() ==
            idMatstock?.toString().trim() &&
        item['name']?.toString().trim() == materialName.trim();
  }

  List<Map<String, dynamic>> _normalizeMaterials(dynamic rawMaterials) {
    final Iterable<dynamic> values;
    if (rawMaterials is List) {
      values = rawMaterials;
    } else if (rawMaterials is Map) {
      values = rawMaterials.values;
    } else {
      values = const <dynamic>[];
    }

    final normalized = values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
      final id = item['id_matstock']?.toString().trim() ?? '';
      final name = item['name']?.toString().trim() ?? '';
      return id.isNotEmpty || name.isNotEmpty;
    }).toList();

    final uniqueMaterials = <Map<String, dynamic>>[];
    for (final item in normalized) {
      final existingIndex = uniqueMaterials.indexWhere(
        (existing) => _isSameMaterial(
          existing,
          item['id_matstock'],
          item['name']?.toString() ?? '',
        ),
      );
      if (existingIndex == -1) {
        uniqueMaterials.add(item);
      } else {
        final existingQty =
            uniqueMaterials[existingIndex]['qty']?.toString().trim() ?? '';
        final currentQty = item['qty']?.toString().trim() ?? '';
        if (existingQty.isEmpty && currentQty.isNotEmpty) {
          uniqueMaterials[existingIndex] = item;
        }
      }
    }
    return uniqueMaterials;
  }

  Future<void> initEditJobcard() async {
    // Edit Jobcard (Proses yg dipilih)
    existingJob = widget.selectedJob;
    // Data sebelumnya
    final selectedJobQuery = await firestore
        .collection(FirestoreKey.tireRepairInspectionReport)
        .where('id', isEqualTo: widget.tireDetail['id'])
        .limit(1)
        .get();

    final selectedJobData = selectedJobQuery.docs[0].data();
    final selectedJobSelect = (selectedJobData['jobcard1'] as List<dynamic>)
        .firstWhere((element) => element['name'] == existingJob);

    final format = DateFormat('dd-MM-yyyy');
    selectedDate = format.parse(selectedJobSelect['date']);
    selectedMaterials
      ..clear()
      ..addAll(_normalizeMaterials(selectedJobSelect['material']));

    final dimensi = (selectedJobSelect['dimensi'] ?? '').toString();

    final groups = dimensi
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    log('dimensi length: ${groups}');

    LController.clear();
    WController.clear();
    PController.clear();
    TController.clear();

    for (int i = 0; i < dimensiLukaMax; i++) {
      String? L, W, P, T;

      if (i < groups.length) {
        final parts = groups[i].split(',');

        for (var part in parts) {
          if (part.startsWith('L')) {
            L = part.substring(1);
          } else if (part.startsWith('W')) {
            W = part.substring(1);
          } else if (part.startsWith('P')) {
            P = part.substring(1);
          } else if (part.startsWith('T')) {
            T = part.substring(1);
          }
        }
      }

      // isi sesuai index
      LController.add(TextEditingController(text: L ?? ''));
      WController.add(TextEditingController(text: W ?? ''));
      PController.add(TextEditingController(text: P ?? ''));
      TController.add(TextEditingController(text: T ?? ''));
    }

    // LController.add(TextEditingController());
    // WController.add(TextEditingController());
    // PController.add(TextEditingController());
    // TController.add(TextEditingController());

    hoursController.text = selectedJobSelect['hours'];
    minutesController.text = selectedJobSelect['minutes'];
    repairmanController.text = selectedJobSelect['bywhom'];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    context.read<ProcessJobcardBloc>().add(FetchMaterialListEvent());
    injuriesController.text = widget.tireDetail['remarks'];

    for (int i = 0; i < dimensiLukaMax; i++) {
      LController.add(TextEditingController());
      WController.add(TextEditingController());
      PController.add(TextEditingController());
      TController.add(TextEditingController());
    }

    if (widget.tireDetail['jobcard1'].isEmpty) {
      existingJob = 'Skiving';
      existingDuration = JobcardRepair.jobName
          .firstWhere((element) => element['name'] == 'Skiving')['duration'];
      print('duration : $existingDuration');
    } else {
      // Edit Jobcard
      if (widget.selectedJob != '') {
        initEditJobcard();
        return;
      }
      final lastName = widget.tireDetail['jobcard1'].last['name'];
      final lastDuration = widget.tireDetail['jobcard1'].last['duration'];

      final jobList = JobcardRepair.jobName;
      final currentIndex = jobList.indexWhere((job) => job['name'] == lastName);

      existingJob = widget.tireDetail['jobcard1'].last['name'];
      existingDuration = JobcardRepair.jobName
          .firstWhere((element) => element['name'] == existingJob)['duration'];
      if (currentIndex != -1 && currentIndex < jobList.length - 1) {
        existingJob = jobList[currentIndex + 1]['name'];
        existingDuration = jobList[currentIndex + 1]['duration'];
      } else {
        // Kalau tidak ketemu atau sudah di akhir list, tetap pakai lastName
        existingJob = lastName;
        existingDuration = lastDuration;
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

  // Future<void> _selectDate(BuildContext context) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: selectedDate,
  //     firstDate: DateTime(1900),
  //     lastDate: DateTime(2100),
  //   );
  //   if (picked != null && picked != selectedDate) {
  //     setState(() {
  //       selectedDate = picked;
  //     });
  //   }
  // }
  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (selectedDate ?? today).isAfter(today)
          ? today
          : (selectedDate ?? today),
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year, today.month, today.day),
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
        FormTitle(title: 'Job : $existingJob'),
        const SizedBox(
          height: 12,
        ),
        const FormTitle(title: 'Luka'),
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
        const FormTitle(title: 'Tanggal Pengerjaan'),
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
                  ? 'Pilih Tanggal'
                  : '${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ),
        if (existingJob == 'Dimensi Luka')
          Column(
            children: [
              const SizedBox(
                height: 12,
              ),
              ...List.generate(dimensiLukaMax, (index) {
                if (index >= visibleItemCountDimensi) return const SizedBox();
                return Column(
                  children: [
                    DimensiLukaWidget(
                      index: index,
                      LController: LController[index],
                      WController: WController[index],
                      PController: PController[index],
                      TController: TController[index],
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              }),

              // Tombol Show More
              if (visibleItemCountDimensi < dimensiLukaMax)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green00968A,
                  ),
                  onPressed: () {
                    setState(() {
                      visibleItemCountDimensi++;
                    });
                  },
                  child: Text(
                    'Add More',
                    style: getWhiteTextStyle(),
                  ),
                )
              else
                Text(
                  'Semua dimensi luka sudah ditampilkan',
                  style: getWhiteTextStyle(),
                ),
              const SizedBox(
                height: 12,
              ),
            ],
          )
        else
          Container(),
        if (existingJob != 'Skiving' &&
            existingJob != 'Painting' &&
            existingJob != 'Dimensi Luka' &&
            existingJob != 'Buffing InnerLinner' &&
            existingJob != 'Curing' &&
            existingJob != 'Finishing' &&
            existingJob != 'Painting')
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
                    log('semua materials : ${filteredMaterials}');

                    // mendapatkan satuan material
                    final existingMaterialUnit = (filteredMaterials.isNotEmpty)
                        ? filteredMaterials[0].smu.name
                        : '';
                    log('existing materials : ${filteredMaterials}');

                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        const FormTitle(title: 'Material'),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            final List<Map<String, dynamic>>
                                tempSelectedMaterials = selectedMaterials
                                    .map((item) =>
                                        Map<String, dynamic>.from(item))
                                    .toList();
                            showModalBottomSheet(
                              isDismissible: false,
                              context: context,
                              isScrollControlled: true,
                              enableDrag: false,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setModalState) {
                                    return WillPopScope(
                                      onWillPop: () async => false, //
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            bottom: MediaQuery.of(context)
                                                .viewInsets
                                                .bottom,
                                            top: 16,
                                            left: 16,
                                            right: 16),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Choose Materials & Input Qty',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                  // IconButton(
                                                  //     onPressed: () {
                                                  //       Navigator.pop(context);
                                                  //     },
                                                  //     icon: Icon(Icons.close))
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              ListView(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                children: filteredMaterials
                                                    .map((material) {
                                                  final isSelected =
                                                      tempSelectedMaterials.any(
                                                          (element) =>
                                                              _isSameMaterial(
                                                                element,
                                                                material
                                                                    .idMatstock,
                                                                material
                                                                    .materialName,
                                                              ));

                                                  final currentQty =
                                                      tempSelectedMaterials
                                                          .firstWhere(
                                                    (element) =>
                                                        _isSameMaterial(
                                                      element,
                                                      material.idMatstock,
                                                      material.materialName,
                                                    ),
                                                    orElse: () => {'qty': ''},
                                                  )['qty'];

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(material
                                                                .materialName),
                                                          ),
                                                          Checkbox(
                                                            value: isSelected,
                                                            onChanged: (bool?
                                                                selected) {
                                                              setModalState(() {
                                                                if (selected ==
                                                                    true) {
                                                                  final existingIndex =
                                                                      tempSelectedMaterials
                                                                          .indexWhere(
                                                                    (element) =>
                                                                        _isSameMaterial(
                                                                      element,
                                                                      material
                                                                          .idMatstock,
                                                                      material
                                                                          .materialName,
                                                                    ),
                                                                  );
                                                                  if (existingIndex ==
                                                                      -1) {
                                                                    tempSelectedMaterials
                                                                        .add({
                                                                      'id_matstock':
                                                                          material
                                                                              .idMatstock,
                                                                      'name': material
                                                                          .materialName,
                                                                      'qty': '',
                                                                      'smu':
                                                                          existingMaterialUnit,
                                                                    });
                                                                  }
                                                                } else {
                                                                  tempSelectedMaterials
                                                                      .removeWhere(
                                                                    (element) =>
                                                                        _isSameMaterial(
                                                                      element,
                                                                      material
                                                                          .idMatstock,
                                                                      material
                                                                          .materialName,
                                                                    ),
                                                                  );
                                                                }
                                                              });
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      if (isSelected)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                            top: 8,
                                                            bottom: 8,
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              SizedBox(
                                                                width: 120,
                                                                child:
                                                                    TextFormField(
                                                                  key: ValueKey(
                                                                    'qty-${material.idMatstock}-${material.materialName}',
                                                                  ),
                                                                  initialValue:
                                                                      currentQty
                                                                          ?.toString(),
                                                                  keyboardType:
                                                                      const TextInputType
                                                                          .numberWithOptions(
                                                                    decimal:
                                                                        true,
                                                                    signed:
                                                                        false,
                                                                  ),
                                                                  inputFormatters: [
                                                                    DecimalTextInputFormatter(),
                                                                  ],
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    labelText:
                                                                        'Qty',
                                                                    border:
                                                                        OutlineInputBorder(),
                                                                    contentPadding:
                                                                        EdgeInsets
                                                                            .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                  onChanged:
                                                                      (value) {
                                                                    final index =
                                                                        tempSelectedMaterials
                                                                            .indexWhere(
                                                                      (element) =>
                                                                          _isSameMaterial(
                                                                        element,
                                                                        material
                                                                            .idMatstock,
                                                                        material
                                                                            .materialName,
                                                                      ),
                                                                    );
                                                                    if (index !=
                                                                        -1) {
                                                                      tempSelectedMaterials[index]
                                                                              [
                                                                              'qty'] =
                                                                          value.replaceAll(
                                                                              ',',
                                                                              '.');
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              Text(
                                                                existingMaterialUnit,
                                                                style:
                                                                    getBlackTextStyle(),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      const Divider(
                                                        color: black,
                                                        thickness: 1.5,
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  final hasEmptyQty =
                                                      tempSelectedMaterials.any(
                                                          (item) =>
                                                              item['qty'] ==
                                                                  null ||
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
                                                            child: const Text(
                                                                'OK'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  } else {
                                                    setState(() {
                                                      selectedMaterials =
                                                          tempSelectedMaterials
                                                              .map((item) => Map<
                                                                      String,
                                                                      dynamic>.from(
                                                                  item))
                                                              .toList();
                                                    });
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
                                              const SizedBox(
                                                height: 12,
                                              ),
                                            ],
                                          ),
                                        ),
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
                                          '${e['name']} (QTY : ${e['qty']} $existingMaterialUnit)')
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
                const SizedBox(
                  height: 12,
                ),
                const FormTitle(title: 'Jam'),
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
                const FormTitle(title: 'Menit'),
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
        Text(
          '*Rekomendasi Durasi Pekerjaan: ${existingDuration}',
          textAlign: TextAlign.center,
          style: getGreyTextStyle(grey6A707C),
        ),
        const SizedBox(
          height: 12,
        ),
        const FormTitle(title: 'Nama Repairman'),
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
                      Navigator.pop(context, true);
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
                  .collection(FirestoreKey.tireRepairInspectionReport)
                  .where('id', isEqualTo: widget.tireDetail['id'])
                  .limit(1)
                  .get();
              final oldRef = oldData.docs.first.reference;
              final oldMapData = oldData.docs.first.data();

              print(
                  'process repair count before : ${widget.processRepairCountBefore}');
              print(
                  'process repair count : ${oldData.docs.first['process_repair_count']}');

              if (hoursController.text.isEmpty &&
                  minutesController.text.isEmpty) {
                hoursController.text = '0';
                minutesController.text = '1';
              }

              // int processRepairCount;

              // if (widget.processRepairCountBefore != '') {
              //   processRepairCount = int.parse(widget.processRepairCountBefore);
              // } else {
              //   processRepairCount = oldData.docs.first['process_repair_count'];
              // }
              final processRepairCount = 1;

              if (selectedMaterials.isEmpty) {
                selectedMaterials.add({
                  'id_matstock': '',
                  'name': '',
                  'qty': '',
                  'smu': '',
                });
              }

              String dimensiString =
                  List.generate(visibleItemCountDimensi, (index) {
                final l = LController[index].text.trim();
                final w = WController[index].text.trim();
                final p = PController[index].text.trim();
                final t = TController[index].text.trim();

                // Cek kalau semua field tidak kosong
                if (l.isNotEmpty &&
                    w.isNotEmpty &&
                    p.isNotEmpty &&
                    t.isNotEmpty) {
                  return 'L$l,W$w,P$p,T$t';
                } else {
                  return ''; // kosong → akan dihapus di filter
                }
              }).where((e) => e.isNotEmpty).join(' ');

              print('format material : ${selectedMaterials}');

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
                'dimensi': dimensiString,
                'created_at': DateTime.now().toIso8601String(),
              };

              print('format json jobcard : ${jsonEncode(jobcardData)}');

              // LANGKAH 1: READ
              // Ambil array yang ada dari dokumen. Default ke list kosong jika tidak ada.
              List<dynamic> jobcardOldList =
                  List.from(oldMapData['jobcard1'] ?? []);

              // LANGKAH 2: MODIFY
              // Cari index dari jobcard yang memiliki 'name' yang sama
              int existingIndex = jobcardOldList.indexWhere(
                  (job) => job is Map && job['name'] == jobcardData['name']);

              if (existingIndex != -1) {
                // JIKA DITEMUKAN: timpa data pada index tersebut
                jobcardOldList[existingIndex] = jobcardData;
              } else {
                // JIKA TIDAK DITEMUKAN: Tambahkan data baru ke list
                jobcardOldList.add(jobcardData);
              }

              // Simpan ke Firestore
              // await oldData.docs[0].reference.update({
              //   'jobcard1': FieldValue.arrayUnion([jobcardData]),

              await oldRef.update({
                'jobcard1': jobcardOldList,
              });

              bool isEdit = false;
              if (widget.selectedJob != '') {
                isEdit = true;
              }

              context.read<ProcessJobcardBloc>().add(
                  SubmitJobcardEvent(jobcard: jobcardData, isEdit: isEdit));
            })
      ]),
    );
  }
}

class DimensiLukaWidget extends StatelessWidget {
  const DimensiLukaWidget({
    super.key,
    required this.LController,
    required this.WController,
    required this.PController,
    required this.TController,
    required this.index,
  });

  final TextEditingController LController;
  final TextEditingController WController;
  final TextEditingController PController;
  final TextEditingController TController;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              if (index == 0) FormTitle(title: 'L') else Container(),
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
              if (index == 0) FormTitle(title: 'W') else Container(),
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
              if (index == 0) FormTitle(title: 'P') else Container(),
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
              if (index == 0) FormTitle(title: 'T') else Container(),
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
