import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/blocs/wo_jobcard/wo_jobcard_bloc.dart';
import '../../../core/services/api_service.dart';
import '../../../core/styles/asset_path.dart';
import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/data/jobcard_repair.dart';
import '../../../core/utils/firebase_key/firebase_key.dart';
import '../../../core/widgets/button_widget.dart';
import 'history_jobcard_repair_page.dart';
import 'jobcard_form_page.dart';
import 'jobcard_selected_job_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ListJobcardRepair extends StatefulWidget {
  static const routeName = '/list-jobcard-repair';
  const ListJobcardRepair({super.key});

  @override
  State<ListJobcardRepair> createState() => _ListJobcardRepairState();
}

class _ListJobcardRepairState extends State<ListJobcardRepair> {
  bool isChecked = false;
  final List<String> jobName =
      JobcardRepair.jobName.map((item) => item['name'] as String).toList();
  int selectedMenu = 1;
  List<Map<String, dynamic>> WOlist = [];

  List<bool> isCheckedList =
      List.generate(10, (_) => false); // Sesuaikan jumlah item

  void _onHistoryPressed() {
    // Navigator.pushNamed(context, JobcardQCPage.routeName);
    // Navigator.pushNamed(context, HistoryJobcardRepairPage.routeName);
    Navigator.pushNamed(context, HistoryJobcardRepairPage.routeName);
  }

  Future<void> _onRefresh() async {
    context.read<WoJobcardBloc>().add(WoJobcardEvent());

    // kasih delay kecil biar indikator keliatan natural
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void initState() {
    super.initState();
    context.read<WoJobcardBloc>().add(WoJobcardEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jobcard Repair',
          style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF359B7B),
        iconTheme: const IconThemeData(color: Colors.white),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.history),
        //     color: Colors.white,
        //     tooltip: 'History',
        //     onPressed: _onHistoryPressed,
        //   ),
        // ],
      ),
      body: SafeArea(
          child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: BlocConsumer<WoJobcardBloc, WoJobcardState>(
                listener: (context, state) {
                  if (state is WoJobcardLoadedState) {
                    WOlist.clear();
                    WOlist.addAll(state.WOList);
                  }
                },
                builder: (context, state) {
                  if (state is WoJobcardLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is WoJobcardLoadedState) {
                    final widgetOptions = [
                      UploadDocumentJobcard(woList: WOlist),
                      WaitingWO(woList: WOlist),
                      OnProgress(woList: WOlist),
                      // const WaitingQC()
                    ];
                    return widgetOptions.elementAt(selectedMenu);
                  } else if (state is WoJobcardErrorState) {
                    return const Center(
                      child: Icon(Icons.error),
                    );
                  } else {
                    return Container();
                  }
                },
              )),
        ),
      )),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedMenu,
          onTap: (index) async {
            // FirebaseFirestore firestore = FirebaseFirestore.instance;
            // final snapshot = await firestore
            //     .collection(FirestoreKey.tireRepairInspectionReportTrial)
            //     .where('id', isEqualTo: 'v2qvvHSZF6')
            //     .get();

            // print('firebase kuy: ${snapshot.docs[0].data()}');
            setState(() {
              selectedMenu = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
                // icon: Icon(Icons.tag), label: 'Waiting WO#'),
                icon: Icon(Icons.tag),
                label: 'Upload Document Jobcard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.pending), label: 'Waiting WO#'),
            // icon: Icon(Icons.tag),),
            BottomNavigationBarItem(
                // icon: Icon(Icons.work_history), label: 'On Progress'),
                icon: Icon(Icons.work_history),
                label: 'Input Form Jobcard'),
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.fact_check), label: 'Waiting QC'),
          ]),
    );
  }
}

class UploadDocumentJobcard extends StatefulWidget {
  final List<Map<String, dynamic>> woList;

  const UploadDocumentJobcard({super.key, required this.woList});

  @override
  State<UploadDocumentJobcard> createState() => _UploadDocumentJobcardState();
}

class _UploadDocumentJobcardState extends State<UploadDocumentJobcard> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final List<String> idWoList =
        widget.woList.map((item) => item['id_wo'] as String).toList();

    print('id wo list : ${idWoList}');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(
                hintText: 'Search... (SN)',
                hintStyle: getGreyTextStyle(grey8391A1),
                prefixIcon: Icon(Icons.search)),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        PaginateFirestore(
            query: firestore
                .collection(FirestoreKey.tireRepairInspectionReport)
                .orderBy('created_at', descending: true),
            itemBuilderType: PaginateBuilderType.listView,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemsPerPage: 5,
            key: const Key('upload_document_jobcard'),
            isLive: true,
            initialLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            bottomLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            itemBuilder: (context, snapshot, index) {
              final Map<String, dynamic> data =
                  snapshot[index].data() as Map<String, dynamic>;

              if (searchQuery.isNotEmpty &&
                  !data['sn']!.toLowerCase().contains(searchQuery) &&
                  !data['sn']!.toUpperCase().contains(searchQuery)) {
                return Container();
              }

              return UploadDocumentJobcardCard(data: data);
            }),
      ],
    );
  }
}

class WaitingWO extends StatefulWidget {
  final List<Map<String, dynamic>> woList;

  const WaitingWO({super.key, required this.woList});

  @override
  State<WaitingWO> createState() => _WaitingWOState();
}

class _WaitingWOState extends State<WaitingWO> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final List<String> idWoList =
        widget.woList.map((item) => item['id_wo'] as String).toList();

    print('id wo list : ${idWoList}');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(
                hintText: 'Search... (SN)',
                hintStyle: getGreyTextStyle(grey8391A1),
                prefixIcon: Icon(Icons.search)),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        PaginateFirestore(
            query: firestore
                .collection(FirestoreKey.tireRepairInspectionReport)
                .orderBy('created_at', descending: true),
            itemBuilderType: PaginateBuilderType.listView,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemsPerPage: 5,
            key: const Key('waiting_wo'),
            isLive: true,
            initialLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            bottomLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            itemBuilder: (context, snapshot, index) {
              final Map<String, dynamic> data =
                  snapshot[index].data() as Map<String, dynamic>;

              if (searchQuery.isNotEmpty &&
                  !data['sn']!.toLowerCase().contains(searchQuery) &&
                  !data['sn']!.toUpperCase().contains(searchQuery)) {
                return Container();
              }

              if (idWoList.contains(data['id'])) {
                return Container();
              }

              return WaitingWOCard(data: data);
            }),
      ],
    );
  }
}

class OnProgress extends StatefulWidget {
  const OnProgress({super.key, required this.woList});
  // woList adalah data dari API yang statusnya sudah "On Progress"
  final List<Map<String, dynamic>> woList;

  @override
  State<OnProgress> createState() => _OnProgressState();
}

class _OnProgressState extends State<OnProgress> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  // State untuk menyimpan hasil data gabungan dan status loading
  bool _isLoading = true;
  List<Map<String, dynamic>> _onProgressDocuments = [];

  // Map untuk lookup data dari API agar lebih cepat (Optimalisasi)
  late Map<String, Map<String, dynamic>> _apiDataMap;

  @override
  void initState() {
    super.initState();
    // Proses hanya jika ada data dari API
    if (widget.woList.isNotEmpty) {
      // 1. Buat Map dari data API untuk pencarian yg efisien (O(1) lookup)
      _apiDataMap = {for (var item in widget.woList) item['id_wo']: item};
      // 2. Mulai proses pengambilan data dari Firestore dan gabungkan
      _fetchAndProcessData();
    } else {
      // Jika tidak ada list dari API, langsung set status tidak loading
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Mengambil data dari Firestore berdasarkan ID dari API, lalu menggabungkannya.
  Future<void> _fetchAndProcessData() async {
    final List<String> idWoList =
        widget.woList.map((item) => item['id_wo'] as String).toList();
    const int chunkSize = 30; // Batas maksimal 'whereIn' dari Firestore

    List<Map<String, dynamic>> fetchedAndMergedDocs = [];

    // Loop untuk setiap 'chunk' dari list ID untuk menghindari limit
    for (var i = 0; i < idWoList.length; i += chunkSize) {
      final chunk = idWoList.sublist(
        i,
        i + chunkSize > idWoList.length ? idWoList.length : i + chunkSize,
      );

      if (chunk.isNotEmpty) {
        final querySnapshot = await _firestore
            .collection(FirestoreKey.tireRepairInspectionReport)
            .where('id', whereIn: chunk)
            .get();

        // Proses dan gabungkan data untuk chunk ini
        for (var doc in querySnapshot.docs) {
          final firestoreData = doc.data() as Map<String, dynamic>;
          final String firestoreId = firestoreData['id'];

          // Ambil data terkait dari API via Map yang sudah dibuat
          final apiData = _apiDataMap[firestoreId];

          if (apiData != null) {
            // Gabungkan data: field dari API akan menimpa field dari Firestore jika namanya sama
            final mergedData = {
              ...firestoreData,
              ...apiData,
            };
            fetchedAndMergedDocs.add(mergedData);
          }
        }
      }
    }

    // Urutkan hasil gabungan berdasarkan 'wo_date' dari API (atau field lain yg relevan)
    fetchedAndMergedDocs.sort((a, b) {
      // Pastikan 'wo_date' ada dan valid sebelum diurutkan
      final aDate = DateTime.tryParse(a['wo_date'] ?? '');
      final bDate = DateTime.tryParse(b['wo_date'] ?? '');
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate); // Urutkan dari terbaru ke terlama
    });

    // Update state dengan data yang sudah digabung dan diurutkan
    if (mounted) {
      setState(() {
        _onProgressDocuments = fetchedAndMergedDocs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_onProgressDocuments.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: getBlackTextStyle(), // Aktifkan style Anda
        ),
      );
    }

    // Terapkan filter pencarian secara lokal pada data yang sudah digabung
    final List<Map<String, dynamic>> filteredDocs =
        _onProgressDocuments.where((doc) {
      // Mencari berdasarkan 'sn' atau 'tire_sn'
      final sn = (doc['sn'] ?? doc['tire_sn'])?.toString().toLowerCase() ?? '';
      return _searchQuery.isEmpty || sn.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: const InputDecoration(
              hintText: 'Search... (SN)',
              // hintStyle: getGreyTextStyle(grey8391A1), // Aktifkan style Anda
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final item = filteredDocs[index];

            // Data WO dan WODate sekarang sudah ada di dalam 'item'
            // Tidak perlu lagi `firstWhere` yang lambat
            final String woNumber = item['wo'] ?? '';
            final String woDate = item['wo_date'] ?? '';

            return JobcardCard(
              wo: woNumber,
              woDate: woDate,
              data: item, // Kirim semua data gabungan ke card
            );
          },
        ),
      ],
    );
  }
}

class UploadDocumentJobcardCard extends StatefulWidget {
  const UploadDocumentJobcardCard({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  State<UploadDocumentJobcardCard> createState() =>
      _UploadDocumentJobcardCardState();
}

class _UploadDocumentJobcardCardState extends State<UploadDocumentJobcardCard> {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  File? selectedImage;
  bool isUploading = false;
  String? imageUrl;
  bool isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadImageFromFirestore();
  }

  Future<void> _downloadImage() async {
    if (imageUrl == null) return;

    try {
      // 🔐 Permission Gallery / Storage
      if (await Permission.storage.request().isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission ditolak')),
        );
        return;
      }

      // 📂 Temp directory (sementara)
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/jobcard_${widget.data['sn']}.jpg';

      // ⬇️ Download dari Firebase Storage
      await Dio().download(imageUrl!, tempPath);

      // 🔄 Convert ke XFile
      final XFile xFile = XFile(tempPath);

      // 🔥 Simpan ke Gallery (pakai fungsi kamu)
      saveToGallery(xFile, widget.data['sn']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar berhasil disimpan ke Gallery')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download gagal: $e')),
      );
    }
  }

  Future<void> downloadAndSaveImageToGallery() async {
    if (imageUrl == null) return;

    try {
      // folder sementara
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/jobcard_${widget.data['sn']}.jpg';

      // download dari Firebase Storage
      await Dio().download(imageUrl!, filePath);

      // convert ke XFile
      final xFile = XFile(filePath);

      // 🔥 pakai fungsi kamu
      saveToGallery(xFile, widget.data['sn']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar berhasil disimpan ke Gallery')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan gambar: $e')),
      );
    }
  }

  void saveToGallery(XFile? compressedImageFile, String sn) async {
    final imageBytes = await compressedImageFile?.readAsBytes();

    await ImageGallerySaver.saveImage(
      imageBytes!,
      name: 'jobcard-form-$sn-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> _loadImageFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('form-jobcard')
          .where('sn', isEqualTo: widget.data['sn'])
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          imageUrl = snapshot.docs.first['imageUrl'];
        });
      }
    } catch (e) {
      debugPrint('Load image error: $e');
    } finally {
      setState(() {
        isLoadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: white,
        elevation: 50,
        shadowColor: black,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer : ${widget.data['customer']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Site : ${widget.data['site']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Repair Location : ${widget.data['repair_location']}',
              ),
              const SizedBox(
                height: 14,
              ),
              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     Text(
              //       'W/O #',
              //       style: getGreyTextStyle(const Color(0xff969696)),
              //     ),
              //     const SizedBox(
              //       height: 4,
              //     ),
              //     Text(
              //       'Waiting WO',
              //       style: getBlackTextStyle(
              //         fontSize: 18,
              //         fontWeight: w700,
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(
              //   height: 6,
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serial Number',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        // 'FGR3463GRE',
                        '${widget.data['sn']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tire Size',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '${widget.data['tire_size']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 🔥 TARUH KODE IMAGE DI SINI
              if (isLoadingImage)
                const Center(child: CircularProgressIndicator())
              else if (imageUrl != null) ...[
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.black,
                        insetPadding: const EdgeInsets.all(12),
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              panEnabled: true,
                              minScale: 1,
                              maxScale: 4,
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _downloadImage,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // 🔘 BUTTON ADD PICTURE
              ButtonWidget(
                name: Text('Add Picture', style: getWhiteTextStyle()),
                color: Colors.green,
                function: () async {
                  final ImagePicker picker = ImagePicker();

                  showModalBottomSheet(
                    context: context,
                    builder: (_) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Ambil dari Kamera'),
                              onTap: () async {
                                Navigator.pop(context);

                                final image = await picker.pickImage(
                                  source: ImageSource.camera,
                                  imageQuality: 80,
                                );

                                if (image != null) {
                                  setState(() {
                                    isUploading = true;
                                  });

                                  try {
                                    final fileName =
                                        'jobcard_${widget.data['sn']}_${DateTime.now().millisecondsSinceEpoch}.jpg';

                                    final ref = storage
                                        .ref()
                                        .child('form-jobcard/$fileName');

                                    await ref.putFile(File(image.path));
                                    final url = await ref.getDownloadURL();

                                    await firestore
                                        .collection('form-jobcard')
                                        .add({
                                      'idSite': widget.data['site'],
                                      'sn': widget.data['sn'],
                                      'customer': widget.data['customer'],
                                      'brand': widget.data['brand'],
                                      'tireSize': widget.data['tire_size'],
                                      'repairLocation':
                                          widget.data['repair_location'],
                                      'imageUrl': url,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    setState(() {
                                      imageUrl = url; // 🔥 UPDATE UI LANGSUNG
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Upload dari kamera berhasil')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Upload gagal: $e')),
                                    );
                                  } finally {
                                    setState(() {
                                      isUploading = false;
                                    });
                                  }
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Ambil dari Gallery'),
                              onTap: () async {
                                Navigator.pop(context);
                                final image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 80,
                                );

                                if (image != null) {
                                  setState(() {
                                    isUploading = true;
                                  });

                                  try {
                                    final fileName =
                                        'jobcard_${widget.data['sn']}_${DateTime.now().millisecondsSinceEpoch}.jpg';

                                    final ref = storage
                                        .ref()
                                        .child('form-jobcard/$fileName');

                                    await ref.putFile(File(image.path));
                                    final url = await ref.getDownloadURL();

                                    await firestore
                                        .collection('form-jobcard')
                                        .add({
                                      'idSite': widget.data['site'],
                                      'sn': widget.data['sn'],
                                      'customer': widget.data['customer'],
                                      'brand': widget.data['brand'],
                                      'tireSize': widget.data['tire_size'],
                                      'repairLocation':
                                          widget.data['repair_location'],
                                      'imageUrl': url,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    setState(() {
                                      imageUrl = url; // 🔥 UPDATE UI
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Upload berhasil')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Upload gagal: $e')),
                                    );
                                  } finally {
                                    setState(() {
                                      isUploading = false;
                                    });
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaitingWOCard extends StatefulWidget {
  const WaitingWOCard({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  State<WaitingWOCard> createState() => _WaitingWOCardState();
}

class _WaitingWOCardState extends State<WaitingWOCard> {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  File? selectedImage;
  bool isUploading = false;
  String? imageUrl;
  bool isLoadingImage = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: white,
        elevation: 50,
        shadowColor: black,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer : ${widget.data['customer']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Site : ${widget.data['site']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Repair Location : ${widget.data['repair_location']}',
              ),
              const SizedBox(
                height: 14,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'W/O #',
                    style: getGreyTextStyle(const Color(0xff969696)),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Waiting WO',
                    style: getBlackTextStyle(
                      fontSize: 18,
                      fontWeight: w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serial Number',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        // 'FGR3463GRE',
                        '${widget.data['sn']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tire Size',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '${widget.data['tire_size']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class JobcardCard extends StatefulWidget {
  const JobcardCard(
      {super.key, required this.wo, required this.data, required this.woDate});

  final String wo;
  final String woDate;
  final Map<String, dynamic> data;

  @override
  State<JobcardCard> createState() => _JobcardCardState();
}

class _JobcardCardState extends State<JobcardCard> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<String> jobName =
      JobcardRepair.jobName.map((item) => item['name'] as String).toList();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: white,
        elevation: 50,
        shadowColor: black,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer : ${widget.data['customer']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Site : ${widget.data['site']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Repair Location : ${widget.data['repair_location']}',
              ),
              const SizedBox(
                height: 14,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'W/O #',
                    style: getGreyTextStyle(const Color(0xff969696)),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    widget.wo,
                    style: getBlackTextStyle(
                      fontSize: 18,
                      fontWeight: w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brand',
                    style: getGreyTextStyle(const Color(0xff969696)),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '${widget.data['brand']}',
                    style: getBlackTextStyle(
                      fontSize: 18,
                      fontWeight: w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serial Number',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        // 'FGR3463GRE',
                        '${widget.data['sn']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tire Size',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '${widget.data['tire_size']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // if (_isExpanded)
              //   ItemJob(
              //     jobName: jobName,
              //     data: widget.data,
              //     cardIndex: 0,
              //     wo: widget.wo,
              //     woDate: widget.woDate,
              //   ),
              // ...List.generate(
              //     (widget.data['process_repair_count'] ?? 0) as int, (index) {
              //   return Column(
              //     children: [
              //       ItemJob(
              //         jobName: jobName,
              //         data: widget.data,
              //         cardIndex: index,
              //         wo: widget.wo,
              //         woDate: widget.woDate,
              //       ),
              //       const SizedBox(
              //         height: 12,
              //       ),
              //       // ADD PROCESS BUTTON
              //       ButtonWidget(
              //           color: green359B7B,
              //           name: Row(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: [
              //               const Icon(
              //                 Icons.add_circle,
              //                 color: white,
              //               ),
              //               const SizedBox(
              //                 width: 12,
              //               ),
              //               Text(
              //                 'Add Proccess',
              //                 style: getWhiteTextStyle(),
              //               ),
              //             ],
              //           ),
              //           function: () async {
              //             final oldData = await firestore
              //                 .collection(
              //                     FirestoreKey.tireRepairInspectionReport)
              //                 .where('id', isEqualTo: widget.data['id'])
              //                 .get();

              //             final repairCount =
              //                 oldData.docs[0].data()['process_repair_count'];

              //             await oldData.docs[0].reference.update({
              //               'process_repair_count': FieldValue.increment(1),
              //               'jobcard${repairCount + 1}': [],
              //             });

              //             setState(() {});
              //           }),
              //       const SizedBox(
              //         height: 12,
              //       ),
              //     ],
              //   );
              // }),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     TextButton(
              //       onPressed: () {
              //         setState(() {
              //           _isExpanded = !_isExpanded;
              //         });
              //       },
              //       child: Row(
              //         children: [
              //           Icon(
              //             (_isExpanded)
              //                 ? Icons.visibility_off
              //                 : Icons.visibility,
              //             color: green35C2C1,
              //           ),
              //           const SizedBox(width: 6),
              //           Text(
              //             _isExpanded ? 'Hide' : 'Show Job Repair',
              //             style: getGreenTextStyle(
              //               fontWeight: w700,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ],
              // )
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      //     jobName: jobName,
                      //     data: widget.data,
                      //     cardIndex: 0,
                      //     wo: widget.wo,
                      //     woDate: widget.woDate,
                      await Navigator.pushNamed(
                        context,
                        JobcardSelectedJobPage.routeName,
                        arguments: {
                          'wo': widget.wo,
                          'woDate': widget.woDate,
                          'data': widget.data,
                        },
                      );
                      if (context.mounted) {
                        context.read<WoJobcardBloc>().add(WoJobcardEvent());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green35C2C1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Input Jobcard',
                          style: getGreenTextStyle(
                            fontWeight: w700,
                          ).copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ItemJob extends StatelessWidget {
  const ItemJob({
    super.key,
    required this.jobName,
    required this.data,
    required this.cardIndex,
    required this.wo,
    required this.woDate,
  });

  final List<String> jobName;
  final Map<String, dynamic> data;
  final int cardIndex;
  final String wo;
  final String woDate;

  bool containsAnyMatch({
    required List<String> listA,
    required List<dynamic> listB,
    required String matchKey,
  }) {
    print('sama a : ${listA}');
    print('sama b : ${listB}');
    final setA = listA.toSet();
    return listB.any((mapItem) => setA.contains(mapItem[matchKey]));
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String existingJob = '';

    String processRepairCount = '';
    int indexCount = cardIndex + 1;
    processRepairCount = '$indexCount';

    print('process : ${processRepairCount}');

    if (data['jobcard$processRepairCount'].isEmpty) {
      existingJob = 'Skiving';
    } else {
      final lastName = data['jobcard$processRepairCount'].last['name'];

      final jobList = JobcardRepair.jobName;
      final currentIndex = jobList.indexWhere((job) => job['name'] == lastName);

      existingJob = data['jobcard$processRepairCount'].last['name'];
      if (currentIndex != -1 && currentIndex < jobList.length - 1) {
        existingJob = jobList[currentIndex + 1]['name'];
      } else {
        // Kalau tidak ketemu atau sudah di akhir list, tetap pakai lastName
        existingJob = lastName;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.work,
            ),
            const SizedBox(
              width: 6,
            ),
            Text(
              'Process Repair (${cardIndex + 1})',
              style: getBlackTextStyle(
                fontSize: 16,
                fontWeight: w700,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 6,
        ),
        Column(
          children: List.generate(jobName.length, (index) {
            final jobcardItem = data['jobcard$processRepairCount'].firstWhere(
              (item) => item['name'] == jobName[index],
              orElse: () => null,
            );
            return Column(
              children: [
                InkWell(
                  onTap: () async {
                    await Navigator.pushNamed(
                        context, JobcardSelectedJobPage.routeName,
                        arguments: {
                          'tireDetail': data,
                          'wo': wo,
                          'woDate': woDate,
                          'processRepairCount': processRepairCount,
                          'isFromListJobcard': true,
                        });
                    if (context.mounted) {
                      context.read<WoJobcardBloc>().add(WoJobcardEvent());
                    }
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (jobcardItem != null &&
                              jobcardItem['hours'] == '0' &&
                              jobcardItem['minutes'] == '0')
                            Text(
                              jobName[index],
                              style: getBlackTextStyle().copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  decorationThickness: 3.0),
                            )
                          else
                            Row(
                              children: [
                                if (data['jobcard$processRepairCount'].any(
                                    (item) => item['name'] == jobName[index]))
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        Image.asset('${iconPath}/accept.png'),
                                  )
                                else
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: black)),
                                  ),
                                const SizedBox(
                                  width: 6,
                                ),
                                Text(
                                  jobName[index],
                                  style: getBlackTextStyle(),
                                )
                              ],
                            ),
                          if (!data['jobcard$processRepairCount'].any(
                                  (item) => item['name'] == jobName[index]) &&
                              existingJob == jobName[index])
                            SizedBox(
                              width: 60,
                              height: 25,
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          'Confirmation Skip (${jobName[index]})',
                                          style: getBlackTextStyle(),
                                        ),
                                        content: Text(
                                          'Are you sure you want to skip this process (${jobName[index]})?',
                                          style: getBlackTextStyle(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(), // Tutup dialog
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final oldData = await firestore
                                                  .collection(FirestoreKey
                                                      .tireRepairInspectionReport)
                                                  .where('id',
                                                      isEqualTo: data['id'])
                                                  .get();
                                              final jobcardData = {
                                                'name': jobName[index],
                                                'fulldate': DateTime.now()
                                                    .toIso8601String(),
                                                'date': DateFormat('dd-MM-yyyy')
                                                    .format(DateTime.now()),
                                                'material': [
                                                  {
                                                    'id_matstock': '',
                                                    'name': '',
                                                    'qty': '',
                                                  }
                                                ],
                                                'hours': '0',
                                                'minutes': '0',
                                                'bywhom': '',
                                                'remarks': '',
                                                'process_repair_count': 1,
                                                'id_wo': data['id'],
                                                'dimensi': '',
                                                'created_at': DateTime.now()
                                                    .toIso8601String(),
                                              };

                                              await oldData.docs[0].reference
                                                  .update({
                                                'jobcard$processRepairCount':
                                                    FieldValue.arrayUnion(
                                                        [jobcardData]),
                                              });

                                              await ApiService
                                                  .postJobJobcardRepair(
                                                      jobcardData);
                                              Navigator.of(context)
                                                  .pop(); // Tutup dialog
                                            },
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF35469B),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.skip_next_outlined,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Skip',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Container()
                        ],
                      )),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
