import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadQueueService extends GetxService {
  final box = GetStorage();
  final _key = 'pendingTaskUploads';

  List<Map<String, dynamic>> pending = [];
  bool _isUploading = false;

  static UploadQueueService get to => Get.find<UploadQueueService>();

  Future<UploadQueueService> init() async {
    final stored = box.read(_key);
    if (stored != null && stored is List) {
      pending = stored
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e as Map),
          )
          .toList();
    }

    // Coba upload semua yang tertunda saat app start
    retryPending();
    return this;
  }

  void _save() => box.write(_key, pending);

  /// Tambah ke antrian upload
  void addPending({
    required String docId,
    required String filePath,
  }) {
    pending.add({
      "docId": docId,
      "filePath": filePath,
    });
    _save();
  }

  /// Upload semua foto pending → update Firestore dengan downloadURL
  Future<void> retryPending() async {
    if (_isUploading) return;
    _isUploading = true;

    final firestore = FirebaseFirestore.instance;
    final List<Map<String, dynamic>> current = List.from(pending);

    for (final item in current) {
      final docId = item["docId"] as String?;
      final filePath = item["filePath"] as String?;

      if (docId == null || filePath == null) continue;

      final file = File(filePath);
      if (!file.existsSync()) continue;

      try {
        final ref = FirebaseStorage.instance.ref('tire_task_images/$docId.jpg');

        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        await firestore.collection('task').doc(docId).update({
          'images': [url],
          'imagePending': false,
        });

        // Hapus file lokal setelah sukses
        try {
          await file.delete();
        } catch (_) {}

        pending.remove(item);
        _save();
      } catch (e) {
        // Kalau gagal upload, biarkan tetap di pending
      }
    }

    _isUploading = false;
  }
}
